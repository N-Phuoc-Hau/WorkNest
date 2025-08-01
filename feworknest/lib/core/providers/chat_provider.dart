import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_realtime_service.dart';

class ChatState {
  final List<Map<String, dynamic>> chatRooms;
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? error;
  final String? currentChatRoomId;

  ChatState({
    this.chatRooms = const [],
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentChatRoomId,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? chatRooms,
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? error,
    String? currentChatRoomId,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentChatRoomId: currentChatRoomId ?? this.currentChatRoomId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final FirebaseRealtimeService _chatService;
  final String _userId;
  final String _userType;

  ChatNotifier(this._chatService, this._userId, this._userType) : super(ChatState()) {
    _initializeChatRooms();
  }

  void _initializeChatRooms() {
    _chatService.getUserChatRoomsStream(_userId, _userType).listen(
      (chatRooms) {
        state = state.copyWith(chatRooms: chatRooms);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<String> createOrGetChatRoom({
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
      
      state = state.copyWith(
        isLoading: false,
        currentChatRoomId: roomId,
      );
      
      return roomId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> sendMessage(String roomId, String text, String senderType, Map<String, dynamic>? senderInfo) async {
    try {
      await _chatService.sendMessage(roomId, _userId, text, senderType, senderInfo);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void subscribeToMessages(String roomId) {
    state = state.copyWith(currentChatRoomId: roomId);
    
    _chatService.subscribeToMessages(roomId).listen(
      (messages) {
        state = state.copyWith(messages: messages);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      await _chatService.markMessagesAsRead(roomId, _userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<int> getUnreadMessageCount(String roomId) async {
    try {
      return await _chatService.getUnreadMessageCount(roomId, _userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteChatRoom(String roomId) async {
    try {
      await _chatService.deleteChatRoom(roomId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}

// Providers
final chatServiceProvider = Provider<FirebaseRealtimeService>((ref) {
  return FirebaseRealtimeService();
});

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, Map<String, String>>((ref, userInfo) {
  final chatService = ref.watch(chatServiceProvider);
  final userId = userInfo['userId']!;
  final userType = userInfo['userType']!;
  return ChatNotifier(chatService, userId, userType);
}); 