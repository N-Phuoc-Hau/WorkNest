using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Services;
using BEWorkNest.Models;
using BEWorkNest.Data;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AnalyticsController : ControllerBase
    {
        private readonly AnalyticsService _analyticsService;
        private readonly ExcelExportService _excelExportService;
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AnalyticsController> _logger;

        public AnalyticsController(
            AnalyticsService analyticsService,
            ExcelExportService excelExportService,
            ApplicationDbContext context,
            ILogger<AnalyticsController> logger)
        {
            _analyticsService = analyticsService;
            _excelExportService = excelExportService;
            _context = context;
            _logger = logger;
        }

        [HttpGet("detailed")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetDetailedAnalytics()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                return Ok(new
                {
                    success = true,
                    message = "Lấy phân tích chi tiết thành công",
                    data = analytics
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy phân tích chi tiết");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy phân tích chi tiết",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("job-performance/{jobId}")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetJobPerformance(int jobId)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                // Verify job ownership
                var job = await _context.JobPosts
                    .FirstOrDefaultAsync(j => j.Id == jobId && j.RecruiterId == userId);
                
                if (job == null)
                {
                    return NotFound(new { message = "Không tìm thấy công việc hoặc bạn không có quyền truy cập" });
                }

                // Get detailed analytics for the recruiter and find the specific job
                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                var jobPerformance = analytics.Jobs.AllJobs.FirstOrDefault(j => j.JobId == jobId);

                if (jobPerformance == null)
                {
                    return NotFound(new { message = "Không tìm thấy dữ liệu hiệu suất cho công việc này" });
                }

                return Ok(new
                {
                    success = true,
                    message = "Lấy hiệu suất công việc thành công",
                    data = jobPerformance
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy hiệu suất công việc {JobId}", jobId);
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy hiệu suất công việc",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("charts/job-views")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetJobViewsChart([FromQuery] int days = 30)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                var chartData = analytics.Recruiter.ViewsByMonth;

                return Ok(new
                {
                    success = true,
                    message = "Lấy dữ liệu biểu đồ lượt xem thành công",
                    data = chartData
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy dữ liệu biểu đồ lượt xem");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy dữ liệu biểu đồ",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("charts/applications")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetApplicationsChart([FromQuery] int months = 12)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                var chartData = analytics.Recruiter.ApplicationsByMonth;

                return Ok(new
                {
                    success = true,
                    message = "Lấy dữ liệu biểu đồ ứng tuyển thành công",
                    data = chartData
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy dữ liệu biểu đồ ứng tuyển");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy dữ liệu biểu đồ",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("charts/followers")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetFollowersChart([FromQuery] int months = 6)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                var chartData = analytics.Company.FollowerGrowth;

                return Ok(new
                {
                    success = true,
                    message = "Lấy dữ liệu biểu đồ người theo dõi thành công",
                    data = chartData
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy dữ liệu biểu đồ người theo dõi");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy dữ liệu biểu đồ",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("export/excel")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> ExportToExcel()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                var excelData = await _excelExportService.ExportDetailedAnalyticsToExcel(analytics, userId);

                var fileName = $"Analytics_Report_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                
                return File(
                    excelData,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    fileName
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xuất báo cáo Excel");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi xuất báo cáo Excel",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("summary")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetAnalyticsSummary()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                var analytics = await _analyticsService.GetDetailedAnalyticsAsync(userId);
                
                var summary = new
                {
                    CompanyInfo = new
                    {
                        analytics.Company.CompanyName,
                        analytics.Company.CompanyLocation,
                        analytics.Company.IsVerified,
                        analytics.Company.TotalFollowers,
                        analytics.Company.AverageRating,
                        analytics.Company.TotalReviews
                    },
                    JobStats = new
                    {
                        analytics.Recruiter.TotalJobsPosted,
                        analytics.Recruiter.ActiveJobs,
                        analytics.Recruiter.InactiveJobs,
                        analytics.Recruiter.AverageViewsPerJob,
                        analytics.Recruiter.AverageApplicationsPerJob
                    },
                    ApplicationStats = new
                    {
                        analytics.Recruiter.TotalApplicationsReceived,
                        analytics.Recruiter.PendingApplications,
                        analytics.Recruiter.AcceptedApplications,
                        analytics.Recruiter.RejectedApplications,
                        analytics.Recruiter.ApplicationToViewRatio
                    },
                    Performance = new
                    {
                        BestJob = analytics.Jobs.BestPerformingJob,
                        MostViewed = analytics.Jobs.MostViewedJob,
                        MostApplied = analytics.Jobs.MostAppliedJob
                    }
                };

                return Ok(new
                {
                    success = true,
                    message = "Lấy tóm tắt phân tích thành công",
                    data = summary
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy tóm tắt phân tích");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy tóm tắt phân tích",
                    error = ex.Message 
                });
            }
        }

        [HttpPost("track-event")]
        public async Task<IActionResult> TrackEvent([FromBody] TrackEventRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "Không thể xác định người dùng" });
                }

                await _analyticsService.TrackEventAsync(
                    userId,
                    request.Type,
                    request.Action,
                    request.TargetId,
                    request.Metadata
                );

                return Ok(new
                {
                    success = true,
                    message = "Theo dõi sự kiện thành công"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi theo dõi sự kiện");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi theo dõi sự kiện",
                    error = ex.Message 
                });
            }
        }
    }

    public class TrackEventRequest
    {
        public string Type { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public string? TargetId { get; set; }
        public string? Metadata { get; set; }
    }
}
