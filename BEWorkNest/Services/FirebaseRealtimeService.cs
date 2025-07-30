using Firebase.Database;
using Firebase.Database.Query;
using System.Text.Json;

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
                    .Child("chats")
                    .Child(chatId)
                    .Child("messages")
                    .PostAsync(JsonSerializer.Serialize(message));

                _logger.LogInformation($"Message sent to chat {chatId}: {messageRef.Key}");
                return messageRef.Key;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending message to chat {chatId}");
                throw;
            }
        }

        public async Task<List<ChatMessage>> GetChatMessagesAsync(string chatId, int limit = 50)
        {
            try
            {
                var messages = await _firebaseClient
                    .Child("chats")
                    .Child(chatId)
                    .Child("messages")
                    .OrderByKey()
                    .LimitToLast(limit)
                    .OnceAsync<ChatMessage>();

                return messages.Select(x => x.Object).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting messages for chat {chatId}");
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
                    Participants = new List<string> { userId1, userId2 },
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow
                };

                await _firebaseClient
                    .Child("chats")
                    .Child(chat.Id)
                    .PutAsync(JsonSerializer.Serialize(chat));

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
                    .Child("chats")
                    .OnceAsync<ChatRoom>();

                return chats
                    .Where(x => x.Object.Participants.Contains(userId))
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
                    .Child("chats")
                    .Child(chatId)
                    .Child("lastMessageAt")
                    .PutAsync(JsonSerializer.Serialize(lastMessageAt));
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
                    .PostAsync(JsonSerializer.Serialize(notification));

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
                    .PutAsync(JsonSerializer.Serialize(true));
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
                .Child("chats")
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
    }

    public class ChatMessage
    {
        public string Id { get; set; } = string.Empty;
        public string SenderId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string MessageType { get; set; } = "text"; // text, image, file
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public bool IsRead { get; set; } = false;
        public string? FileUrl { get; set; }
        public string? FileName { get; set; }
    }

    public class ChatRoom
    {
        public string Id { get; set; } = string.Empty;
        public List<string> Participants { get; set; } = new List<string>();
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;
        public string? LastMessage { get; set; }
        public string? LastMessageSenderId { get; set; }
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