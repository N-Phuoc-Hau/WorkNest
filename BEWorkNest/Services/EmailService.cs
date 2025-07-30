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
    }
}
