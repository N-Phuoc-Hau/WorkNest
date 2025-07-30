using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace BEWorkNest.Services
{
    public class FirebaseService
    {
        private readonly FirebaseMessaging _firebaseMessaging;
        private readonly ILogger<FirebaseService> _logger;
        
        public FirebaseService(ILogger<FirebaseService> logger, IConfiguration configuration)
        {
            _logger = logger;
            
            if (FirebaseApp.DefaultInstance == null)
            {
                var serviceAccountKeyPath = configuration["Firebase:ServiceAccountKeyPath"];
                FirebaseApp.Create(new AppOptions()
                {
                    Credential = GoogleCredential.FromFile(serviceAccountKeyPath)
                });
            }
            
            _firebaseMessaging = FirebaseMessaging.DefaultInstance;
        }
        
        public async Task<string> SendPushNotificationAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
        {
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
        
        public async Task<BatchResponse> SendPushNotificationToMultipleAsync(List<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null)
        {
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
