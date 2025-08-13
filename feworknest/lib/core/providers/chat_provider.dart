import 'package:flutter_riverpod/flutter_riverpod.dart';
i  /// Load danh sách phòng chat
  Future<void> loadChatRooms() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final rooms = await _chatService.getUserChatRooms();
      final unreadCount = await _chatService.getUnreadMessagesCount();
      
      state = state.copyWith(
        chatRooms: rooms,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Cập nhật số lượng tin nhắn chưa đọc
  Future<void> updateUnreadCount() async {
    try {
      final unreadCount = await _chatService.getUnreadMessagesCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }e_picker/image_picker.dart';

import '../services/chat_service.dart';
import 'auth_provider.dart';

// Chat State Model
class ChatState {
  final List<Map<String, dynamic>> chatRooms;
  final List<Map<String, dynamic>> currentMessages;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final String? currentRoomId;

  const ChatState({
    this.chatRooms = const [],
    this.currentMessages = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.currentRoomId,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? chatRooms,
    List<Map<String, dynamic>>? currentMessages,
    int? unreadCount,
    bool? isLoading,
    String? error,
    String? currentRoomId,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      currentMessages: currentMessages ?? this.currentMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentRoomId: currentRoomId ?? this.currentRoomId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final Ref _ref;

  ChatNotifier(this._chatService, this._ref) : super(const ChatState());

  /// Xử lý lỗi authentication - logout user nếu token hết hạn
  void _handleAuthError(String error) {
    if (error.contains('AUTH_REQUIRED') || error.contains('401') || 
        error.contains('Không có quyền truy cập') || error.contains('đăng nhập')) {
      // Token hết hạn, logout user
      _ref.read(authProvider.notifier).logout();
    }
  }

  /// Tải danh sách phòng chat
  Future<void> loadChatRooms() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final rooms = await _chatService.getUserChatRooms();
      state = state.copyWith(
        chatRooms: rooms,
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Tạo hoặc lấy phòng chat
  Future<String?> createOrGetChatRoom({
    required String recruiterId,
    required String candidateId,
    String? jobId,
    Map<String, dynamic>? recruiterInfo,
    Map<String, dynamic>? candidateInfo,
    Map<String, dynamic>? jobInfo,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final roomId = await _chatService.createOrGetChatRoom(
        recruiterId: recruiterId,
        candidateId: candidateId,
        jobId: jobId,
        recruiterInfo: recruiterInfo,
        candidateInfo: candidateInfo,
        jobInfo: jobInfo,
      );
      
      // Reload chat rooms to include the new one
      await loadChatRooms();
      
      return roomId;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return null;
    }
  }

  /// Tải tin nhắn từ phòng chat
  Future<void> loadMessages(String roomId, {int page = 1}) async {
    try {
      List<Map<String, dynamic>> currentMessages = state.currentMessages;
      String? currentRoomId = state.currentRoomId;
      
      if (page == 1) {
        currentMessages = [];
        currentRoomId = roomId;
      }
      
      state = state.copyWith(
        isLoading: true, 
        error: null,
        currentMessages: currentMessages,
        currentRoomId: currentRoomId,
      );
      
      final messages = await _chatService.getChatMessages(roomId, page: page);
      
      if (page == 1) {
        currentMessages = messages;
      } else {
        currentMessages = [...messages, ...currentMessages];
      }
      
      state = state.copyWith(
        currentMessages: currentMessages,
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Gửi tin nhắn text
  Future<bool> sendTextMessage(String roomId, String content) async {
    try {
      state = state.copyWith(error: null);
      
      await _chatService.sendTextMessage(
        roomId: roomId,
        content: content,
      );
      
      // Reload messages để hiển thị tin nhắn mới
      await loadMessages(roomId);
      
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
      return false;
    }
  }

  /// Gửi tin nhắn hình ảnh
  Future<bool> sendImageMessage(String roomId, XFile imageFile, {String? caption}) async {
    try {
      state = state.copyWith(error: null);
      
      await _chatService.sendImageMessage(
        roomId: roomId,
        imageFile: imageFile,
        caption: caption,
      );
      
      // Reload messages để hiển thị hình ảnh mới
      await loadMessages(roomId);
      
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
      return false;
    }
  }

  /// Đánh dấu đã đọc tin nhắn
  Future<void> markAsRead(String roomId) async {
    try {
      await _chatService.markMessagesAsRead(roomId);
      
      // Cập nhật trạng thái đã đọc trong danh sách phòng chat
      final updatedChatRooms = state.chatRooms.map((room) {
        if (room['id'] == roomId) {
          return {...room, 'unreadCount': 0};
        }
        return room;
      }).toList();
      
      state = state.copyWith(chatRooms: updatedChatRooms);
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
    }
  }

  /// Xóa phòng chat
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      state = state.copyWith(error: null);
      
      await _chatService.deleteChatRoom(roomId);
      
      // Xóa khỏi danh sách local
      final updatedChatRooms = state.chatRooms.where((room) => room['id'] != roomId).toList();
      
      // Nếu đang ở trong phòng chat bị xóa, clear messages
      List<Map<String, dynamic>> updatedCurrentMessages = state.currentMessages;
      String? updatedCurrentRoomId = state.currentRoomId;
      
      if (state.currentRoomId == roomId) {
        updatedCurrentMessages = [];
        updatedCurrentRoomId = null;
      }
      
      state = state.copyWith(
        chatRooms: updatedChatRooms,
        currentMessages: updatedCurrentMessages,
        currentRoomId: updatedCurrentRoomId,
      );
      
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
      return false;
    }
  }

  /// Lấy thông tin phòng chat
  Future<Map<String, dynamic>?> getChatRoomInfo(String roomId) async {
    try {
      state = state.copyWith(error: null);
      return await _chatService.getChatRoomInfo(roomId);
    } catch (e) {
      final errorMsg = e.toString();
      _handleAuthError(errorMsg);
      state = state.copyWith(error: errorMsg);
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear current messages
  void clearCurrentMessages() {
    state = state.copyWith(
      currentMessages: [],
      currentRoomId: null,
    );
  }
}

// Providers
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatServiceProvider), ref);
});
