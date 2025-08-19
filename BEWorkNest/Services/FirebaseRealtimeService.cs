using Firebase.Database;
using Firebase.Database.Query;
using SystemTextJson = System.Text.Json;
using Newtonsoft.Json;

namespace BEWorkNest.Services
{
    public class FirebaseRealtimeService
    {
        private readonly FirebaseClient _firebaseClient;
        private readonly ILogger<FirebaseRealtimeService> _logger;

        public FirebaseRealtimeService(ILogger<FirebaseRealtimeService> logger, IConfiguration configuration)
        {
            _logger = logger;
            var databaseUrl = configuration["Firebase:DatabaseUrl"] ?? "https://jobappchat-default-rtdb.asia-southeast1.firebasedatabase.app";
            _firebaseClient = new FirebaseClient(databaseUrl);
        }

        // Chat methods
        public async Task<string> SendMessageAsync(string chatId, ChatMessage message)
        {
            try
            {
                var messageRef = await _firebaseClient
                    .Child("chatRooms") // Changed to chatRooms
                    .Child(chatId)
                    .Child("messages")
                    .PostAsync(SystemTextJson.JsonSerializer.Serialize(message));

                _logger.LogInformation($"Message sent to chat {chatId}: {messageRef.Key}");
                return messageRef.Key;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending message to chat {chatId}");
                throw;
            }
        }

        public async Task<string> CreateChatAsync(string userId1, string userId2)
        {
            try
            {
                var chat = new ChatRoom
                {
                    Id = Guid.NewGuid().ToString(),
                    Participants = new Dictionary<string, ParticipantInfo>
                    {
                        { userId1, new ParticipantInfo { Id = userId1, Role = "user" } },
                        { userId2, new ParticipantInfo { Id = userId2, Role = "user" } }
                    },
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow
                };

                await _firebaseClient
                    .Child("chatRooms") // Changed to chatRooms
                    .Child(chat.Id)
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(chat));

                _logger.LogInformation($"Chat created: {chat.Id}");
                return chat.Id;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating chat");
                throw;
            }
        }

        public async Task<List<ChatRoom>> GetUserChatsAsync(string userId)
        {
            try
            {
                var chats = await _firebaseClient
                    .Child("chatRooms") // Changed to chatRooms
                    .OnceAsync<ChatRoom>();

                return chats
                    .Where(x => x.Object.Participants.ContainsKey(userId))
                    .Select(x => x.Object)
                    .OrderByDescending(x => x.LastMessageAt)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting chats for user {userId}");
                throw;
            }
        }

        public async Task UpdateChatLastMessageAsync(string chatId, DateTime lastMessageAt)
        {
            try
            {
                await _firebaseClient
                    .Child("chatRooms") // Changed to chatRooms
                    .Child(chatId)
                    .Child("lastMessageAt")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(lastMessageAt));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating last message time for chat {chatId}");
                throw;
            }
        }

        // Notification methods
        public async Task<string> CreateNotificationAsync(string userId, NotificationData notification)
        {
            try
            {
                var notificationRef = await _firebaseClient
                    .Child("notifications")
                    .Child(userId)
                    .PostAsync(SystemTextJson.JsonSerializer.Serialize(notification));

                _logger.LogInformation($"Notification created for user {userId}: {notificationRef.Key}");
                return notificationRef.Key;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating notification for user {userId}");
                throw;
            }
        }

        public async Task<List<NotificationData>> GetUserNotificationsAsync(string userId, int limit = 20)
        {
            try
            {
                var notifications = await _firebaseClient
                    .Child("notifications")
                    .Child(userId)
                    .OrderByKey()
                    .LimitToLast(limit)
                    .OnceAsync<NotificationData>();

                return notifications.Select(x => x.Object).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting notifications for user {userId}");
                throw;
            }
        }

        public async Task MarkNotificationAsReadAsync(string userId, string notificationId)
        {
            try
            {
                await _firebaseClient
                    .Child("notifications")
                    .Child(userId)
                    .Child(notificationId)
                    .Child("isRead")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(true));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error marking notification as read: {notificationId}");
                throw;
            }
        }

        // Real-time listeners (for SignalR integration)
        public IDisposable ListenToChatMessages(string chatId, Action<ChatMessage> onMessageReceived)
        {
            return _firebaseClient
                .Child("chatRooms") // Changed to chatRooms
                .Child(chatId)
                .Child("messages")
                .AsObservable<ChatMessage>()
                .Subscribe(message => onMessageReceived(message.Object));
        }

        public IDisposable ListenToUserNotifications(string userId, Action<NotificationData> onNotificationReceived)
        {
            return _firebaseClient
                .Child("notifications")
                .Child(userId)
                .AsObservable<NotificationData>()
                .Subscribe(notification => onNotificationReceived(notification.Object));
        }

        // New methods for ChatController
        public async Task<List<ChatRoom>> GetUserChatRoomsAsync(string userId, string userRole)
        {
            try
            {
                var chatRooms = await _firebaseClient
                    .Child("chatRooms")
                    .OnceAsync<ChatRoom>();

                var filteredRooms = new List<ChatRoom>();

                foreach (var room in chatRooms)
                {
                    var chatRoom = room.Object;
                    chatRoom.Id = room.Key;

                    // Check if user is participant based on role
                    if ((userRole == "recruiter" && chatRoom.RecruiterId == userId) ||
                        (userRole == "candidate" && chatRoom.CandidateId == userId))
                    {
                        filteredRooms.Add(chatRoom);
                    }
                }

                return filteredRooms
                    .OrderByDescending(x => x.LastMessageAt)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting chat rooms for user {userId}");
                throw;
            }
        }

        public async Task<string> CreateOrGetChatRoomAsync(
            string recruiterId,
            string candidateId,
            string? jobId = null,
            Dictionary<string, object>? recruiterInfo = null,
            Dictionary<string, object>? candidateInfo = null,
            Dictionary<string, object>? jobInfo = null)
        {
            try
            {
                // Generate room ID with recruiterId first for consistency
                var roomId = $"{recruiterId}_{candidateId}_{jobId ?? "0"}";
                
                _logger.LogInformation($"Creating/Getting chat room: {roomId} (recruiter: {recruiterId}, candidate: {candidateId}, job: {jobId})");
                
                // Check if room already exists
                var existingRoom = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .OnceSingleAsync<ChatRoom>();

                if (existingRoom != null)
                {
                    _logger.LogInformation($"Chat room already exists: {roomId}");
                    return roomId;
                }

                // Create new room
                var chatRoom = new ChatRoom
                {
                    Id = roomId,
                    RecruiterId = recruiterId,
                    CandidateId = candidateId,
                    JobId = jobId,
                    Participants = new Dictionary<string, ParticipantInfo>
                    {
                        { recruiterId, new ParticipantInfo { Id = recruiterId, Role = "recruiter" } },
                        { candidateId, new ParticipantInfo { Id = candidateId, Role = "candidate" } }
                    },
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow,
                    RecruiterInfo = recruiterInfo?.ToDictionary(kvp => kvp.Key, kvp => kvp.Value?.ToString() ?? string.Empty),
                    CandidateInfo = candidateInfo?.ToDictionary(kvp => kvp.Key, kvp => kvp.Value?.ToString() ?? string.Empty),
                    JobInfo = jobInfo?.ToDictionary(kvp => kvp.Key, kvp => kvp.Value?.ToString() ?? string.Empty)
                };

                _logger.LogInformation($"Creating new chat room with participants: {string.Join(", ", chatRoom.Participants.Keys)}");

                // Use PutAsync with proper JSON serialization
                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .PutAsync(chatRoom);

                // Verify the room was created properly
                var verifyRoom = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .OnceSingleAsync<ChatRoom>();

                if (verifyRoom != null)
                {
                    _logger.LogInformation($"Room {roomId} created successfully. Participants: {(verifyRoom.Participants != null ? string.Join(", ", verifyRoom.Participants.Keys) : "NULL")}");
                }
                else
                {
                    _logger.LogError($"Failed to verify room creation for {roomId}");
                }

                _logger.LogInformation($"Chat room created: {roomId}");
                return roomId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating/getting chat room");
                throw;
            }
        }

        public async Task<bool> UserHasAccessToChatRoomAsync(string roomId, string userId)
        {
            try
            {
                _logger.LogInformation($"Checking access for user {userId} to room {roomId}");
                
                var actualRoomId = await ResolveActualRoomIdAsync(roomId);
                if (actualRoomId == null)
                {
                    _logger.LogWarning($"Room not found: {roomId}");
                    return false;
                }

                _logger.LogInformation($"Resolved room ID: {actualRoomId} (requested: {roomId})");

                // First get the room info to check if user is recruiter or candidate
                var roomInfo = await _firebaseClient
                    .Child("chatRooms")
                    .Child(actualRoomId)
                    .OnceSingleAsync<ChatRoom>();

                if (roomInfo == null)
                {
                    _logger.LogWarning($"Room {actualRoomId} does not exist");
                    return false;
                }

                // Check if user is the recruiter or candidate of this room
                if (roomInfo.RecruiterId == userId || roomInfo.CandidateId == userId)
                {
                    _logger.LogInformation($"User {userId} has access to room {actualRoomId} as room owner (recruiter: {roomInfo.RecruiterId}, candidate: {roomInfo.CandidateId})");
                    return true;
                }

                // Fallback: check participants
                var participants = await _firebaseClient
                    .Child("chatRooms")
                    .Child(actualRoomId)
                    .Child("participants")
                    .OnceSingleAsync<Dictionary<string, ParticipantInfo>>();

                if (participants == null)
                {
                    _logger.LogWarning($"No participants found for room {actualRoomId}, but user is not room owner");
                    return false;
                }

                _logger.LogInformation($"Room {actualRoomId} participants: {string.Join(", ", participants.Keys)}");
                
                var hasAccess = participants.ContainsKey(userId);
                _logger.LogInformation($"User {userId} has access to room {actualRoomId} via participants: {hasAccess}");
                
                return hasAccess;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking user access to chat room {roomId}");
                return false;
            }
        }

        private async Task<string?> ResolveActualRoomIdAsync(string roomId)
        {
            try
            {
                // Check if original room ID exists
                var room = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .OnceSingleAsync<object>();

                if (room != null) return roomId;

                // Try alternative format
                var parts = roomId.Split('_');
                if (parts.Length == 3)
                {
                    var altRoomId = $"{parts[1]}_{parts[0]}_{parts[2]}";
                    room = await _firebaseClient
                        .Child("chatRooms")
                        .Child(altRoomId)
                        .OnceSingleAsync<object>();

                    if (room != null) return altRoomId;
                }

                return null;
            }
            catch
            {
                return null;
            }
        }

        public async Task<List<ChatMessage>> GetChatMessagesAsync(string roomId, int page = 1, int limit = 50)
        {
            try
            {
                var actualRoomId = await ResolveActualRoomIdAsync(roomId);
                if (actualRoomId == null)
                {
                    _logger.LogWarning($"Room not found: {roomId}");
                    return new List<ChatMessage>();
                }

                _logger.LogInformation($"Getting messages from room: {actualRoomId} (requested: {roomId})");

                var messages = await _firebaseClient
                    .Child("chatRooms")
                    .Child(actualRoomId)
                    .Child("messages")
                    .OrderByKey()
                    .LimitToLast(limit)
                    .OnceAsync<ChatMessage>();

                return messages
                    .Select(x => { x.Object.Id = x.Key; return x.Object; })
                    .OrderBy(x => x.Timestamp)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting messages for room {roomId}");
                throw;
            }
        }

        public async Task<string> SendTextMessageAsync(string roomId, string senderId, string? senderRole, string content)
        {
            try
            {
                var message = new ChatMessage
                {
                    Id = Guid.NewGuid().ToString(),
                    SenderId = senderId,
                    SenderRole = senderRole ?? "user",
                    Content = content,
                    MessageType = "text",
                    Timestamp = DateTime.UtcNow,
                    IsRead = false
                };

                var messageRef = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("messages")
                    .PostAsync(message);

                // Update last message info
                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessage")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(content));

                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessageAt")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(DateTime.UtcNow));

                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessageSenderId")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(senderId));

                _logger.LogInformation($"Text message sent to room {roomId}: {messageRef.Key}");
                return messageRef.Key;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending text message to room {roomId}");
                throw;
            }
        }

        public async Task<string> SendImageMessageAsync(string roomId, string senderId, string? senderRole, string imageUrl, string? caption = null)
        {
            try
            {
                var message = new ChatMessage
                {
                    Id = Guid.NewGuid().ToString(),
                    SenderId = senderId,
                    SenderRole = senderRole ?? "user",
                    Content = caption ?? "Image",
                    MessageType = "image",
                    Timestamp = DateTime.UtcNow,
                    IsRead = false,
                    FileUrl = imageUrl
                };

                var messageRef = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("messages")
                    .PostAsync(message);

                // Update last message info
                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessage")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize("📷 Image"));

                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessageAt")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(DateTime.UtcNow));

                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .Child("lastMessageSenderId")
                    .PutAsync(SystemTextJson.JsonSerializer.Serialize(senderId));

                _logger.LogInformation($"Image message sent to room {roomId}: {messageRef.Key}");
                return messageRef.Key;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending image message to room {roomId}");
                throw;
            }
        }

        public async Task MarkMessagesAsReadAsync(string roomId, string userId)
        {
            try
            {
                var actualRoomId = await ResolveActualRoomIdAsync(roomId);
                if (actualRoomId == null)
                {
                    _logger.LogWarning($"Room not found for marking as read: {roomId}");
                    return;
                }

                _logger.LogInformation($"Marking messages as read in room: {actualRoomId} (requested: {roomId}) by user {userId}");

                var messages = await _firebaseClient
                    .Child("chatRooms")
                    .Child(actualRoomId)
                    .Child("messages")
                    .OnceAsync<ChatMessage>();

                var unreadMessages = messages.Where(m => m.Object.SenderId != userId && !m.Object.IsRead);

                foreach (var message in unreadMessages)
                {
                    await _firebaseClient
                        .Child("chatRooms")
                        .Child(actualRoomId)
                        .Child("messages")
                        .Child(message.Key)
                        .Child("isRead")
                        .PutAsync(true);
                }

                _logger.LogInformation($"Messages marked as read for room {actualRoomId} by user {userId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error marking messages as read for room {roomId}");
                throw;
            }
        }

        public async Task DeleteChatRoomAsync(string roomId)
        {
            try
            {
                await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .DeleteAsync();

                _logger.LogInformation($"Chat room deleted: {roomId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting chat room {roomId}");
                throw;
            }
        }

        public async Task<ChatRoom?> GetChatRoomInfoAsync(string roomId)
        {
            try
            {
                var chatRoom = await _firebaseClient
                    .Child("chatRooms")
                    .Child(roomId)
                    .OnceSingleAsync<ChatRoom>();

                if (chatRoom != null)
                {
                    chatRoom.Id = roomId;
                }

                return chatRoom;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting chat room info for {roomId}");
                throw;
            }
        }
    }

    public class ChatMessage
    {
        public string Id { get; set; } = string.Empty;
        public string SenderId { get; set; } = string.Empty;
        public string SenderRole { get; set; } = string.Empty; // "candidate" or "recruiter"
        public string Content { get; set; } = string.Empty;
        public string MessageType { get; set; } = "text"; // text, image, file
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public bool IsRead { get; set; } = false;
        public string? FileUrl { get; set; }
        public string? FileName { get; set; }
    }

    public class ParticipantInfo
    {
        public string Id { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty; // "candidate" or "recruiter"
    }

    public class ChatRoom
    {
        public string Id { get; set; } = string.Empty;
        public string RecruiterId { get; set; } = string.Empty;
        public string CandidateId { get; set; } = string.Empty;
        public string? JobId { get; set; }
        public Dictionary<string, ParticipantInfo> Participants { get; set; } = new Dictionary<string, ParticipantInfo>();
        
        [JsonProperty("createdAt")]
        [JsonConverter(typeof(FlexibleTimestampConverter))]
        public long CreatedAtTimestamp { get; set; }
        
        [JsonIgnore]
        public DateTime CreatedAt 
        { 
            get => DateTimeOffset.FromUnixTimeMilliseconds(CreatedAtTimestamp).DateTime;
            set => CreatedAtTimestamp = ((DateTimeOffset)value).ToUnixTimeMilliseconds();
        }
        
        [JsonProperty("lastMessageAt")]
        [JsonConverter(typeof(FlexibleTimestampConverter))]
        public long LastMessageAtTimestamp { get; set; }
        
        [JsonIgnore]
        public DateTime LastMessageAt 
        { 
            get => DateTimeOffset.FromUnixTimeMilliseconds(LastMessageAtTimestamp).DateTime;
            set => LastMessageAtTimestamp = ((DateTimeOffset)value).ToUnixTimeMilliseconds();
        }
        
        public string? LastMessage { get; set; }
        public string? LastMessageSenderId { get; set; }
        public Dictionary<string, string>? RecruiterInfo { get; set; }
        public Dictionary<string, string>? CandidateInfo { get; set; }
        public Dictionary<string, string>? JobInfo { get; set; }
    }

    public class NotificationData
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // job_application, message, system
        public string? Data { get; set; } // JSON data
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public bool IsRead { get; set; } = false;
        public string? ImageUrl { get; set; }
    }
}

// Custom converter để handle cả Unix timestamp và DateTime string
public class FlexibleTimestampConverter : JsonConverter<long>
{
    public override long ReadJson(JsonReader reader, Type objectType, long existingValue, bool hasExistingValue, JsonSerializer serializer)
    {
        if (reader.Value == null)
            return 0;

        // Nếu là số (Unix timestamp)
        if (reader.Value is long longValue)
            return longValue;

        // Nếu là DateTime string
        if (reader.Value is string stringValue && DateTime.TryParse(stringValue, out DateTime dateTime))
        {
            return ((DateTimeOffset)dateTime.ToUniversalTime()).ToUnixTimeMilliseconds();
        }

        // Nếu là DateTime object
        if (reader.Value is DateTime dateTimeValue)
        {
            return ((DateTimeOffset)dateTimeValue.ToUniversalTime()).ToUnixTimeMilliseconds();
        }

        return 0;
    }

    public override void WriteJson(JsonWriter writer, long value, JsonSerializer serializer)
    {
        writer.WriteValue(value);
    }
}