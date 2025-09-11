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
                var subject = "🎯 Thông báo lịch phỏng vấn - WorkNest";
                var vietnamTime = scheduledTime.AddHours(7); // Convert to Vietnam timezone
                var dayOfWeek = vietnamTime.ToString("dddd", new System.Globalization.CultureInfo("vi-VN"));
                
                var body = $@"
<!DOCTYPE html>
<html lang=""vi"">
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Thông báo lịch phỏng vấn</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f8fafc;
            padding: 20px;
        }}
        
        .email-container {{
            max-width: 600px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }}
        
        .header {{
            background: linear-gradient(135deg, #6C63FF 0%, #4FACFE 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }}
        
        .header h1 {{
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }}
        
        .header p {{
            font-size: 16px;
            opacity: 0.9;
            font-weight: 400;
        }}
        
        .content {{
            padding: 40px 30px;
        }}
        
        .greeting {{
            font-size: 18px;
            color: #2d3748;
            margin-bottom: 20px;
            font-weight: 500;
        }}
        
        .interview-card {{
            background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            padding: 25px;
            margin: 25px 0;
            position: relative;
            overflow: hidden;
        }}
        
        .interview-card::before {{
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 4px;
            height: 100%;
            background: linear-gradient(135deg, #6C63FF 0%, #4FACFE 100%);
        }}
        
        .interview-title {{
            font-size: 20px;
            font-weight: 600;
            color: #2d3748;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
        }}
        
        .interview-title::before {{
            content: '🎯';
            margin-right: 10px;
            font-size: 24px;
        }}
        
        .interview-details {{
            display: grid;
            gap: 15px;
        }}
        
        .detail-item {{
            display: flex;
            align-items: flex-start;
            padding: 12px 0;
            border-bottom: 1px solid #e2e8f0;
        }}
        
        .detail-item:last-child {{
            border-bottom: none;
        }}
        
        .detail-icon {{
            width: 20px;
            height: 20px;
            margin-right: 15px;
            margin-top: 2px;
            flex-shrink: 0;
        }}
        
        .detail-label {{
            font-weight: 600;
            color: #4a5568;
            min-width: 120px;
            margin-right: 10px;
        }}
        
        .detail-value {{
            color: #2d3748;
            font-weight: 500;
            flex: 1;
        }}
        
        .time-highlight {{
            background: linear-gradient(135deg, #6C63FF 0%, #4FACFE 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            text-align: center;
            margin: 20px 0;
            font-weight: 600;
            font-size: 16px;
        }}
        
        .meeting-link {{
            background: #48bb78;
            color: white;
            padding: 15px 25px;
            border-radius: 8px;
            text-decoration: none;
            display: inline-block;
            font-weight: 600;
            text-align: center;
            margin: 20px 0;
            transition: all 0.3s ease;
            box-shadow: 0 4px 12px rgba(72, 187, 120, 0.3);
        }}
        
        .meeting-link:hover {{
            background: #38a169;
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(72, 187, 120, 0.4);
        }}
        
        .tips-section {{
            background: #fef5e7;
            border: 1px solid #f6e05e;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
        }}
        
        .tips-title {{
            font-weight: 600;
            color: #744210;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
        }}
        
        .tips-title::before {{
            content: '💡';
            margin-right: 8px;
        }}
        
        .tips-list {{
            list-style: none;
            padding: 0;
        }}
        
        .tips-list li {{
            color: #744210;
            margin-bottom: 8px;
            padding-left: 20px;
            position: relative;
        }}
        
        .tips-list li::before {{
            content: '✓';
            position: absolute;
            left: 0;
            color: #38a169;
            font-weight: bold;
        }}
        
        .footer {{
            background: #2d3748;
            color: #a0aec0;
            padding: 30px;
            text-align: center;
        }}
        
        .footer-logo {{
            font-size: 24px;
            font-weight: 700;
            color: #6C63FF;
            margin-bottom: 10px;
        }}
        
        .footer p {{
            font-size: 14px;
            margin-bottom: 5px;
        }}
        
        .social-links {{
            margin-top: 20px;
        }}
        
        .social-links a {{
            color: #6C63FF;
            text-decoration: none;
            margin: 0 10px;
            font-weight: 500;
        }}
        
        @media (max-width: 600px) {{
            .email-container {{
                margin: 10px;
                border-radius: 12px;
            }}
            
            .header, .content, .footer {{
                padding: 25px 20px;
            }}
            
            .interview-card {{
                padding: 20px;
            }}
            
            .detail-item {{
                flex-direction: column;
                align-items: flex-start;
            }}
            
            .detail-label {{
                margin-bottom: 5px;
                min-width: auto;
            }}
        }}
    </style>
</head>
<body>
    <div class=""email-container"">
        <div class=""header"">
            <h1>🎯 Lịch Phỏng Vấn Mới</h1>
            <p>Cơ hội nghề nghiệp đang chờ đón bạn</p>
        </div>
        
        <div class=""content"">
            <div class=""greeting"">
                Xin chào <strong>{candidateName}</strong>,
            </div>
            
            <p style=""color: #4a5568; margin-bottom: 25px; font-size: 16px;"">
                Chúc mừng! Bạn đã được mời tham gia phỏng vấn. Dưới đây là thông tin chi tiết về cuộc phỏng vấn của bạn:
            </p>
            
            <div class=""interview-card"">
                <div class=""interview-title"">
                    Thông tin phỏng vấn
                </div>
                
                <div class=""interview-details"">
                    <div class=""detail-item"">
                        <div class=""detail-icon"">💼</div>
                        <div class=""detail-label"">Vị trí:</div>
                        <div class=""detail-value"">{jobTitle}</div>
                    </div>
                    
                    <div class=""detail-item"">
                        <div class=""detail-icon"">👤</div>
                        <div class=""detail-label"">Người phỏng vấn:</div>
                        <div class=""detail-value"">{recruiterName}</div>
                    </div>
                    
                    <div class=""detail-item"">
                        <div class=""detail-icon"">📅</div>
                        <div class=""detail-label"">Ngày:</div>
                        <div class=""detail-value"">{dayOfWeek}, {vietnamTime:dd/MM/yyyy}</div>
                    </div>
                    
                    <div class=""detail-item"">
                        <div class=""detail-icon"">⏰</div>
                        <div class=""detail-label"">Thời gian:</div>
                        <div class=""detail-value"">{vietnamTime:HH:mm} (Giờ Việt Nam)</div>
                    </div>
                </div>
                
                <div class=""time-highlight"">
                    📅 {dayOfWeek}, {vietnamTime:dd/MM/yyyy} lúc {vietnamTime:HH:mm}
                </div>
                
                {(!string.IsNullOrEmpty(meetingLink) ? $@"
                <div style=""text-align: center; margin-top: 20px;"">
                    <a href=""{meetingLink}"" class=""meeting-link"">
                        🎥 Tham gia cuộc họp
                    </a>
                    <p style=""font-size: 14px; color: #6b7280; margin-top: 10px;"">
                        Nhấn vào nút trên để tham gia phỏng vấn online
                    </p>
                </div>" : @"
                <div style=""background: #fef2f2; border: 1px solid #fca5a5; border-radius: 8px; padding: 15px; margin-top: 20px; text-align: center;"">
                    <p style=""color: #dc2626; font-weight: 500;"">
                        📍 Địa điểm phỏng vấn sẽ được thông báo riêng
                    </p>
                </div>")}
            </div>
            
            <div class=""tips-section"">
                <div class=""tips-title"">Lời khuyên cho buổi phỏng vấn</div>
                <ul class=""tips-list"">
                    <li>Tham gia đúng giờ hoặc sớm hơn 5-10 phút</li>
                    <li>Chuẩn bị sẵn CV và các tài liệu liên quan</li>
                    <li>Tìm hiểu về công ty và vị trí ứng tuyển</li>
                    <li>Chuẩn bị câu trả lời cho các câu hỏi phổ biến</li>
                    <li>Mặc trang phục chuyên nghiệp và phù hợp</li>
                    <li>Kiểm tra kết nối mạng nếu phỏng vấn online</li>
                </ul>
            </div>
            
            <div style=""background: #e6fffa; border: 1px solid #81e6d9; border-radius: 8px; padding: 20px; margin: 25px 0; text-align: center;"">
                <p style=""color: #234e52; font-weight: 500; margin-bottom: 10px;"">
                    🌟 Chúng tôi tin tưởng vào khả năng của bạn!
                </p>
                <p style=""color: #2c7a7b; font-size: 14px;"">
                    Hãy tự tin thể hiện bản thân và chúc bạn thành công!
                </p>
            </div>
            
            <p style=""color: #4a5568; font-size: 16px; margin-top: 30px;"">
                Nếu bạn có bất kỳ câu hỏi nào, vui lòng liên hệ với chúng tôi qua email này hoặc truy cập trang web WorkNest.
            </p>
            
            <p style=""color: #2d3748; font-weight: 600; margin-top: 20px;"">
                Chúc bạn may mắn và thành công! 🍀
            </p>
        </div>
        
        <div class=""footer"">
            <div class=""footer-logo"">WorkNest</div>
            <p>Nền tảng tuyển dụng hàng đầu Việt Nam</p>
            <p>Kết nối nhà tuyển dụng và ứng viên chất lượng</p>
            
            <div class=""social-links"">
                <a href=""#"">Về chúng tôi</a> |
                <a href=""#"">Hỗ trợ</a> |
                <a href=""#"">Điều khoản</a>
            </div>
            
            <p style=""margin-top: 20px; font-size: 12px; opacity: 0.8;"">
                © 2024 WorkNest. Tất cả quyền được bảo lưu.
            </p>
        </div>
    </div>
</body>
</html>";

                await _emailService.SendEmailAsync(email, subject, body);
                _logger.LogInformation($"Professional interview schedule email sent to {email}");
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
