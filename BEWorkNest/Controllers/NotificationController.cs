using BEWorkNest.Models.DTOs;
using BEWorkNest.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class NotificationController : ControllerBase
    {
        private readonly NotificationService _notificationService;
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;
        
        public NotificationController(NotificationService notificationService, ApplicationDbContext context, JwtService jwtService)
        {
            _notificationService = notificationService;
            _context = context;
            _jwtService = jwtService;
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
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Error extracting user info from token: {ex.Message}");
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }
        
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            var notifications = await _notificationService.GetUserNotificationsAsync(userId, page, pageSize);
            
            var totalCount = await _context.Notifications
                .CountAsync(n => n.UserId == userId);
            
            return Ok(new
            {
                notifications,
                totalCount,
                currentPage = page,
                pageSize,
                totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
            });
        }
        
        [HttpPost("mark-read/{notificationId}")]
        [AllowAnonymous]
        public async Task<IActionResult> MarkAsRead(int notificationId)
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            var success = await _notificationService.MarkNotificationAsReadAsync(notificationId, userId);
            
            if (!success)
            {
                return NotFound(new { message = "Notification not found" });
            }
            
            return Ok(new { message = "Notification marked as read" });
        }
        
        [HttpPost("mark-all-read")]
        [AllowAnonymous]
        public async Task<IActionResult> MarkAllAsRead()
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            await _notificationService.MarkAllNotificationsAsReadAsync(userId);
            
            return Ok(new { message = "All notifications marked as read" });
        }
        
        [HttpGet("unread-count")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUnreadCount()
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            var count = await _notificationService.GetUnreadNotificationCountAsync(userId);
            
            return Ok(new { unreadCount = count });
        }
        
        [HttpPost("device-token")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterDeviceToken([FromBody] DeviceTokenDto dto)
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            // Check if device already exists
            var existingDevice = await _context.UserDevices
                .FirstOrDefaultAsync(ud => ud.UserId == userId && ud.FcmToken == dto.FcmToken);
            
            if (existingDevice != null)
            {
                // Update existing device
                existingDevice.DeviceType = dto.DeviceType;
                existingDevice.DeviceName = dto.DeviceName;
                existingDevice.IsActive = true;
                existingDevice.LastUsed = DateTime.UtcNow;
                existingDevice.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                // Create new device
                var userDevice = new UserDevice
                {
                    UserId = userId,
                    FcmToken = dto.FcmToken,
                    DeviceType = dto.DeviceType,
                    DeviceName = dto.DeviceName,
                    IsActive = true,
                    LastUsed = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow
                };
                
                _context.UserDevices.Add(userDevice);
            }
            
            await _context.SaveChangesAsync();
            
            return Ok(new { message = "Device token registered successfully" });
        }
        
        [HttpDelete("device-token")]
        [AllowAnonymous]
        public async Task<IActionResult> UnregisterDeviceToken([FromBody] DeviceTokenDto dto)
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            var device = await _context.UserDevices
                .FirstOrDefaultAsync(ud => ud.UserId == userId && ud.FcmToken == dto.FcmToken);
            
            if (device != null)
            {
                device.IsActive = false;
                device.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
            
            return Ok(new { message = "Device token unregistered successfully" });
        }
        
        [HttpGet("my-devices")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyDevices()
        {
            // Get user info from JWT token
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { 
                    message = "Token không hợp lệ hoặc đã hết hạn",
                    errorCode = "INVALID_TOKEN"
                });
            }
            
            var devices = await _context.UserDevices
                .Where(ud => ud.UserId == userId && ud.IsActive)
                .OrderByDescending(ud => ud.LastUsed)
                .ToListAsync();
            
            return Ok(new { devices });
        }
    }
}
