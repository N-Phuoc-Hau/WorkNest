using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using System.IO;

namespace BEWorkNest.Services
{
    public class FirebaseService
    {
        private readonly FirebaseMessaging? _firebaseMessaging;
        private readonly ILogger<FirebaseService> _logger;
        
        public FirebaseService(ILogger<FirebaseService> logger, IConfiguration configuration)
        {
            _logger = logger;
            
            if (FirebaseApp.DefaultInstance == null)
            {
                // Try multiple paths for service account key
                var serviceAccountKeyPath = configuration["Firebase:ServiceAccountKeyPath"];
                
                // Fallback paths
                var fallbackPaths = new[]
                {
                    serviceAccountKeyPath,
                    "firebase-service-account.json",
                    "firebase-adminsdk.json",
                    Path.Combine(Directory.GetCurrentDirectory(), "firebase-service-account.json")
                };
                
                string? validPath = null;
                foreach (var path in fallbackPaths)
                {
                    if (!string.IsNullOrEmpty(path) && File.Exists(path))
                    {
                        validPath = path;
                        break;
                    }
                }
                
                if (validPath == null)
                {
                    _logger.LogWarning("Firebase service account key file not found in any of the expected locations. Firebase service will not be available.");
                    _logger.LogWarning($"Tried paths: {string.Join(", ", fallbackPaths.Where(p => !string.IsNullOrEmpty(p)))}");
                    return;
                }
                
                try
                {
                    FirebaseApp.Create(new AppOptions()
                    {
                        Credential = GoogleCredential.FromFile(validPath)
                    });
                    _logger.LogInformation($"Firebase app initialized successfully using: {validPath}");
                    _logger.LogInformation("Firebase project: jobappchat");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to initialize Firebase app. Firebase service will not be available.");
                    return;
                }
            }
            
            try
            {
                _firebaseMessaging = FirebaseMessaging.DefaultInstance;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get Firebase messaging instance. Firebase service will not be available.");
            }
        }
        
        public async Task<string> SendPushNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Push notification will not be sent.");
                return string.Empty;
            }
            
            try
            {
                var message = new Message()
                {
                    Token = fcmToken,
                    Notification = new Notification()
                    {
                        Title = title,
                        Body = body
                    },
                    Data = data ?? new Dictionary<string, string>(),
                    Android = new AndroidConfig()
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification()
                        {
                            Title = title,
                            Body = body,
                            Icon = "ic_notification",
                            Color = "#FF6B35"
                        }
                    },
                    Apns = new ApnsConfig()
                    {
                        Aps = new Aps()
                        {
                            Alert = new ApsAlert()
                            {
                                Title = title,
                                Body = body
                            },
                            Badge = 1,
                            Sound = "default"
                        }
                    },
                    Webpush = new WebpushConfig()
                    {
                        Notification = new WebpushNotification()
                        {
                            Title = title,
                            Body = body,
                            Icon = "/icons/icon-192x192.png"
                        }
                    }
                };
                
                var response = await _firebaseMessaging.SendAsync(message);
                _logger.LogInformation($"Successfully sent message: {response}");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending push notification to token: {fcmToken}");
                throw;
            }
        }
        
        public async Task<string> SendChatNotificationAsync(string fcmToken, string senderName, string message, string chatRoomId, Dictionary<string, string>? additionalData = null)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Chat notification will not be sent.");
                return string.Empty;
            }
            
            try
            {
                var data = new Dictionary<string, string>
                {
                    ["type"] = "chat",
                    ["chatRoomId"] = chatRoomId,
                    ["senderName"] = senderName,
                    ["message"] = message
                };
                
                if (additionalData != null)
                {
                    foreach (var item in additionalData)
                    {
                        data[item.Key] = item.Value;
                    }
                }
                
                var notificationMessage = new Message()
                {
                    Token = fcmToken,
                    Notification = new Notification()
                    {
                        Title = $"Tin nhắn từ {senderName}",
                        Body = message.Length > 50 ? message.Substring(0, 47) + "..." : message
                    },
                    Data = data,
                    Android = new AndroidConfig()
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification()
                        {
                            Title = $"Tin nhắn từ {senderName}",
                            Body = message.Length > 50 ? message.Substring(0, 47) + "..." : message,
                            Icon = "ic_chat",
                            Color = "#4CAF50",
                            Sound = "default",
                            ChannelId = "chat_messages"
                        }
                    },
                    Apns = new ApnsConfig()
                    {
                        Aps = new Aps()
                        {
                            Alert = new ApsAlert()
                            {
                                Title = $"Tin nhắn từ {senderName}",
                                Body = message.Length > 50 ? message.Substring(0, 47) + "..." : message
                            },
                            Badge = 1,
                            Sound = "default",
                            Category = "chat"
                        }
                    },
                    Webpush = new WebpushConfig()
                    {
                        Notification = new WebpushNotification()
                        {
                            Title = $"Tin nhắn từ {senderName}",
                            Body = message.Length > 50 ? message.Substring(0, 47) + "..." : message,
                            Icon = "/icons/chat-icon.png",
                            Tag = chatRoomId
                        }
                    }
                };
                
                var response = await _firebaseMessaging.SendAsync(notificationMessage);
                _logger.LogInformation($"Successfully sent chat notification: {response}");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending chat notification to token: {fcmToken}");
                throw;
            }
        }
        
        public async Task<BatchResponse?> SendPushNotificationToMultipleAsync(List<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Push notifications will not be sent.");
                return null;
            }
            
            try
            {
                var messages = fcmTokens.Select(token => new Message()
                {
                    Token = token,
                    Notification = new Notification()
                    {
                        Title = title,
                        Body = body
                    },
                    Data = data ?? new Dictionary<string, string>()
                }).ToList();
                
                var response = await _firebaseMessaging.SendEachAsync(messages);
                _logger.LogInformation($"Successfully sent {response.SuccessCount} messages");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending push notifications to multiple tokens");
                throw;
            }
        }
        
        public async Task<string> SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Topic message will not be sent.");
                return string.Empty;
            }
            
            try
            {
                var message = new Message()
                {
                    Topic = topic,
                    Notification = new Notification()
                    {
                        Title = title,
                        Body = body
                    },
                    Data = data ?? new Dictionary<string, string>()
                };
                
                var response = await _firebaseMessaging.SendAsync(message);
                _logger.LogInformation($"Successfully sent message to topic {topic}: {response}");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending message to topic: {topic}");
                throw;
            }
        }
        
        public async Task SubscribeToTopicAsync(List<string> fcmTokens, string topic)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Topic subscription will not be performed.");
                return;
            }
            
            try
            {
                var response = await _firebaseMessaging.SubscribeToTopicAsync(fcmTokens, topic);
                _logger.LogInformation($"Successfully subscribed {response.SuccessCount} tokens to topic {topic}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error subscribing to topic: {topic}");
                throw;
            }
        }
        
        public async Task UnsubscribeFromTopicAsync(List<string> fcmTokens, string topic)
        {
            if (_firebaseMessaging == null)
            {
                _logger.LogWarning("Firebase messaging is not available. Topic unsubscription will not be performed.");
                return;
            }
            
            try
            {
                var response = await _firebaseMessaging.UnsubscribeFromTopicAsync(fcmTokens, topic);
                _logger.LogInformation($"Successfully unsubscribed {response.SuccessCount} tokens from topic {topic}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error unsubscribing from topic: {topic}");
                throw;
            }
        }
    }
}
