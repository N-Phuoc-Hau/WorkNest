import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

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
    
    print('DEBUG Firebase Service: Initializing with validated config');
    print('DEBUG Firebase Service: Database URL: ${_database.root.toString()}');
    _validateFirebaseConfig();
  }

  void _validateFirebaseConfig() {
    try {
      final app = Firebase.app();
      print('DEBUG Firebase Config: ✅ App Name: ${app.name}');
      print('DEBUG Firebase Config: ✅ Project ID: ${app.options.projectId}');
      print('DEBUG Firebase Config: ✅ Database URL: ${app.options.databaseURL}');
      
      if (app.options.projectId != 'jobappchat') {
        print('DEBUG Firebase Config: ⚠️ Project ID mismatch! Expected: jobappchat, Got: ${app.options.projectId}');
      }
      
      if (app.options.databaseURL != 'https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app') {
        print('DEBUG Firebase Config: ⚠️ Database URL mismatch! Expected: https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app, Got: ${app.options.databaseURL}');
      }
    } catch (e) {
      print('DEBUG Firebase Config: ❌ Validation failed: $e');
    }
  }

  // Test Firebase connection
  Future<bool> testConnection() async {
    try {
      print('DEBUG Firebase: Testing connection...');
      
      // Test connection info
      final connRef = _database.child('.info/connected');
      final snapshot = await connRef.get().timeout(const Duration(seconds: 8));
      final isConnected = snapshot.value as bool? ?? false;
      
      print('DEBUG Firebase: Connection test result: $isConnected');
      return isConnected;
    } catch (e) {
      print('DEBUG Firebase: Connection test failed: $e');
      return false;
    }
  }

  // Diagnostic test
  Future<Map<String, dynamic>> diagnosticTest() async {
    final results = <String, dynamic>{};
    
    try {
      print('DEBUG Firebase: Starting diagnostic test...');
      
      // Test Firebase App
      try {
        final app = Firebase.app();
        results['firebase_app'] = {
          'status': 'initialized',
          'project_id': app.options.projectId,
          'database_url': app.options.databaseURL,
        };
      } catch (e) {
        results['firebase_app'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Test Connection
      try {
        final isConnected = await testConnection();
        results['connection'] = {
          'status': isConnected ? 'success' : 'failed',
          'connected': isConnected,
        };
      } catch (e) {
        results['connection'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Test Basic Read
      try {
        final testRef = _database.child('test_read');
        await testRef.get().timeout(const Duration(seconds: 5));
        results['read_test'] = {
          'status': 'success',
          'message': 'Can read from database',
        };
      } catch (e) {
        results['read_test'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      final successCount = results.values.where((v) => 
        v is Map && v['status'] == 'success'
      ).length;
      
      results['summary'] = {
        'total_tests': results.length,
        'successful_tests': successCount,
        'overall_status': successCount >= 2 ? 'healthy' : 'issues_detected',
      };

    } catch (e) {
      results['general_error'] = e.toString();
    }

    return results;
  }

  // Generate chat room ID
  String generateChatRoomId(String userId1, String userId2, String? jobId) {
    final sortedIds = [userId1, userId2]..sort();
    return jobId != null ? 
      '${sortedIds[0]}_${sortedIds[1]}_$jobId' :
      '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Create or get chat room using backend API
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

      print('DEBUG Firebase: Creating chat room via backend API');
      print('DEBUG Firebase: Recruiter: $recruiterId, Candidate: $candidateId');

      // Use backend API first
      final response = await _dio.post(
        ApiConstants.createChat,
        data: {
          'otherUserId': candidateId,
          'initiatorUserId': recruiterId,
          'jobId': jobId,
          'recruiterInfo': recruiterInfo,
          'candidateInfo': candidateInfo,
          'jobInfo': jobInfo,
        },
      ).timeout(const Duration(seconds: 10));

      final roomId = response.data['chatId'] ?? response.data['roomId'];
      
      if (roomId == null) {
        throw Exception('Backend did not return chatId');
      }

      print('DEBUG Firebase: Chat room created via backend: $roomId');
      return roomId;
    } catch (e) {
      print('DEBUG Firebase: Backend error, using fallback: $e');
      
      // Fallback to direct Firebase creation
      final roomId = generateChatRoomId(recruiterId, candidateId, jobId);
      final roomRef = _database.child('chats/$roomId');
      
      final snapshot = await roomRef.get().timeout(const Duration(seconds: 8));
      
      if (!snapshot.exists) {
        final room = {
          'Id': roomId,
          'Participants': [recruiterId, candidateId],
          'CreatedAt': DateTime.now().toUtc().toIso8601String(),
          'LastMessageAt': DateTime.now().toUtc().toIso8601String(),
          'recruiterId': recruiterId,
          'candidateId': candidateId,
          'jobId': jobId,
          'recruiterInfo': recruiterInfo,
          'candidateInfo': candidateInfo,
          'jobInfo': jobInfo,
        };
        
        await roomRef.set(room).timeout(const Duration(seconds: 8));
        print('DEBUG Firebase: Room created via direct Firebase: $roomId');
      }
      
      return roomId;
    }
  }

  // Send message via backend API
  Future<String> sendMessage(String roomId, String senderId, String text, String senderType, Map<String, dynamic>? senderInfo) async {
    try {
      if (roomId.isEmpty || senderId.isEmpty || text.isEmpty) {
        throw Exception('RoomId, senderId, and text are required');
      }

      print('DEBUG Firebase: Sending message via backend API');
      print('DEBUG Firebase: Room ID: $roomId');
      print('DEBUG Firebase: Sender ID: $senderId');
      print('DEBUG Firebase: Message: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      final response = await _dio.post(
        ApiConstants.sendMessage,
        data: {
          'chatId': roomId,
          'content': text,
          'messageType': 'text',
          'senderId': senderId,
          'senderType': senderType,
          'senderInfo': senderInfo,
        },
      ).timeout(const Duration(seconds: 10));

      print('DEBUG Firebase: Message sent successfully via backend');
      return response.data['messageId'];
    } on DioException catch (e) {
      print('DEBUG Firebase: Backend API error: ${e.message}');
      if (e.response?.statusCode == 401) {
        print('DEBUG Firebase: 401 Unauthorized - SenderId: $senderId might be invalid');
        print('DEBUG Firebase: Response: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }

  // Subscribe to messages (matching backend structure: chats/{chatId}/messages)
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String roomId) {
    try {
      if (roomId.isEmpty) {
        throw Exception('roomId is required');
      }

      print('DEBUG Firebase: Subscribing to messages for room: $roomId');
      print('DEBUG Firebase: Using path: chats/$roomId/messages');

      final messagesRef = _database.child('chats/$roomId/messages');
      final messagesQuery = messagesRef.orderByKey();

      return messagesQuery.onValue.map((event) {
        final messages = <Map<String, dynamic>>[];
        
        print('DEBUG Firebase: Received message event - exists: ${event.snapshot.exists}');
        
        if (event.snapshot.exists) {
          print('DEBUG Firebase: Processing ${event.snapshot.children.length} messages');
          
          for (final child in event.snapshot.children) {
            final messageId = child.key!;
            final messageData = child.value;
            
            print('DEBUG Firebase: Message $messageId: $messageData');
            
            // Handle both Map and String (JSON) data formats
            Map<String, dynamic> parsedMessage;
            if (messageData is String) {
              try {
                parsedMessage = Map<String, dynamic>.from(
                  json.decode(messageData) as Map
                );
              } catch (e) {
                print('DEBUG Firebase: Error parsing JSON message: $e');
                continue;
              }
            } else if (messageData is Map) {
              parsedMessage = Map<String, dynamic>.from(messageData);
            } else {
              print('DEBUG Firebase: Unknown message format: ${messageData.runtimeType}');
              continue;
            }
            
            // Normalize field names
            messages.add({
              'id': messageId,
              'messageId': messageId,
              'senderId': parsedMessage['SenderId'] ?? parsedMessage['senderId'],
              'content': parsedMessage['Content'] ?? parsedMessage['content'] ?? parsedMessage['text'],
              'messageType': parsedMessage['MessageType'] ?? parsedMessage['messageType'] ?? 'text',
              'timestamp': parsedMessage['Timestamp'] ?? parsedMessage['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              'fileUrl': parsedMessage['FileUrl'] ?? parsedMessage['fileUrl'],
              'fileName': parsedMessage['FileName'] ?? parsedMessage['fileName'],
              // Keep original data for compatibility
              ...parsedMessage,
            });
          }
        } else {
          print('DEBUG Firebase: No messages found in path: chats/$roomId/messages');
        }
        
        // Sort messages by timestamp
        messages.sort((a, b) {
          final timeA = _parseTimestamp(a['timestamp']);
          final timeB = _parseTimestamp(b['timestamp']);
          return timeA.compareTo(timeB);
        });
        
        print('DEBUG Firebase: Returning ${messages.length} sorted messages');
        return messages;
      });
    } catch (e) {
      print('ERROR Firebase: Error setting up message subscription: $e');
      rethrow;
    }
  }

  // Get user chat rooms stream (matching backend structure: chats/)
  Stream<List<Map<String, dynamic>>> getUserChatRoomsStream(String userId, String userType) {
    try {
      if (userId.isEmpty || userType.isEmpty) {
        throw Exception('userId and userType are required');
      }

      print('DEBUG Firebase: Getting chat rooms for user: $userId, type: $userType');
      print('DEBUG Firebase: Using path: chats/');

      final roomsRef = _database.child('chats');

      return roomsRef.onValue.map((event) {
        final chatRooms = <Map<String, dynamic>>[];
        
        print('DEBUG Firebase: Received chat rooms event - exists: ${event.snapshot.exists}');
        
        if (event.snapshot.exists) {
          print('DEBUG Firebase: Processing ${event.snapshot.children.length} chat rooms');
          
          for (final child in event.snapshot.children) {
            final roomId = child.key!;
            final roomData = child.value;
            
            // Handle both Map and String (JSON) data formats
            Map<String, dynamic> parsedRoom;
            if (roomData is String) {
              try {
                parsedRoom = Map<String, dynamic>.from(
                  json.decode(roomData) as Map
                );
              } catch (e) {
                print('DEBUG Firebase: Error parsing JSON room: $e');
                continue;
              }
            } else if (roomData is Map) {
              parsedRoom = Map<String, dynamic>.from(roomData);
            } else {
              print('DEBUG Firebase: Unknown room format: ${roomData.runtimeType}');
              continue;
            }
            
            // Check if user is participant in this chat
            final participants = parsedRoom['Participants'] ?? parsedRoom['participants'] ?? [];
            if (participants is List && participants.contains(userId)) {
              chatRooms.add({
                'id': roomId,
                'roomId': roomId,
                'participants': participants,
                'createdAt': parsedRoom['CreatedAt'] ?? parsedRoom['createdAt'],
                'lastMessageAt': parsedRoom['LastMessageAt'] ?? parsedRoom['lastMessageAt'],
                'lastMessageTimestamp': parsedRoom['LastMessageAt'] ?? parsedRoom['lastMessageAt'],
                // Keep original data for compatibility
                ...parsedRoom,
              });
            }
          }
        } else {
          print('DEBUG Firebase: No chat rooms found in path: chats/');
        }
        
        // Sort by last message time (most recent first)
        chatRooms.sort((a, b) {
          final timeA = _parseTimestamp(a['lastMessageTimestamp'] ?? a['createdAt'] ?? 0);
          final timeB = _parseTimestamp(b['lastMessageTimestamp'] ?? b['createdAt'] ?? 0);
          return timeB.compareTo(timeA);
        });
        
        print('DEBUG Firebase: Returning ${chatRooms.length} sorted chat rooms');
        return chatRooms;
      });
    } catch (e) {
      print('ERROR Firebase: Error setting up chat rooms subscription: $e');
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

  // Get unread message count
  Future<int> getUnreadMessageCount(String roomId, String userId) async {
    try {
      if (roomId.isEmpty || userId.isEmpty) {
        throw Exception('roomId and userId are required');
      }

      final messagesRef = _database.child('chats/$roomId/messages');
      final snapshot = await messagesRef.get();

      if (!snapshot.exists) {
        return 0;
      }

      int unreadCount = 0;
      for (final child in snapshot.children) {
        final messageData = child.value;
        
        // Handle both Map and String (JSON) data formats
        Map<String, dynamic> message;
        if (messageData is String) {
          try {
            message = Map<String, dynamic>.from(json.decode(messageData) as Map);
          } catch (e) {
            continue;
          }
        } else if (messageData is Map) {
          message = Map<String, dynamic>.from(messageData);
        } else {
          continue;
        }

        final senderId = message['SenderId'] ?? message['senderId'];
        final isRead = message['read'] == true || message['Read'] == true;
        
        if (senderId != userId && !isRead) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread message count: $e');
      rethrow;
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('roomId is required');
      final roomRef = _database.child('chats/$roomId');
      await roomRef.remove();
    } catch (e) {
      print('Error deleting chat room: $e');
      rethrow;
    }
  }

  // Helper method to parse timestamp
  int _parseTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp).millisecondsSinceEpoch;
      } catch (e) {
        return 0;
      }
    } else if (timestamp is int) {
      return timestamp;
    }
    return 0;
  }

  // Handle Dio errors
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
