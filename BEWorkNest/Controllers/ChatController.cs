using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Services;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private const string AuthRequiredMessage = "Không có quyền truy cập. Vui lòng đăng nhập.";
        private const string AuthRequiredCode = "AUTH_REQUIRED";
        private const string NoAccessMessage = "You don't have access to this chat room";
        
        private readonly FirebaseRealtimeService _firebaseService;
        private readonly CloudinaryService _cloudinaryService;
        private readonly JwtService _jwtService;
        private readonly NotificationService _notificationService;
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ChatController> _logger;

        public ChatController(
            FirebaseRealtimeService firebaseService,
            CloudinaryService cloudinaryService,
            JwtService jwtService,
            NotificationService notificationService,
            ApplicationDbContext context,
            ILogger<ChatController> logger)
        {
            _firebaseService = firebaseService;
            _cloudinaryService = cloudinaryService;
            _jwtService = jwtService;
            _notificationService = notificationService;
            _context = context;
            _logger = logger;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // If not found from claims, try to extract from Authorization header
            if (string.IsNullOrEmpty(userId) && Request.Headers.ContainsKey("Authorization"))
            {
                var authHeader = Request.Headers["Authorization"].FirstOrDefault();
                if (authHeader != null && authHeader.StartsWith("Bearer "))
                {
                    var token = authHeader.Substring("Bearer ".Length).Trim();
                    if (!string.IsNullOrEmpty(token))
                    {
                        try
                        {
                            userId = _jwtService.GetUserIdFromToken(token);
                            userRole = _jwtService.GetRoleFromToken(token);
                            isAuthenticated = !string.IsNullOrEmpty(userId);
                        }
                        catch (Exception)
                        {
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        /// <summary>
        /// Lấy danh sách phòng chat của user hiện tại
        /// </summary>
        [HttpGet("rooms")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUserChatRooms()
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                if (string.IsNullOrEmpty(userRole))
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy thông tin vai trò người dùng",
                        errorCode = "USER_ROLE_NOT_FOUND"
                    });
                }

                _logger.LogInformation("Getting chat rooms for user: {UserId}, role: {UserRole}", userId, userRole);

                var chatRooms = await _firebaseService.GetUserChatRoomsAsync(userId, userRole!);
                
                return Ok(new { success = true, data = chatRooms });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user chat rooms");
                return StatusCode(500, new { message = "Error retrieving chat rooms", error = ex.Message });
            }
        }

        /// <summary>
        /// Tạo hoặc lấy phòng chat giữa recruiter và candidate cho job cụ thể
        /// </summary>
        [HttpPost("rooms")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateOrGetChatRoom([FromBody] CreateChatRoomDto dto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Creating/Getting chat room between recruiter: {dto.RecruiterId} and candidate: {dto.CandidateId} for job: {dto.JobId}");

                // Convert Dictionary<string, object> to Dictionary<string, string> to avoid serialization issues
                Dictionary<string, string>? recruiterInfo = null;
                Dictionary<string, string>? candidateInfo = null;
                Dictionary<string, string>? jobInfo = null;

                if (dto.RecruiterInfo != null)
                {
                    recruiterInfo = dto.RecruiterInfo.ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value?.ToString() ?? string.Empty
                    );
                }

                if (dto.CandidateInfo != null)
                {
                    candidateInfo = dto.CandidateInfo.ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value?.ToString() ?? string.Empty
                    );
                }

                if (dto.JobInfo != null)
                {
                    jobInfo = dto.JobInfo.ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value?.ToString() ?? string.Empty
                    );
                }

                var roomId = await _firebaseService.CreateOrGetChatRoomAsync(
                    recruiterId: dto.RecruiterId,
                    candidateId: dto.CandidateId,
                    jobId: dto.JobId,
                    recruiterInfo: recruiterInfo?.ToDictionary(kvp => kvp.Key, kvp => (object)kvp.Value),
                    candidateInfo: candidateInfo?.ToDictionary(kvp => kvp.Key, kvp => (object)kvp.Value),
                    jobInfo: jobInfo?.ToDictionary(kvp => kvp.Key, kvp => (object)kvp.Value)
                );

                return Ok(new { success = true, roomId = roomId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating chat room");
                return StatusCode(500, new { message = "Error creating chat room", error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy tin nhắn từ phòng chat
        /// </summary>
        [HttpGet("rooms/{roomId}/messages")]
        [AllowAnonymous]
        public async Task<IActionResult> GetChatMessages(string roomId, [FromQuery] int page = 1, [FromQuery] int limit = 50)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Getting messages for room: {roomId}, user: {userId}, role: {userRole}");

                // Verify user has access to this chat room
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(roomId, userId);
                if (!hasAccess)
                {
                    _logger.LogWarning($"Access denied for user {userId} to room {roomId}");
                    return StatusCode(403, new { 
                        message = "You don't have access to this chat room",
                        errorCode = "ACCESS_DENIED"
                    });
                }

                var messages = await _firebaseService.GetChatMessagesAsync(roomId, page, limit);
                
                return Ok(new { success = true, data = messages });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting chat messages");
                return StatusCode(500, new { message = "Error retrieving messages", error = ex.Message });
            }
        }

        /// <summary>
        /// Gửi tin nhắn text
        /// </summary>
        [HttpPost("messages/text")]
        [AllowAnonymous]
        public async Task<IActionResult> SendTextMessage([FromBody] SendTextMessageDto dto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                if (string.IsNullOrEmpty(userRole))
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy thông tin vai trò người dùng",
                        errorCode = "USER_ROLE_NOT_FOUND"
                    });
                }
                
                _logger.LogInformation($"Sending text message from user: {userId} to room: {dto.RoomId}");

                // Verify user has access to this chat room
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(dto.RoomId, userId);
                if (!hasAccess)
                    return StatusCode(403, new { 
                        message = "You don't have access to this chat room",
                        errorCode = "ACCESS_DENIED"
                    });

                var messageId = await _firebaseService.SendTextMessageAsync(
                    roomId: dto.RoomId,
                    senderId: userId,
                    senderRole: userRole!,
                    content: dto.Content
                );

                // Send notification to the other user in the chat room
                try
                {
                    var roomInfo = await _firebaseService.GetChatRoomInfoAsync(dto.RoomId);
                    if (roomInfo != null)
                    {
                        // Determine the recipient (the other user in the chat room)
                        var recipientId = roomInfo.CandidateId == userId ? roomInfo.RecruiterId : roomInfo.CandidateId;
                        
                        // Get sender name from database
                        var sender = await _context.Users.FindAsync(userId);
                        var senderName = sender != null ? $"{sender.FirstName} {sender.LastName}".Trim() : "Unknown User";
                        
                        // Send chat notification
                        await _notificationService.SendChatNotificationAsync(
                            fromUserId: userId,
                            toUserId: recipientId,
                            fromUserName: senderName,
                            roomId: dto.RoomId,
                            message: dto.Content
                        );
                    }
                }
                catch (Exception notificationEx)
                {
                    _logger.LogError(notificationEx, "Failed to send chat notification for message {MessageId}", messageId);
                    // Don't fail the message sending if notification fails
                }

                return Ok(new { success = true, messageId = messageId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending text message");
                return StatusCode(500, new { message = "Error sending message", error = ex.Message });
            }
        }

        /// <summary>
        /// Upload ảnh và gửi tin nhắn hình ảnh
        /// </summary>
        [HttpPost("messages/image")]
        [AllowAnonymous]
        public async Task<IActionResult> SendImageMessage([FromForm] SendImageMessageDto dto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                if (string.IsNullOrEmpty(userRole))
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy thông tin vai trò người dùng",
                        errorCode = "USER_ROLE_NOT_FOUND"
                    });
                }

                _logger.LogInformation($"Sending image message from user: {userId} to room: {dto.RoomId}");

                // Verify user has access to this chat room
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(dto.RoomId, userId);
                if (!hasAccess)
                    return StatusCode(403, new { message = "You don't have access to this chat room", errorCode = "ACCESS_DENIED" });

                // Validate image file
                if (dto.ImageFile == null || dto.ImageFile.Length == 0)
                    return BadRequest("Image file is required");

                var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
                if (!allowedTypes.Contains(dto.ImageFile.ContentType.ToLower()))
                    return BadRequest("Only JPEG, PNG and GIF images are allowed");

                if (dto.ImageFile.Length > 10 * 1024 * 1024) // 10MB limit
                    return BadRequest("Image file size cannot exceed 10MB");

                // Upload to Cloudinary
                _logger.LogInformation("Uploading image to Cloudinary...");
                var imageUrl = await _cloudinaryService.UploadImageAsync(dto.ImageFile, "chat_images");

                // Send image message to Firebase
                var messageId = await _firebaseService.SendImageMessageAsync(
                    roomId: dto.RoomId,
                    senderId: userId,
                    senderRole: userRole!,
                    imageUrl: imageUrl,
                    caption: dto.Caption
                );

                return Ok(new { 
                    success = true, 
                    messageId = messageId,
                    imageUrl = imageUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending image message");
                return StatusCode(500, new { message = "Error sending image", error = ex.Message });
            }
        }

        /// <summary>
        /// Đánh dấu tin nhắn đã đọc
        /// </summary>
        [HttpPost("rooms/{roomId}/mark-read")]
        [AllowAnonymous]
        public async Task<IActionResult> MarkMessagesAsRead(string roomId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Marking messages as read for room: {roomId}, user: {userId}, role: {userRole}");

                // Verify user has access to this chat room
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(roomId, userId);
                if (!hasAccess)
                {
                    _logger.LogWarning($"Access denied for user {userId} when marking messages as read in room {roomId}");
                    return StatusCode(403, new { message = "You don't have access to this chat room", errorCode = "ACCESS_DENIED" });
                }

                await _firebaseService.MarkMessagesAsReadAsync(roomId, userId);
                
                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking messages as read");
                return StatusCode(500, new { message = "Error marking messages as read", error = ex.Message });
            }
        }

        /// <summary>
        /// Xóa phòng chat
        /// </summary>
        [HttpDelete("rooms/{roomId}")]
        [AllowAnonymous] // Changed to allow checking role through token
        public async Task<IActionResult> DeleteChatRoom(string roomId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                if (userRole?.ToLower() != "recruiter")
                {
                    return BadRequest(new { 
                        message = "Chỉ nhà tuyển dụng mới có thể xóa phòng chat.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                _logger.LogInformation($"Deleting chat room: {roomId} by user: {userId}");

                // Verify user has access to this chat room and is the recruiter
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(roomId, userId);
                if (!hasAccess)
                    return StatusCode(403, new { message = "You don't have access to this chat room", errorCode = "ACCESS_DENIED" });

                await _firebaseService.DeleteChatRoomAsync(roomId);
                
                return Ok(new { success = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting chat room");
                return StatusCode(500, new { message = "Error deleting chat room", error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy thông tin phòng chat
        /// </summary>
        [HttpGet("rooms/{roomId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetChatRoomInfo(string roomId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Getting chat room info: {roomId} for user: {userId}");

                // Verify user has access to this chat room
                var hasAccess = await _firebaseService.UserHasAccessToChatRoomAsync(roomId, userId);
                if (!hasAccess)
                    return StatusCode(403, new { message = "You don't have access to this chat room", errorCode = "ACCESS_DENIED" });

                var roomInfo = await _firebaseService.GetChatRoomInfoAsync(roomId);
                
                return Ok(new { success = true, data = roomInfo });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting chat room info");
                return StatusCode(500, new { message = "Error getting chat room info", error = ex.Message });
            }
        }
    }
}
