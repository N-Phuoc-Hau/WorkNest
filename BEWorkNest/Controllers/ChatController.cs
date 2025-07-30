using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Services;
using BEWorkNest.Models.DTOs;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly FirebaseRealtimeService _firebaseService;
        private readonly FirebaseService _firebaseMessagingService;
        private readonly ILogger<ChatController> _logger;

        public ChatController(
            FirebaseRealtimeService firebaseService,
            FirebaseService firebaseMessagingService,
            ILogger<ChatController> logger)
        {
            _firebaseService = firebaseService;
            _firebaseMessagingService = firebaseMessagingService;
            _logger = logger;
        }

        [HttpPost("send-message")]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageDto dto)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var message = new ChatMessage
                {
                    Id = Guid.NewGuid().ToString(),
                    SenderId = userId,
                    Content = dto.Content,
                    MessageType = dto.MessageType ?? "text",
                    Timestamp = DateTime.UtcNow,
                    FileUrl = dto.FileUrl,
                    FileName = dto.FileName
                };

                var messageId = await _firebaseService.SendMessageAsync(dto.ChatId, message);
                
                // Update last message info
                await _firebaseService.UpdateChatLastMessageAsync(dto.ChatId, DateTime.UtcNow);

                // Send push notification to other participants
                await SendNotificationToChatParticipants(dto.ChatId, userId, dto.Content);

                return Ok(new { messageId, message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                return BadRequest(new { message = "Failed to send message", error = ex.Message });
            }
        }

        [HttpGet("messages/{chatId}")]
        public async Task<IActionResult> GetChatMessages(string chatId, [FromQuery] int limit = 50)
        {
            try
            {
                var messages = await _firebaseService.GetChatMessagesAsync(chatId, limit);
                return Ok(messages);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting messages for chat {chatId}");
                return BadRequest(new { message = "Failed to get messages", error = ex.Message });
            }
        }

        [HttpPost("create-chat")]
        public async Task<IActionResult> CreateChat([FromBody] CreateChatDto dto)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var chatId = await _firebaseService.CreateChatAsync(userId, dto.OtherUserId);
                return Ok(new { chatId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating chat");
                return BadRequest(new { message = "Failed to create chat", error = ex.Message });
            }
        }

        [HttpGet("user-chats")]
        public async Task<IActionResult> GetUserChats()
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var chats = await _firebaseService.GetUserChatsAsync(userId);
                return Ok(chats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting chats for user");
                return BadRequest(new { message = "Failed to get chats", error = ex.Message });
            }
        }

        [HttpPost("mark-as-read/{chatId}")]
        public async Task<IActionResult> MarkChatAsRead(string chatId)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                // Mark messages as read logic here
                // This would update the messages in Firebase Realtime Database

                return Ok(new { message = "Chat marked as read" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error marking chat as read: {chatId}");
                return BadRequest(new { message = "Failed to mark chat as read", error = ex.Message });
            }
        }

        private async Task SendNotificationToChatParticipants(string chatId, string senderId, string messageContent)
        {
            try
            {
                // Get chat participants
                var chats = await _firebaseService.GetUserChatsAsync(senderId);
                var chat = chats.FirstOrDefault(c => c.Id == chatId);
                
                if (chat != null)
                {
                    var otherParticipants = chat.Participants.Where(p => p != senderId).ToList();
                    
                    foreach (var participantId in otherParticipants)
                    {
                        // Get FCM token for participant (you'll need to implement this)
                        // var fcmToken = await GetUserFcmToken(participantId);
                        
                        // Send push notification
                        // await _firebaseMessagingService.SendPushNotificationAsync(
                        //     fcmToken,
                        //     "New Message",
                        //     messageContent.Length > 50 ? messageContent.Substring(0, 50) + "..." : messageContent
                        // );
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending notification to chat participants");
            }
        }
    }

    public class SendMessageDto
    {
        public string ChatId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? MessageType { get; set; }
        public string? FileUrl { get; set; }
        public string? FileName { get; set; }
    }

    public class CreateChatDto
    {
        public string OtherUserId { get; set; } = string.Empty;
    }
} 