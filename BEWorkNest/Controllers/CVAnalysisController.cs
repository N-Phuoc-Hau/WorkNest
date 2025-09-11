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
    [Route("cvanalysis")]
    [AllowAnonymous]
    public class CVAnalysisController : ControllerBase
    {
        private readonly CVAnalysisService _cvAnalysisService;
        private readonly AiService _aiService;
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;
        private readonly ILogger<CVAnalysisController> _logger;

        public CVAnalysisController(
            CVAnalysisService cvAnalysisService,
            AiService aiService,
            ApplicationDbContext context,
            JwtService jwtService,
            ILogger<CVAnalysisController> logger)
        {
            _cvAnalysisService = cvAnalysisService;
            _aiService = aiService;
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

        /// <summary>
        /// Phân tích CV từ file upload
        /// </summary>
        [HttpPost("analyze-file")]
        [AllowAnonymous]
        public async Task<IActionResult> AnalyzeCVFromFile([FromForm] IFormFile cvFile)
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể phân tích CV.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                if (cvFile == null || cvFile.Length == 0)
                {
                    return BadRequest(new { message = "Vui lòng chọn file CV" });
                }

                _logger.LogInformation("Starting CV analysis from file for user: {UserId}", userId);
                var result = await _cvAnalysisService.AnalyzeCVFromFileAsync(userId, cvFile);

                return Ok(new
                {
                    success = true,
                    message = "Phân tích CV thành công",
                    data = result
                });
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Invalid CV file for user");
                return BadRequest(new { 
                    success = false,
                    message = ex.Message 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi phân tích CV từ file");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi phân tích CV",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Phân tích CV từ text
        /// </summary>
        [HttpPost("analyze-text")]
        [AllowAnonymous]
        public async Task<IActionResult> AnalyzeCVFromText([FromBody] CVAnalysisRequest request)
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể phân tích CV.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                if (string.IsNullOrWhiteSpace(request.CVText))
                {
                    return BadRequest(new { message = "Nội dung CV không được để trống" });
                }

                _logger.LogInformation("Starting CV analysis from text for user: {UserId}", userId);
                var result = await _cvAnalysisService.AnalyzeCVTextAsync(userId, request.CVText);

                return Ok(new
                {
                    success = true,
                    message = "Phân tích CV thành công",
                    data = result
                });
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Invalid CV text for user");
                return BadRequest(new { 
                    success = false,
                    message = ex.Message 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi phân tích CV từ text");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi phân tích CV",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Lấy lịch sử phân tích CV của user
        /// </summary>
        [HttpGet("history")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAnalysisHistory([FromQuery] int pageSize = 10, [FromQuery] int pageNumber = 1)
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem lịch sử phân tích CV.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                _logger.LogInformation("Getting CV analysis history for user: {UserId}", userId);
                var history = await _cvAnalysisService.GetAnalysisHistoryAsync(userId, pageSize, pageNumber);

                return Ok(new
                {
                    success = true,
                    message = "Lấy lịch sử phân tích CV thành công",
                    data = history
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy lịch sử phân tích CV");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy lịch sử phân tích CV",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Lấy chi tiết phân tích CV theo ID
        /// </summary>
        [HttpGet("analysis/{analysisId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAnalysisDetail(string analysisId)
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem chi tiết phân tích CV.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                _logger.LogInformation("Getting CV analysis detail for user: {UserId}, analysisId: {AnalysisId}", userId, analysisId);
                var result = await _cvAnalysisService.GetAnalysisDetailAsync(userId, analysisId);

                if (result == null)
                {
                    return NotFound(new { message = "Không tìm thấy kết quả phân tích" });
                }

                return Ok(new
                {
                    success = true,
                    message = "Lấy chi tiết phân tích CV thành công",
                    data = result
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy chi tiết phân tích CV");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy chi tiết phân tích CV",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Lấy thống kê phân tích CV của user
        /// </summary>
        [HttpGet("stats")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAnalysisStats()
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem thống kê phân tích CV.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                _logger.LogInformation("Getting CV analysis stats for user: {UserId}", userId);
                var stats = await _cvAnalysisService.GetAnalysisStatsAsync(userId);

                return Ok(new
                {
                    success = true,
                    message = "Lấy thống kê phân tích CV thành công",
                    data = stats
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thống kê phân tích CV");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy thống kê phân tích CV",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Lấy gợi ý việc làm dựa trên CV
        /// </summary>
        [HttpGet("job-recommendations")]
        [AllowAnonymous]
        public async Task<IActionResult> GetJobRecommendations([FromQuery] string? cvText, [FromQuery] int maxRecommendations = 10)
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

                if (userRole != "candidate")
                {
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem gợi ý việc làm.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                _logger.LogInformation("Getting job recommendations for user: {UserId}", userId);
                List<JobRecommendationAnalytics> recommendations = new List<JobRecommendationAnalytics>();

                if (!string.IsNullOrEmpty(cvText))
                {
                    // Use AI service with real database data for CV text analysis
                    var aiRecommendations = await _aiService.GetJobRecommendationsFromDatabaseAsync(cvText, userId);
                    recommendations = ConvertToJobRecommendationAnalytics(aiRecommendations);
                }
                else
                {
                    // Get recommendations based on user's latest CV analysis or filtered recommendations
                    try
                    {
                        var filteredRecommendations = await _aiService.GetFilteredJobRecommendationsAsync(
                            "", // Empty CV text for general recommendations
                            userId,
                            null, // No location filter  
                            null, // No category filter
                            null, // No experience filter
                            null, // No salary filter
                            maxRecommendations
                        );
                        recommendations = ConvertToJobRecommendationAnalytics(filteredRecommendations);
                    }
                    catch
                    {
                        // Fallback: If no previous CV analysis, get general recommendations
                        var aiRecommendations = await _aiService.GetJobRecommendationsFromDatabaseAsync("", userId);
                        recommendations = ConvertToJobRecommendationAnalytics(aiRecommendations.Take(maxRecommendations).ToList());
                    }
                }

                return Ok(new
                {
                    success = true,
                    message = "Lấy gợi ý việc làm thành công",
                    data = recommendations
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy gợi ý việc làm");
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi lấy gợi ý việc làm",
                    error = ex.Message 
                });
            }
        }

        /// <summary>
        /// Phân tích CV với job cụ thể (cho recruiter)
        /// </summary>
        [HttpPost("analyze-for-job/{jobId}")]
        [AllowAnonymous]
        public async Task<IActionResult> AnalyzeCVForJob(int jobId, [FromBody] CVAnalysisRequest request)
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
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể phân tích CV cho công việc.",
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

                if (string.IsNullOrWhiteSpace(request.CVText))
                {
                    return BadRequest(new { message = "Nội dung CV không được để trống" });
                }

                _logger.LogInformation("Analyzing CV for job {JobId} by recruiter {UserId}", jobId, userId);

                // Create job details for AI analysis
                var jobDetails = new Dictionary<string, object>
                {
                    ["id"] = job.Id,
                    ["title"] = job.Title,
                    ["company"] = job.Recruiter?.Company?.Name ?? "Unknown",
                    ["location"] = job.Location,
                    ["salary"] = job.Salary.ToString(),
                    ["jobType"] = job.JobType,
                    ["experienceLevel"] = job.ExperienceLevel,
                    ["description"] = job.Description,
                    ["requirements"] = job.Requirements
                };

                // Use AI service to analyze CV against specific job
                var analysisResult = await _aiService.AnalyzeCVForJobAsync(request.CVText, jobDetails);

                return Ok(new
                {
                    success = true,
                    message = "Phân tích CV cho công việc thành công",
                    data = new
                    {
                        jobInfo = new
                        {
                            jobId = job.Id,
                            jobTitle = job.Title,
                            company = job.Recruiter?.Company?.Name ?? "Unknown",
                            location = job.Location
                        },
                        analysis = analysisResult
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi phân tích CV cho công việc {JobId}", jobId);
                return StatusCode(500, new { 
                    success = false,
                    message = "Lỗi hệ thống khi phân tích CV cho công việc",
                    error = ex.Message 
                });
            }
        }

        // Helper method to convert JobRecommendationWithScore to JobRecommendationAnalytics
        private List<JobRecommendationAnalytics> ConvertToJobRecommendationAnalytics(List<JobRecommendationWithScore> aiRecommendations)
        {
            return aiRecommendations.Select(rec => new JobRecommendationAnalytics
            {
                JobId = rec.JobId,
                JobTitle = rec.Title,
                CompanyName = rec.Company,
                Location = rec.Location,
                SalaryRange = rec.SalaryRange,
                JobType = rec.JobType,
                ExperienceLevel = rec.ExperienceLevel,
                MatchScore = rec.MatchPercentage,
                MatchedSkills = rec.SkillsRequired,
                MissingSkills = new List<string>(),
                MatchReasons = !string.IsNullOrEmpty(rec.Reason) ? new List<string> { rec.Reason } : new List<string>(),
                RecommendationLevel = GetRecommendationLevel(rec.MatchPercentage),
                SalaryFitScore = GetSalaryFitScore(rec.SalaryRange),
                LocationFitScore = 1.0,
                SkillFitScore = rec.MatchPercentage / 100.0,
                ExperienceFitScore = GetExperienceFitScore(rec.ExperienceLevel),
                PostedDate = rec.PostedDate,
                ApplicationDeadline = rec.DeadLine,
                IsActive = rec.DeadLine > DateTime.Now
            }).ToList();
        }

        private string GetRecommendationLevel(int matchPercentage)
        {
            return matchPercentage switch
            {
                >= 80 => "Highly Recommended",
                >= 60 => "Good Match", 
                _ => "Potential Match"
            };
        }

        private double GetSalaryFitScore(string salaryRange)
        {
            // Simple scoring based on salary range availability
            return string.IsNullOrEmpty(salaryRange) ? 0.5 : 0.8;
        }

        private double GetExperienceFitScore(string experienceLevel)
        {
            // Simple scoring based on experience level match
            return experienceLevel.ToLower() switch
            {
                var exp when exp.Contains("intern") => 0.6,
                var exp when exp.Contains("junior") || exp.Contains("entry") => 0.7,
                var exp when exp.Contains("mid") || exp.Contains("senior") => 0.8,
                var exp when exp.Contains("lead") || exp.Contains("manager") => 0.9,
                _ => 0.7
            };
        }
    }
}
