using BEWorkNest.Data;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using BEWorkNest.Hubs;

namespace BEWorkNest.Services
{
    public class NotificationService
    {
        private readonly ApplicationDbContext _context;
        private readonly FirebaseService _firebaseService;
        private readonly EmailService _emailService;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationService> _logger;
        
        public NotificationService(
            ApplicationDbContext context,
            FirebaseService firebaseService,
            EmailService emailService,
            IHubContext<NotificationHub> hubContext,
            ILogger<NotificationService> logger)
        {
            _context = context;
            _firebaseService = firebaseService;
            _emailService = emailService;
            _hubContext = hubContext;
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
            
            // Send real-time notification via SignalR
            await SendRealTimeNotification(userId, notification);
            
            return notification;
        }

        // Send real-time notification via SignalR
        private async Task SendRealTimeNotification(string userId, Notification notification)
        {
            try
            {
                await _hubContext.Clients.Group($"user_{userId}").SendAsync("ReceiveNotification", new
                {
                    id = notification.Id,
                    title = notification.Title,
                    message = notification.Message,
                    type = notification.Type,
                    relatedEntityId = notification.RelatedEntityId,
                    actionUrl = notification.ActionUrl,
                    createdAt = notification.CreatedAt,
                    isRead = notification.IsRead
                });
                
                _logger.LogInformation($"Real-time notification sent to user {userId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send real-time notification to user {userId}");
            }
        }

        // 1. Chat Notification
        public async Task SendChatNotificationAsync(string fromUserId, string toUserId, string fromUserName, string roomId, string message)
        {
            try
            {
                var title = $"Tin nhắn mới từ {fromUserName}";
                var notificationMessage = message.Length > 50 ? message.Substring(0, 50) + "..." : message;
                
                var notification = await CreateNotificationAsync(
                    toUserId, 
                    title, 
                    notificationMessage, 
                    "chat", 
                    roomId, 
                    $"/chat/{roomId}"
                );

                // Send real-time notification to specific chat room
                await _hubContext.Clients.Group($"chat_{roomId}").SendAsync("ReceiveChatNotification", new
                {
                    fromUserId,
                    fromUserName,
                    message = notificationMessage,
                    roomId,
                    timestamp = DateTime.UtcNow
                });

                _logger.LogInformation($"Chat notification sent from {fromUserId} to {toUserId} in room {roomId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send chat notification from {fromUserId} to {toUserId}");
            }
        }

        // 2. Job Posted Notification
        public async Task SendJobPostedNotificationAsync(JobPost job, User recruiter)
        {
            try
            {
                // Get followers of the recruiter
                var followers = await _context.Follows
                    .Where(f => f.RecruiterId == recruiter.Id && f.IsActive)
                    .Include(f => f.Follower)
                    .ToListAsync();

                var companyName = recruiter.Company?.Name ?? "Công ty";
                var title = $"Việc làm mới từ {companyName}";
                var message = $"Vị trí: {job.Title} - {job.Location}";

                foreach (var follow in followers)
                {
                    await CreateNotificationAsync(
                        follow.FollowerId,
                        title,
                        message,
                        "job_posted",
                        job.Id.ToString(),
                        $"/job-detail/{job.Id}"
                    );
                }

                // Send to recruiter followers group
                await _hubContext.Clients.Group($"recruiter_{recruiter.Id}_followers").SendAsync("ReceiveJobNotification", new
                {
                    jobId = job.Id,
                    jobTitle = job.Title,
                    companyName = companyName,
                    location = job.Location,
                    createdAt = job.CreatedAt
                });

                // Send email notification to the recruiter about successful job posting
                var recruiterEmailSubject = "Đăng bài tuyển dụng thành công";
                var recruiterEmailBody = $@"
                    <h2>Chào {recruiter.FirstName} {recruiter.LastName},</h2>
                    <p>Bài đăng tuyển dụng của bạn đã được đăng thành công!</p>
                    <h3>Thông tin bài đăng:</h3>
                    <ul>
                        <li><strong>Vị trí:</strong> {job.Title}</li>
                        <li><strong>Công ty:</strong> {companyName}</li>
                        <li><strong>Địa điểm:</strong> {job.Location}</li>
                        <li><strong>Mức lương:</strong> {job.Salary}</li>
                        <li><strong>Thời gian đăng:</strong> {job.CreatedAt:dd/MM/yyyy HH:mm}</li>
                    </ul>
                    <p>Bài đăng đã được gửi thông báo tới <strong>{followers.Count}</strong> người theo dõi của bạn.</p>
                    <p>Chúc bạn tìm được ứng viên phù hợp!</p>
                    <br>
                    <p>Trân trọng,<br>Đội ngũ WorkNest</p>
                ";

                await _emailService.SendEmailAsync(recruiter.Email ?? "", recruiterEmailSubject, recruiterEmailBody);

                _logger.LogInformation($"Job posted notification sent to {followers.Count} followers of recruiter {recruiter.UserName}. Email confirmation sent to recruiter.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send job posted notification for job {job.Id}");
            }
        }

        // 3. Interview Schedule Notification
        public async Task SendInterviewScheduleNotificationAsync(string candidateId, string recruiterName, string jobTitle, DateTime scheduledTime, string? meetingLink = null)
        {
            try
            {
                var title = "Lịch hẹn phỏng vấn mới";
                var message = $"Bạn có lịch phỏng vấn cho vị trí {jobTitle} với {recruiterName} vào {scheduledTime:dd/MM/yyyy HH:mm}";

                var notification = await CreateNotificationAsync(
                    candidateId,
                    title,
                    message,
                    "interview_schedule",
                    null,
                    meetingLink
                );

                // Send email notification
                var candidate = await _context.Users.FindAsync(candidateId);
                if (candidate != null && !string.IsNullOrEmpty(candidate.Email))
                {
                    var candidateName = $"{candidate.FirstName} {candidate.LastName}".Trim();
                    await SendInterviewScheduleEmail(candidate.Email, candidateName, 
                        jobTitle, recruiterName, scheduledTime, meetingLink);
                }

                _logger.LogInformation($"Interview schedule notification sent to candidate {candidateId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send interview schedule notification to candidate {candidateId}");
            }
        }

        // Send interview schedule email
        private async Task SendInterviewScheduleEmail(string email, string candidateName, string jobTitle, string recruiterName, DateTime scheduledTime, string? meetingLink)
        {
            try
            {
                var subject = "Thông báo lịch phỏng vấn - WorkNest";
                var body = $@"
                    <h2>Xin chào {candidateName},</h2>
                    <p>Bạn có lịch phỏng vấn mới:</p>
                    <ul>
                        <li><strong>Vị trí:</strong> {jobTitle}</li>
                        <li><strong>Người phỏng vấn:</strong> {recruiterName}</li>
                        <li><strong>Thời gian:</strong> {scheduledTime:dd/MM/yyyy} lúc {scheduledTime:HH:mm}</li>
                        {(!string.IsNullOrEmpty(meetingLink) ? $"<li><strong>Link tham gia:</strong> <a href='{meetingLink}'>{meetingLink}</a></li>" : "")}
                    </ul>
                    <p>Vui lòng chuẩn bị đầy đủ và tham gia đúng giờ.</p>
                    <p>Chúc bạn may mắn!</p>
                    <p>Đội ngũ WorkNest</p>
                ";

                await _emailService.SendEmailAsync(email, subject, body);
                _logger.LogInformation($"Interview schedule email sent to {email}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send interview schedule email to {email}");
            }
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
