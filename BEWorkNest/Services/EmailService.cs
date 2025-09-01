using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MimeKit.Text;
using BEWorkNest.Models;

namespace BEWorkNest.Services
{
    public class EmailService
    {
        private readonly IConfiguration _configuration;
        
        public EmailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        
        public async Task SendEmailAsync(string to, string subject, string body, bool isHtml = true)
        {
            var email = new MimeMessage();
            email.From.Add(MailboxAddress.Parse(_configuration["EmailSettings:From"]));
            email.To.Add(MailboxAddress.Parse(to));
            email.Subject = subject;
            email.Body = new TextPart(isHtml ? TextFormat.Html : TextFormat.Plain) { Text = body };
            
            using var smtp = new SmtpClient();
            await smtp.ConnectAsync(_configuration["EmailSettings:Host"], 
                int.Parse(_configuration["EmailSettings:Port"] ?? "587"), 
                SecureSocketOptions.StartTls);
            await smtp.AuthenticateAsync(_configuration["EmailSettings:Username"], 
                _configuration["EmailSettings:Password"]);
            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);
        }
        
        public async Task SendJobNotificationAsync(string email, string userName, JobPost job, Company company)
        {
            var subject = $"Công việc mới từ {company.Name} - {job.Title}";
            var body = $@"
                <html>
                <body>
                    <h2>Xin chào {userName},</h2>
                    <p>Có một công việc mới phù hợp với bạn:</p>
                    <div style='border: 1px solid #ddd; padding: 15px; margin: 10px 0;'>
                        <h3>{job.Title}</h3>
                        <p><strong>Công ty:</strong> {company.Name}</p>
                        <p><strong>Địa điểm:</strong> {job.Location}</p>
                        <p><strong>Mức lương:</strong> {job.Salary}</p>
                        <p><strong>Loại công việc:</strong> {job.JobType}</p>
                        <p><strong>Mô tả:</strong> {job.Description}</p>
                    </div>
                    <p>Đăng nhập vào WorkNest để ứng tuyển ngay!</p>
                    <p>Trân trọng,<br>Đội ngũ WorkNest</p>
                </body>
                </html>";
            
            await SendEmailAsync(email, subject, body);
        }
        
        public async Task SendApplicationStatusAsync(string email, string userName, string jobTitle, string companyName, string status)
        {
            var statusText = status switch
            {
                "Accepted" => "được chấp nhận",
                "Rejected" => "bị từ chối",
                "Interview" => "được mời phỏng vấn",
                _ => "được cập nhật"
            };
            
            var subject = $"Cập nhật đơn ứng tuyển - {jobTitle}";
            var body = $@"
                <html>
                <body>
                    <h2>Xin chào {userName},</h2>
                    <p>Đơn ứng tuyển của bạn cho vị trí <strong>{jobTitle}</strong> tại <strong>{companyName}</strong> đã {statusText}.</p>
                    <p>Vui lòng đăng nhập vào WorkNest để xem chi tiết.</p>
                    <p>Trân trọng,<br>Đội ngũ WorkNest</p>
                </body>
                </html>";
            
            await SendEmailAsync(email, subject, body);
        }
        
        public async Task SendFollowNotificationAsync(string email, string userName, string companyName)
        {
            var subject = $"Cảm ơn bạn đã theo dõi {companyName}";
            var body = $@"
                <html>
                <body>
                    <h2>Xin chào {userName},</h2>
                    <p>Cảm ơn bạn đã theo dõi <strong>{companyName}</strong>!</p>
                    <p>Bạn sẽ nhận được thông báo khi công ty đăng tin tuyển dụng mới.</p>
                    <p>Trân trọng,<br>Đội ngũ WorkNest</p>
                </body>
                </html>";
            
            await SendEmailAsync(email, subject, body);
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string otp, string userName = "")
        {
            try
            {
                var displayName = string.IsNullOrEmpty(userName) ? "User" : userName;
                var subject = "WorkNest - Reset Password OTP";
                var body = CreateOtpEmailTemplate(otp, displayName);
                
                await SendEmailAsync(toEmail, subject, body);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        private string CreateOtpEmailTemplate(string otp, string userName)
        {
            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>Reset Password - WorkNest</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 30px 20px;
        }}
        .header h1 {{
            margin: 0;
            font-size: 28px;
            font-weight: 300;
        }}
        .content {{
            padding: 40px 30px;
            text-align: center;
        }}
        .otp-container {{
            background-color: #f8f9fa;
            border: 2px dashed #667eea;
            border-radius: 10px;
            padding: 30px;
            margin: 30px 0;
        }}
        .otp-code {{
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
            letter-spacing: 8px;
            margin: 10px 0;
        }}
        .otp-label {{
            font-size: 14px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }}
        .warning {{
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
        }}
        .footer {{
            background-color: #f8f9fa;
            text-align: center;
            padding: 20px;
            font-size: 14px;
            color: #666;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🔐 WorkNest</h1>
            <p>Password Reset Request</p>
        </div>
        
        <div class='content'>
            <h2>Hello {userName}!</h2>
            <p>We received a request to reset your WorkNest password. Use the OTP code below to complete your password reset:</p>
            
            <div class='otp-container'>
                <div class='otp-label'>Your OTP Code</div>
                <div class='otp-code'>{otp}</div>
                <p style='margin: 10px 0 0 0; color: #666; font-size: 14px;'>Valid for 15 minutes</p>
            </div>
            
            <div class='warning'>
                <strong>⚠️ Security Notice:</strong><br>
                • This OTP will expire in 15 minutes<br>
                • Do not share this code with anyone<br>
                • If you didn't request this, please ignore this email
            </div>
            
            <p>If you're having trouble, contact our support team.</p>
        </div>
        
        <div class='footer'>
            <p>This is an automated email from WorkNest. Please do not reply to this email.</p>
            <p>&copy; 2025 WorkNest. All rights reserved.</p>
        </div>
    </div>
</body>
</html>";
        }
    }
}
