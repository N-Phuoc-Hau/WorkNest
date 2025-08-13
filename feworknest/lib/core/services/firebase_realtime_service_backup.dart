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
    
    // Debug Firebase Database URL and validate configuration
    print('DEBUG Firebase Service: Initializing with validated config');
    print('DEBUG Firebase Service: Database URL: ${_database.root.toString()}');
    
    // Validate Firebase app initialization
    _validateFirebaseConfig();
  }

  void _validateFirebaseConfig() {
    try {
      final app = Firebase.app();
      print('DEBUG Firebase Config: ✅ App Name: ${app.name}');
      print('DEBUG Firebase Config: ✅ Project ID: ${app.options.projectId}');
      print('DEBUG Firebase Config: ✅ Database URL: ${app.options.databaseURL}');
      print('DEBUG Firebase Config: ✅ Auth Domain: ${app.options.authDomain}');
      
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

  // Retry mechanism for Firebase operations
  Future<T> _retryOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('DEBUG Firebase: Attempting $operationName (attempt $attempt/$maxRetries)');
        final result = await operation();
        print('DEBUG Firebase: $operationName succeeded on attempt $attempt');
        return result;
      } catch (e) {
        print('DEBUG Firebase: $operationName failed on attempt $attempt: $e');
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          print('DEBUG Firebase: Waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException ?? Exception('Unknown error in $operationName');
  }

  // Enhanced comprehensive diagnostic test
  Future<Map<String, dynamic>> diagnosticTest() async {
    final results = <String, dynamic>{};
    
    try {
      print('DEBUG Firebase: Starting comprehensive diagnostic test...');
      
      // Test 1: Firebase App Status
      try {
        final app = Firebase.app();
        results['firebase_app'] = {
          'status': 'initialized',
          'name': app.name,
          'project_id': app.options.projectId,
          'database_url': app.options.databaseURL,
          'auth_domain': app.options.authDomain,
          'api_key': app.options.apiKey.substring(0, 10) + '...',
        };
        print('DEBUG Firebase: ✅ App initialized - Project: ${app.options.projectId}');
        print('DEBUG Firebase: ✅ Database URL: ${app.options.databaseURL}');
      } catch (e) {
        results['firebase_app'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('DEBUG Firebase: ❌ App initialization error: $e');
      }

      // Test 2: Database Reference
      try {
        final dbUrl = _database.root.toString();
        results['database_ref'] = {
          'status': 'created',
          'url': dbUrl,
        };
        print('DEBUG Firebase: ✅ Database reference created: $dbUrl');
      } catch (e) {
        results['database_ref'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('DEBUG Firebase: ❌ Database reference error: $e');
      }

      // Test 3: Network connectivity test
      try {
        print('DEBUG Firebase: Testing network connectivity...');
        final response = await _dio.get('https://firebase.google.com').timeout(
          const Duration(seconds: 5),
        );
        results['network_connectivity'] = {
          'status': 'success',
          'response_code': response.statusCode,
        };
        print('DEBUG Firebase: ✅ Network connectivity OK');
      } catch (e) {
        results['network_connectivity'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('DEBUG Firebase: ❌ Network connectivity failed: $e');
      }

      // Test 4: Firebase rules test (public read)
      try {
        print('DEBUG Firebase: Testing database rules...');
        final publicRef = _database.child('test_public_read');
        await publicRef.get().timeout(const Duration(seconds: 8));
        results['rules_test'] = {
          'status': 'success',
          'path': 'test_public_read',
          'message': 'Rules allow read access',
        };
        print('DEBUG Firebase: ✅ Database rules allow read access');
      } catch (e) {
        results['rules_test'] = {
          'status': 'error',
          'error': e.toString(),
          'possible_cause': 'Database rules might be too restrictive',
        };
        print('DEBUG Firebase: ❌ Rules test failed (might be restrictive): $e');
      }

      // Test 5: Connection info
      try {
        print('DEBUG Firebase: Testing connection info...');
        final connRef = _database.child('.info/connected');
        final snapshot = await connRef.get().timeout(const Duration(seconds: 8));
        final isConnected = snapshot.value as bool? ?? false;
        results['connection_info'] = {
          'status': 'success',
          'connected': isConnected,
          'snapshot_exists': snapshot.exists,
        };
        print('DEBUG Firebase: ✅ Connection info - Connected: $isConnected');
      } catch (e) {
        results['connection_info'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('DEBUG Firebase: ❌ Connection info failed: $e');
      }

      // Test 6: Write/Read test (if rules allow)
      try {
        print('DEBUG Firebase: Testing write/read operations...');
        final testRef = _database.child('diagnostic_test/${DateTime.now().millisecondsSinceEpoch}');
        final testData = {
          'timestamp': DateTime.now().toIso8601String(),
          'test': 'diagnostic_write_read',
        };
        
        await testRef.set(testData).timeout(const Duration(seconds: 8));
        print('DEBUG Firebase: ✅ Write operation successful');
        
        final readSnapshot = await testRef.get().timeout(const Duration(seconds: 5));
        if (readSnapshot.exists) {
          await testRef.remove(); // Clean up
          results['write_read_test'] = {
            'status': 'success',
            'write': 'success',
            'read': 'success',
            'cleanup': 'success',
          };
          print('DEBUG Firebase: ✅ Write/Read/Cleanup operations successful');
        } else {
          results['write_read_test'] = {
            'status': 'partial_success',
            'write': 'success',
            'read': 'failed',
            'error': 'Data not found after write',
          };
          print('DEBUG Firebase: ⚠️ Write successful but read failed');
        }
      } catch (e) {
        results['write_read_test'] = {
          'status': 'error',
          'error': e.toString(),
          'possible_cause': 'Database rules might not allow write operations',
        };
        print('DEBUG Firebase: ❌ Write/Read test failed: $e');
      }

      // Summary
      final successCount = results.values.where((v) => 
        v is Map && v['status'] == 'success'
      ).length;
      
      results['summary'] = {
        'total_tests': results.length,
        'successful_tests': successCount,
        'overall_status': successCount >= 3 ? 'healthy' : 'issues_detected',
      };
      
      print('DEBUG Firebase: Diagnostic completed - $successCount/${results.length} tests passed');

    } catch (e) {
      results['general_error'] = e.toString();
      print('DEBUG Firebase: ❌ General diagnostic error: $e');
    }

    return results;
  }
  Future<bool> testConnection() async {
    try {
      print('DEBUG Firebase: Testing connection...');
      print('DEBUG Firebase: Database URL: ${_database.root.toString()}');
      
      // Test 1: Check Firebase App initialization
      try {
        final app = Firebase.app();
        print('DEBUG Firebase: App initialized: ${app.name}');
        print('DEBUG Firebase: App options: ${app.options.projectId}');
      } catch (e) {
        print('DEBUG Firebase: App not initialized: $e');
        return false;
      }
      
      // Test 2: Try simple write/read test with shorter timeout
      try {
        final testRef = _database.child('test_connection');
        final testData = {'timestamp': DateTime.now().millisecondsSinceEpoch};
        
        print('DEBUG Firebase: Attempting test write...');
        await testRef.set(testData).timeout(
          const Duration(seconds: 3), // Giảm timeout
          onTimeout: () {
            print('DEBUG Firebase: Test write timeout after 3 seconds');
            throw Exception('Firebase write timeout');
          },
        );
        
        print('DEBUG Firebase: Test write successful, attempting read...');
        final snapshot = await testRef.get().timeout(
          const Duration(seconds: 2), // Giảm timeout cho read
          onTimeout: () {
            print('DEBUG Firebase: Test read timeout after 2 seconds');
            throw Exception('Firebase read timeout');
          },
        );
        
        if (snapshot.exists) {
          print('DEBUG Firebase: Test read successful: ${snapshot.value}');
          // Clean up test data
          await testRef.remove().timeout(const Duration(seconds: 2));
          return true;
        } else {
          print('DEBUG Firebase: Test read failed - no data');
          return false;
        }
      } catch (e) {
        print('DEBUG Firebase: Write/read test failed: $e');
        
        // Quick fallback test - just try to read .info/connected
        try {
          print('DEBUG Firebase: Quick fallback - trying .info/connected...');
          final testRef = _database.child('.info/connected');
          final snapshot = await testRef.get().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print('DEBUG Firebase: Connection info timeout after 2 seconds');
              throw Exception('Firebase connection info timeout');
            },
          );
          
          final isConnected = snapshot.value as bool? ?? false;
          print('DEBUG Firebase: Quick connection info result: $isConnected');
          return isConnected;
        } catch (connectionError) {
          print('DEBUG Firebase: Quick connection test also failed: $connectionError');
          return false;
        }
      }
      
    } catch (e) {
      print('DEBUG Firebase: Connection test failed: $e');
      return false;
    }
  }

  // Generate chat room ID (same logic as React Native)
  String generateChatRoomId(String recruiterId, String candidateId, String? jobId) {
    final sortedIds = [recruiterId, candidateId]..sort();
    return jobId != null ? 
      '${sortedIds[0]}_${sortedIds[1]}_$jobId' :
      '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Create or get chat room (use backend API instead of direct Firebase)
  Future<String> createOrGetChatRoom({
    required String recruiterId,
    required String candidateId,
    String? jobId,
    Map<String, dynamic>? recruiterInfo,
    Map<String, dynamic>? candidateInfo,
    Map<String, dynamic>? jobInfo,
  }) async {
    return _retryOperation(
      () async {
        if (recruiterId.isEmpty || candidateId.isEmpty) {
          throw Exception('Both recruiterId and candidateId are required');
        }

        print('DEBUG Firebase: Creating chat room via backend API');
        print('DEBUG Firebase: Recruiter: $recruiterId, Candidate: $candidateId');

        try {
          // Use backend API to create chat room
          final response = await _dio.post(
            ApiConstants.createChat,
            data: {
              'otherUserId': candidateId, // The other user
              'initiatorUserId': recruiterId, // Current user creating the chat
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
        } on DioException catch (e) {
          print('DEBUG Firebase: Backend create chat error: ${e.message}');
          
          // Fallback: Direct Firebase creation (matching backend structure)
          print('DEBUG Firebase: Falling back to direct Firebase creation...');
          
          final roomId = generateChatRoomId(recruiterId, candidateId, jobId);
          final roomRef = _database.child('chats/$roomId'); // Use 'chats' to match backend
          
          print('DEBUG Firebase: Generated roomId: $roomId');
          print('DEBUG Firebase: Checking if room exists at path: chats/$roomId');
          
          final snapshot = await roomRef.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('DEBUG Firebase: Timeout getting room snapshot');
              throw Exception('Firebase timeout - unable to check room existence');
            },
          );
          
          if (!snapshot.exists) {
            print('DEBUG Firebase: Room does not exist, creating new room...');
            
            // Create new chat room (matching backend ChatRoom structure)
            final room = {
              'Id': roomId,
              'Participants': [recruiterId, candidateId],
              'CreatedAt': DateTime.now().toUtc().toIso8601String(),
              'LastMessageAt': DateTime.now().toUtc().toIso8601String(),
              // Additional metadata
              'recruiterId': recruiterId,
              'candidateId': candidateId,
              'jobId': jobId,
              'recruiterInfo': recruiterInfo,
              'candidateInfo': candidateInfo,
              'jobInfo': jobInfo,
            };
            
            await roomRef.set(room).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('DEBUG Firebase: Timeout setting room data');
                throw Exception('Firebase timeout - unable to create room');
              },
            );
            
            print('DEBUG Firebase: Room created successfully via direct Firebase');
          } else {
            print('DEBUG Firebase: Room already exists');
          }
          
          return roomId;
        }
      },
      'createOrGetChatRoom',
    );
  }
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
          
          await roomRef.set(room).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('DEBUG Firebase: Timeout creating room');
              throw Exception('Firebase timeout - unable to create room');
            },
          );
          print('DEBUG Firebase: Created new chat room: $roomId');
        } else {
          print('DEBUG Firebase: Room exists, checking for updates...');
          
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
            await roomRef.update(updates).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('DEBUG Firebase: Timeout updating room');
                throw Exception('Firebase timeout - unable to update room');
              },
            );
            print('DEBUG Firebase: Updated room with missing info');
          }
          print('DEBUG Firebase: Chat room already exists: $roomId');
        }
        
        return roomId;
      },
      'createOrGetChatRoom',
      maxRetries: 2, // Chỉ retry 2 lần để tránh quá lâu
      delay: const Duration(seconds: 1),
    );
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
          'senderId': senderId, // Include senderId in request body
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
      final messagesQuery = messagesRef.orderByChild('timestamp');

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
          final timeA = a['timestamp'] is String 
              ? DateTime.parse(a['timestamp']).millisecondsSinceEpoch
              : (a['timestamp'] as int? ?? 0);
          final timeB = b['timestamp'] is String 
              ? DateTime.parse(b['timestamp']).millisecondsSinceEpoch 
              : (b['timestamp'] as int? ?? 0);
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
            
            print('DEBUG Firebase: Room $roomId: $roomData');
            
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
          final timeA = a['lastMessageTimestamp'] ?? a['createdAt'] ?? 0;
          final timeB = b['lastMessageTimestamp'] ?? b['createdAt'] ?? 0;
          
          // Handle different timestamp formats
          int getTimestamp(dynamic time) {
            if (time is String) {
              try {
                return DateTime.parse(time).millisecondsSinceEpoch;
              } catch (e) {
                return 0;
              }
            }
            return time is int ? time : 0;
          }
          
          return getTimestamp(timeB).compareTo(getTimestamp(timeA));
        });
        
        print('DEBUG Firebase: Returning ${chatRooms.length} sorted chat rooms');
        return chatRooms;
      });
    } catch (e) {
      print('ERROR Firebase: Error setting up chat rooms subscription: $e');
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

  // Get unread message count (using chats path to match backend)
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

        // Count messages from other users that are not read
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

  // Delete chat room (using chats path to match backend)
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