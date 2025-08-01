using BEWorkNest.Data;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Services
{
    public class NotificationService
    {
        private readonly ApplicationDbContext _context;
        private readonly FirebaseService _firebaseService;
        private readonly EmailService _emailService;
        private readonly ILogger<NotificationService> _logger;
        
        public NotificationService(
            ApplicationDbContext context,
            FirebaseService firebaseService,
            EmailService emailService,
            ILogger<NotificationService> logger)
        {
            _context = context;
            _firebaseService = firebaseService;
            _emailService = emailService;
            _logger = logger;
        }
        
        public async Task<Notification> CreateNotificationAsync(string userId, string title, string message, string type, string? relatedEntityId = null, string? actionUrl = null)
        {
            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                Type = type,
                RelatedEntityId = relatedEntityId,
                ActionUrl = actionUrl,
                CreatedAt = DateTime.UtcNow
            };
            
            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();
            
            return notification;
        }
        
        public async Task SendJobPostedNotificationAsync(JobPost job, Company company)
        {
            try
            {
                // Get followers of the recruiter (company owner)
                var followers = await _context.Follows
                    .Where(f => f.RecruiterId == job.RecruiterId)
                    .Include(f => f.Follower)
                    .ToListAsync();
                
                foreach (var follow in followers)
                {
                    // Create in-app notification
                    await CreateNotificationAsync(
                        follow.FollowerId,
                        $"Công việc mới từ {company.Name}",
                        $"Vị trí: {job.Title} - {job.Location}",
                        "job_posted",
                        job.Id.ToString(),
                        $"/jobs/{job.Id}"
                    );
                    
                    // Send email notification
                    await _emailService.SendJobNotificationAsync(
                        follow.Follower.Email ?? string.Empty,
                        follow.Follower.UserName ?? string.Empty,
                        job,
                        company
                    );
                    
                    // Send push notification
                    var userDevices = await _context.UserDevices
                        .Where(ud => ud.UserId == follow.FollowerId && ud.IsActive)
                        .ToListAsync();
                    
                    foreach (var device in userDevices)
                    {
                        await _firebaseService.SendPushNotificationAsync(
                            device.FcmToken,
                            $"Công việc mới từ {company.Name}",
                            $"{job.Title} - {job.Location}",
                            new Dictionary<string, string>
                            {
                                { "type", "job_posted" },
                                { "jobId", job.Id.ToString() },
                                { "companyId", company.Id.ToString() }
                            }
                        );
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending job posted notifications");
            }
        }
        
        public async Task SendApplicationStatusNotificationAsync(Application application, string newStatus)
        {
            try
            {
                var user = await _context.Users.FindAsync(application.ApplicantId);
                var job = await _context.JobPosts
                    .Include(j => j.Recruiter)
                    .ThenInclude(r => r.Company)
                    .FirstOrDefaultAsync(j => j.Id == application.JobId);
                
                if (user == null || job == null || job.Recruiter.Company == null) return;
                
                // Create in-app notification
                await CreateNotificationAsync(
                    user.Id,
                    "Cập nhật đơn ứng tuyển",
                    $"Đơn ứng tuyển cho vị trí {job.Title} tại {job.Recruiter.Company.Name} đã được {GetStatusText(newStatus)}",
                    "application_status",
                    application.Id.ToString(),
                    $"/applications/{application.Id}"
                );
                
                // Send email notification
                await _emailService.SendApplicationStatusAsync(
                    user.Email ?? string.Empty,
                    user.UserName ?? string.Empty,
                    job.Title,
                    job.Recruiter.Company.Name,
                    newStatus
                );
                
                // Send push notification
                var userDevices = await _context.UserDevices
                    .Where(ud => ud.UserId == user.Id && ud.IsActive)
                    .ToListAsync();
                
                foreach (var device in userDevices)
                {
                    await _firebaseService.SendPushNotificationAsync(
                        device.FcmToken,
                        "Cập nhật đơn ứng tuyển",
                        $"{job.Title} - {GetStatusText(newStatus)}",
                        new Dictionary<string, string>
                        {
                            { "type", "application_status" },
                            { "applicationId", application.Id.ToString() },
                            { "status", newStatus }
                        }
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending application status notification");
            }
        }
        
        public async Task<List<NotificationDto>> GetUserNotificationsAsync(string userId, int page = 1, int pageSize = 20)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
            
            return notifications.Select(n => new NotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                Type = n.Type,
                IsRead = n.IsRead,
                RelatedEntityId = n.RelatedEntityId,
                ActionUrl = n.ActionUrl,
                CreatedAt = n.CreatedAt
            }).ToList();
        }
        
        public async Task<bool> MarkNotificationAsReadAsync(int notificationId, string userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);
            
            if (notification == null) return false;
            
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
            
            await _context.SaveChangesAsync();
            return true;
        }
        
        public async Task<bool> MarkAllNotificationsAsReadAsync(string userId)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();
            
            foreach (var notification in notifications)
            {
                notification.IsRead = true;
                notification.UpdatedAt = DateTime.UtcNow;
            }
            
            await _context.SaveChangesAsync();
            return true;
        }
        
        public async Task<int> GetUnreadNotificationCountAsync(string userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }
        
        private string GetStatusText(string status)
        {
            return status switch
            {
                "Accepted" => "chấp nhận",
                "Rejected" => "từ chối",
                "Interview" => "mời phỏng vấn",
                _ => "cập nhật"
            };
        }
    }
}
