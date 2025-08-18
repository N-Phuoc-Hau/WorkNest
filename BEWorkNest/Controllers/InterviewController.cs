using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Services;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class InterviewController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly NotificationService _notificationService;
        private readonly JwtService _jwtService;
        private readonly ILogger<InterviewController> _logger;

        public InterviewController(
            ApplicationDbContext context,
            NotificationService notificationService,
            JwtService jwtService,
            ILogger<InterviewController> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _jwtService = jwtService;
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
                            var principal = _jwtService.ValidateToken(token);
                            if (principal != null)
                            {
                                userId = principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                                userRole = principal.FindFirst("role")?.Value;
                                isAuthenticated = true;
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error validating JWT token");
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpPost("schedule")]
        public async Task<IActionResult> ScheduleInterview([FromBody] ScheduleInterviewDto dto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Chỉ nhà tuyển dụng mới có thể lên lịch phỏng vấn",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                // Validate the application exists and belongs to recruiter
                var application = await _context.Applications
                    .Include(a => a.Applicant)
                    .Include(a => a.Job)
                    .ThenInclude(j => j.Recruiter)
                    .FirstOrDefaultAsync(a => a.Id == dto.ApplicationId);

                if (application == null)
                {
                    return NotFound(new { message = "Không tìm thấy đơn ứng tuyển" });
                }

                if (application.Job.RecruiterId != userId)
                {
                    return Forbid("Bạn không có quyền lên lịch phỏng vấn cho đơn ứng tuyển này");
                }

                // Create interview record
                var interview = new Interview
                {
                    ApplicationId = dto.ApplicationId,
                    CandidateId = application.ApplicantId,
                    RecruiterId = userId,
                    JobId = application.JobId,
                    ScheduledAt = dto.ScheduledAt,
                    Title = dto.Title ?? $"Phỏng vấn vị trí {application.Job.Title}",
                    Description = dto.Description,
                    MeetingLink = dto.MeetingLink,
                    Location = dto.Location,
                    Status = InterviewStatus.Scheduled,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Interviews.Add(interview);
                await _context.SaveChangesAsync();

                // Get recruiter name for notification
                var recruiter = await _context.Users.FindAsync(userId);
                var recruiterName = recruiter != null ? $"{recruiter.FirstName} {recruiter.LastName}".Trim() : "Nhà tuyển dụng";

                // Send notification to candidate
                await _notificationService.SendInterviewScheduleNotificationAsync(
                    candidateId: application.ApplicantId,
                    recruiterName: recruiterName,
                    jobTitle: application.Job.Title,
                    scheduledTime: dto.ScheduledAt,
                    meetingLink: dto.MeetingLink
                );

                return Ok(new
                {
                    message = "Đã lên lịch phỏng vấn thành công",
                    interviewId = interview.Id,
                    scheduledAt = interview.ScheduledAt,
                    candidateName = $"{application.Applicant.FirstName} {application.Applicant.LastName}".Trim(),
                    jobTitle = application.Job.Title
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scheduling interview");
                return StatusCode(500, new
                {
                    message = "Lỗi hệ thống khi lên lịch phỏng vấn",
                    error = ex.Message
                });
            }
        }

        [HttpGet("my-interviews")]
        public async Task<IActionResult> GetMyInterviews([FromQuery] string? status = null)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                IQueryable<Interview> query = _context.Interviews
                    .Include(i => i.Application)
                    .ThenInclude(a => a.Applicant)
                    .Include(i => i.Application)
                    .ThenInclude(a => a.Job)
                    .ThenInclude(j => j.Recruiter);

                if (userRole == "recruiter")
                {
                    query = query.Where(i => i.RecruiterId == userId);
                }
                else if (userRole == "candidate")
                {
                    query = query.Where(i => i.CandidateId == userId);
                }

                if (!string.IsNullOrEmpty(status) && Enum.TryParse<InterviewStatus>(status, out var statusEnum))
                {
                    query = query.Where(i => i.Status == statusEnum);
                }

                var interviews = await query
                    .OrderByDescending(i => i.ScheduledAt)
                    .ToListAsync();

                var result = interviews.Select(i => new
                {
                    id = i.Id,
                    title = i.Title,
                    description = i.Description,
                    scheduledAt = i.ScheduledAt,
                    meetingLink = i.MeetingLink,
                    location = i.Location,
                    status = i.Status.ToString(),
                    candidateName = $"{i.Application.Applicant.FirstName} {i.Application.Applicant.LastName}".Trim(),
                    recruiterName = $"{i.Application.Job.Recruiter.FirstName} {i.Application.Job.Recruiter.LastName}".Trim(),
                    jobTitle = i.Application.Job.Title,
                    createdAt = i.CreatedAt
                });

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting interviews");
                return StatusCode(500, new
                {
                    message = "Lỗi hệ thống khi lấy danh sách phỏng vấn",
                    error = ex.Message
                });
            }
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateInterviewStatus(int id, [FromBody] UpdateInterviewStatusDto dto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var interview = await _context.Interviews
                    .Include(i => i.Application)
                    .ThenInclude(a => a.Job)
                    .FirstOrDefaultAsync(i => i.Id == id);

                if (interview == null)
                {
                    return NotFound(new { message = "Không tìm thấy cuộc phỏng vấn" });
                }

                // Check permissions
                if (userRole == "recruiter" && interview.RecruiterId != userId)
                {
                    return Forbid("Bạn không có quyền cập nhật cuộc phỏng vấn này");
                }

                if (userRole == "candidate" && interview.CandidateId != userId)
                {
                    return Forbid("Bạn không có quyền cập nhật cuộc phỏng vấn này");
                }

                if (Enum.TryParse<InterviewStatus>(dto.Status, out var status))
                {
                    interview.Status = status;
                    interview.UpdatedAt = DateTime.UtcNow;

                    if (!string.IsNullOrEmpty(dto.Notes))
                    {
                        interview.Notes = dto.Notes;
                    }

                    await _context.SaveChangesAsync();

                    return Ok(new
                    {
                        message = "Cập nhật trạng thái phỏng vấn thành công",
                        status = interview.Status.ToString()
                    });
                }

                return BadRequest(new { message = "Trạng thái không hợp lệ" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating interview status");
                return StatusCode(500, new
                {
                    message = "Lỗi hệ thống khi cập nhật trạng thái phỏng vấn",
                    error = ex.Message
                });
            }
        }
    }
}

// DTOs
public class ScheduleInterviewDto
{
    public int ApplicationId { get; set; }
    public DateTime ScheduledAt { get; set; }
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? MeetingLink { get; set; }
    public string? Location { get; set; }
}

public class UpdateInterviewStatusDto
{
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
}
