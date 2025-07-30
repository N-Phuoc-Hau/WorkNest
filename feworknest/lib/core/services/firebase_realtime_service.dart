import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/token_storage.dart';

class FirebaseRealtimeService {
  final Dio _dio;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  FirebaseRealtimeService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // Generate chat room ID (same logic as React Native)
  String generateChatRoomId(String recruiterId, String candidateId, String? jobId) {
    final sortedIds = [recruiterId, candidateId]..sort();
    return jobId != null ? 
      '${sortedIds[0]}_${sortedIds[1]}_$jobId' :
      '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Create or get chat room (same logic as React Native)
  Future<String> createOrGetChatRoom({
    required String recruiterId,
    required String candidateId,
    String? jobId,
    Map<String, dynamic>? recruiterInfo,
    Map<String, dynamic>? candidateInfo,
    Map<String, dynamic>? jobInfo,
  }) async {
    try {
      if (recruiterId.isEmpty || candidateId.isEmpty) {
        throw Exception('Both recruiterId and candidateId are required');
      }

      final roomId = generateChatRoomId(recruiterId, candidateId, jobId);
      final roomRef = _database.child('chatRooms/$roomId');
      
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) {
        // Create new chat room
        final room = {
          'id': roomId,
          'recruiterId': recruiterId,
          'candidateId': candidateId,
          'jobId': jobId,
          'createdAt': ServerValue.timestamp,
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'recruiterInfo': recruiterInfo,
          'candidateInfo': candidateInfo,
          'jobInfo': jobInfo,
          'participants': {
            recruiterId: {
              'id': recruiterId,
              'role': 'recruiter',
              'lastRead': null,
            },
            candidateId: {
              'id': candidateId,
              'role': 'candidate',
              'lastRead': null,
            },
          },
        };
        
        await roomRef.set(room);
        print('Created new chat room: $roomId');
      } else {
        // Update existing room if info is missing
        final roomData = snapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};
        
        if (roomData['recruiterInfo'] == null && recruiterInfo != null) {
          updates['recruiterInfo'] = recruiterInfo;
        }
        if (roomData['candidateInfo'] == null && candidateInfo != null) {
          updates['candidateInfo'] = candidateInfo;
        }
        if (roomData['jobInfo'] == null && jobInfo != null) {
          updates['jobInfo'] = jobInfo;
        }
        
        if (updates.isNotEmpty) {
          await roomRef.update(updates);
        }
        print('Chat room already exists: $roomId');
      }
      
      return roomId;
    } catch (e) {
      print('Error creating/getting chat room: $e');
      rethrow;
    }
  }

  // Send message via backend API
  Future<String> sendMessage(String roomId, String senderId, String text, String senderType, Map<String, dynamic>? senderInfo) async {
    try {
      if (roomId.isEmpty || senderId.isEmpty || text.isEmpty) {
        throw Exception('RoomId, senderId, and text are required');
      }

      final response = await _dio.post(
        ApiConstants.sendMessage,
        data: {
          'chatId': roomId,
          'content': text,
          'messageType': 'text',
          'senderType': senderType,
          'senderInfo': senderInfo,
        },
      );

      return response.data['messageId'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Subscribe to messages (same logic as React Native)
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String roomId) {
    try {
      if (roomId.isEmpty) {
        throw Exception('roomId is required');
      }

      final messagesRef = _database.child('chatRooms/$roomId/messages');
      final messagesQuery = messagesRef.orderByChild('timestamp');

      return messagesQuery.onValue.map((event) {
        final messages = <Map<String, dynamic>>[];
        
        if (event.snapshot.exists) {
          for (final child in event.snapshot.children) {
            final messageId = child.key!;
            final messageData = child.value as Map<dynamic, dynamic>;
            
            messages.add({
              'id': messageId,
              ...messageData,
              'timestamp': messageData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
        
        return messages;
      });
    } catch (e) {
      print('Error setting up message subscription: $e');
      rethrow;
    }
  }

  // Get user chat rooms via backend API
  Future<List<Map<String, dynamic>>> getUserChatRooms(String userId, String userType) async {
    try {
      if (userId.isEmpty || userType.isEmpty) {
        throw Exception('userId and userType are required');
      }

      final response = await _dio.get(ApiConstants.userChats);
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user chat rooms stream (for real-time updates)
  Stream<List<Map<String, dynamic>>> getUserChatRoomsStream(String userId, String userType) {
    try {
      if (userId.isEmpty || userType.isEmpty) {
        throw Exception('userId and userType are required');
      }

      final userIdField = userType == 'recruiter' ? 'recruiterId' : 'candidateId';
      final roomsRef = _database.child('chatRooms');

      return roomsRef.onValue.map((event) {
        final chatRooms = <Map<String, dynamic>>[];
        
        if (event.snapshot.exists) {
          for (final child in event.snapshot.children) {
            final roomId = child.key!;
            final roomData = child.value as Map<dynamic, dynamic>;
            
            // Filter rooms for the current user
            if (roomData[userIdField] == userId) {
              chatRooms.add({
                'id': roomId,
                ...roomData,
              });
            }
          }
        }
        
        // Sort by last message time (most recent first)
        chatRooms.sort((a, b) {
          final timeA = a['lastMessageTimestamp'] ?? a['createdAt'] ?? 0;
          final timeB = b['lastMessageTimestamp'] ?? b['createdAt'] ?? 0;
          return (timeB as int).compareTo(timeA as int);
        });
        
        return chatRooms;
      });
    } catch (e) {
      print('Error setting up chat rooms subscription: $e');
      rethrow;
    }
  }

  // Mark messages as read via backend API
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    try {
      if (roomId.isEmpty || userId.isEmpty) {
        throw Exception('roomId and userId are required');
      }

      await _dio.post('${ApiConstants.markChatAsRead}/$roomId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get unread message count (same logic as React Native)
  Future<int> getUnreadMessageCount(String roomId, String userId) async {
    try {
      if (roomId.isEmpty || userId.isEmpty) {
        throw Exception('roomId and userId are required');
      }

      final messagesRef = _database.child('chatRooms/$roomId/messages');
      final snapshot = await messagesRef.get();

      if (!snapshot.exists) {
        return 0;
      }

      int unreadCount = 0;

      for (final child in snapshot.children) {
        final message = child.value as Map<dynamic, dynamic>;

        // Count messages from other users that are not read
        if (message['senderId'] != userId && message['read'] != true) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread message count: $e');
      rethrow;
    }
  }

  // Delete chat room (same logic as React Native)
  Future<void> deleteChatRoom(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('roomId is required');
      final roomRef = _database.child('chatRooms/$roomId');
      await roomRef.remove();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }

  // Real-time listeners using Firebase Realtime Database
  Stream<DatabaseEvent> listenToChatMessages(String chatId) {
    return _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .onValue;
  }

  Stream<DatabaseEvent> listenToUserNotifications(String userId) {
    return _database
        .child('notifications')
        .child(userId)
        .onValue;
  }

  Stream<DatabaseEvent> listenToUserChats(String userId) {
    return _database
        .child('chats')
        .onValue;
  }

  // Direct Firebase Realtime Database operations (if needed)
  Future<void> sendMessageDirect(String chatId, Map<String, dynamic> message) async {
    await _database
        .child('chats')
        .child(chatId)
        .child('messages')
        .push()
        .set(message);
  }

  Future<void> updateLastMessage(String chatId, String lastMessage, String senderId) async {
    await _database
        .child('chats')
        .child(chatId)
        .update({
          'lastMessage': lastMessage,
          'lastMessageSenderId': senderId,
          'lastMessageAt': ServerValue.timestamp,
        });
  }

  Future<void> createNotification(String userId, Map<String, dynamic> notification) async {
    await _database
        .child('notifications')
        .child(userId)
        .push()
        .set(notification);
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _database
        .child('notifications')
        .child(userId)
        .child(notificationId)
        .child('isRead')
        .set(true);
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      return 'Lỗi: ${e.response!.statusCode}';
    }
    return 'Lỗi kết nối mạng';
  }
} 