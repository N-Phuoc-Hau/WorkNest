using BEWorkNest.DTOs;
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
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly NotificationService _notificationService;
        private readonly ApplicationDbContext _context;
        
        public NotificationController(NotificationService notificationService, ApplicationDbContext context)
        {
            _notificationService = notificationService;
            _context = context;
        }
        
        [HttpGet]
        public async Task<IActionResult> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
        public async Task<IActionResult> MarkAsRead(int notificationId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var success = await _notificationService.MarkNotificationAsReadAsync(notificationId, userId);
            
            if (!success)
            {
                return NotFound(new { message = "Notification not found" });
            }
            
            return Ok(new { message = "Notification marked as read" });
        }
        
        [HttpPost("mark-all-read")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            await _notificationService.MarkAllNotificationsAsReadAsync(userId);
            
            return Ok(new { message = "All notifications marked as read" });
        }
        
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var count = await _notificationService.GetUnreadNotificationCountAsync(userId);
            
            return Ok(new { unreadCount = count });
        }
        
        [HttpPost("device-token")]
        public async Task<IActionResult> RegisterDeviceToken([FromBody] DeviceTokenDto dto)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
        public async Task<IActionResult> UnregisterDeviceToken([FromBody] DeviceTokenDto dto)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
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
        public async Task<IActionResult> GetMyDevices()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var devices = await _context.UserDevices
                .Where(ud => ud.UserId == userId && ud.IsActive)
                .OrderByDescending(ud => ud.LastUsed)
                .ToListAsync();
            
            return Ok(new { devices });
        }
    }
}
