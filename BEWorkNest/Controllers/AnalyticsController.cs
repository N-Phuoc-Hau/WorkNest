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
    [AllowAnonymous]
    public class AnalyticsController : ControllerBase
    {
        private readonly AnalyticsService _analyticsService;
        private readonly ExcelExportService _excelExportService;
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;
        private readonly ILogger<AnalyticsController> _logger;

        public AnalyticsController(
            AnalyticsService analyticsService,
            ExcelExportService excelExportService,
            ApplicationDbContext context,
            JwtService jwtService,
            ILogger<AnalyticsController> logger)
        {
            _analyticsService = analyticsService;
            _excelExportService = excelExportService;
            _context = context;
            _jwtService = jwtService;
            _logger = logger;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value ?? User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;

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
                            var claimsPrincipal = _jwtService.ValidateToken(token);
                            if (claimsPrincipal != null)
                            {
                                userId = claimsPrincipal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                                userRole = claimsPrincipal.FindFirst("role")?.Value ?? 
                                          claimsPrincipal.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
                                isAuthenticated = true;
                            }
                        }
                        catch (Exception)
                        {
                            // Token validation failed
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpGet("detailed")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDetailedAnalytics([FromQuery] bool simplified = false)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                _logger.LogInformation("GetDetailedAnalytics - UserId: {UserId}, UserRole: {UserRole}, IsAuthenticated: {IsAuthenticated}, Simplified: {Simplified}", 
                    userId, userRole, isAuthenticated, simplified);

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem phân tích chi tiết.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                var analytics = simplified ? 
                    await _analyticsService.GetSimplifiedAnalyticsAsync(userId) : 
                    await _analyticsService.GetDetailedAnalyticsAsync(userId);
                    
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
        [AllowAnonymous]
        public async Task<IActionResult> GetJobPerformance(int jobId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem hiệu suất công việc.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
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
        [AllowAnonymous]
        public async Task<IActionResult> GetJobViewsChart([FromQuery] int days = 30)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem biểu đồ lượt xem.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
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
        [AllowAnonymous]
        public async Task<IActionResult> GetApplicationsChart([FromQuery] int months = 12)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem biểu đồ ứng tuyển.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
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
        [AllowAnonymous]
        public async Task<IActionResult> GetFollowersChart([FromQuery] int months = 6)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem biểu đồ người theo dõi.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
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
        [AllowAnonymous]
        public async Task<IActionResult> ExportToExcel()
        {
            try
            {
                _logger.LogInformation("ExportToExcel: Starting Excel export process");
                
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                _logger.LogInformation("ExportToExcel: UserId={UserId}, UserRole={UserRole}, IsAuthenticated={IsAuthenticated}", 
                    userId, userRole, isAuthenticated);

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    _logger.LogWarning("ExportToExcel: Authentication failed");
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    _logger.LogWarning("ExportToExcel: Insufficient permissions for user role: {UserRole}", userRole);
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xuất báo cáo Excel.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                _logger.LogInformation("ExportToExcel: Getting simplified analytics for user: {UserId}", userId);
                var analytics = await _analyticsService.GetSimplifiedAnalyticsAsync(userId);
                
                _logger.LogInformation("ExportToExcel: Analytics retrieved successfully, generating Excel file");
                var excelData = await _excelExportService.ExportDetailedAnalyticsToExcel(analytics, userId);

                if (excelData == null || excelData.Length == 0)
                {
                    _logger.LogError("ExportToExcel: Generated Excel data is null or empty");
                    return StatusCode(500, new { 
                        success = false,
                        message = "Không thể tạo file Excel",
                        error = "Generated file is empty" 
                    });
                }

                var fileName = $"Analytics_Report_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                
                // Check if it's actually a CSV file (fallback)
                if (excelData.Length > 0)
                {
                    var firstBytes = System.Text.Encoding.UTF8.GetString(excelData.Take(100).ToArray());
                    if (firstBytes.Contains("WorkNest Analytics Report"))
                    {
                        // It's our fallback CSV file
                        fileName = $"Analytics_Report_{DateTime.Now:yyyyMMdd_HHmmss}.csv";
                        contentType = "text/csv";
                    }
                }
                
                _logger.LogInformation("ExportToExcel: Excel file generated successfully. Size: {FileSize} bytes, FileName: {FileName}", 
                    excelData.Length, fileName);
                
                return File(
                    excelData,
                    contentType,
                    fileName
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ExportToExcel: Lỗi khi xuất báo cáo Excel");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi xuất báo cáo Excel",
                    error = ex.Message 
                });
            }
        }

        [HttpGet("summary")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAnalyticsSummary()
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }

                if (userRole != "recruiter")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem tóm tắt phân tích.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                // Use simplified analytics for better performance
                var analytics = await _analyticsService.GetSimplifiedAnalyticsAsync(userId);
                
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
                        // Basic job info only - no detailed chart data
                        BestJob = analytics.Jobs.BestPerformingJob != null ? new
                        {
                            analytics.Jobs.BestPerformingJob.JobId,
                            analytics.Jobs.BestPerformingJob.JobTitle,
                            analytics.Jobs.BestPerformingJob.JobCategory,
                            analytics.Jobs.BestPerformingJob.JobLocation,
                            analytics.Jobs.BestPerformingJob.ExperienceLevel,
                            analytics.Jobs.BestPerformingJob.Salary,
                            analytics.Jobs.BestPerformingJob.PostedDate,
                            analytics.Jobs.BestPerformingJob.DeadLine,
                            analytics.Jobs.BestPerformingJob.IsActive,
                            analytics.Jobs.BestPerformingJob.TotalViews,
                            analytics.Jobs.BestPerformingJob.UniqueViews,
                            analytics.Jobs.BestPerformingJob.TotalApplications,
                            analytics.Jobs.BestPerformingJob.PendingApplications,
                            analytics.Jobs.BestPerformingJob.AcceptedApplications,
                            analytics.Jobs.BestPerformingJob.RejectedApplications,
                            analytics.Jobs.BestPerformingJob.ViewToApplicationRatio,
                            analytics.Jobs.BestPerformingJob.AcceptanceRate,
                            analytics.Jobs.BestPerformingJob.FavoriteCount
                        } : null,
                        MostViewed = analytics.Jobs.MostViewedJob != null ? new
                        {
                            analytics.Jobs.MostViewedJob.JobId,
                            analytics.Jobs.MostViewedJob.JobTitle,
                            analytics.Jobs.MostViewedJob.JobCategory,
                            analytics.Jobs.MostViewedJob.JobLocation,
                            analytics.Jobs.MostViewedJob.ExperienceLevel,
                            analytics.Jobs.MostViewedJob.Salary,
                            analytics.Jobs.MostViewedJob.PostedDate,
                            analytics.Jobs.MostViewedJob.DeadLine,
                            analytics.Jobs.MostViewedJob.IsActive,
                            analytics.Jobs.MostViewedJob.TotalViews,
                            analytics.Jobs.MostViewedJob.UniqueViews,
                            analytics.Jobs.MostViewedJob.TotalApplications,
                            analytics.Jobs.MostViewedJob.PendingApplications,
                            analytics.Jobs.MostViewedJob.AcceptedApplications,
                            analytics.Jobs.MostViewedJob.RejectedApplications,
                            analytics.Jobs.MostViewedJob.ViewToApplicationRatio,
                            analytics.Jobs.MostViewedJob.AcceptanceRate,
                            analytics.Jobs.MostViewedJob.FavoriteCount
                        } : null,
                        MostApplied = analytics.Jobs.MostAppliedJob != null ? new
                        {
                            analytics.Jobs.MostAppliedJob.JobId,
                            analytics.Jobs.MostAppliedJob.JobTitle,
                            analytics.Jobs.MostAppliedJob.JobCategory,
                            analytics.Jobs.MostAppliedJob.JobLocation,
                            analytics.Jobs.MostAppliedJob.ExperienceLevel,
                            analytics.Jobs.MostAppliedJob.Salary,
                            analytics.Jobs.MostAppliedJob.PostedDate,
                            analytics.Jobs.MostAppliedJob.DeadLine,
                            analytics.Jobs.MostAppliedJob.IsActive,
                            analytics.Jobs.MostAppliedJob.TotalViews,
                            analytics.Jobs.MostAppliedJob.UniqueViews,
                            analytics.Jobs.MostAppliedJob.TotalApplications,
                            analytics.Jobs.MostAppliedJob.PendingApplications,
                            analytics.Jobs.MostAppliedJob.AcceptedApplications,
                            analytics.Jobs.MostAppliedJob.RejectedApplications,
                            analytics.Jobs.MostAppliedJob.ViewToApplicationRatio,
                            analytics.Jobs.MostAppliedJob.AcceptanceRate,
                            analytics.Jobs.MostAppliedJob.FavoriteCount
                        } : null
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
        [AllowAnonymous]
        public async Task<IActionResult> TrackEvent([FromBody] TrackEventRequest request)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
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
