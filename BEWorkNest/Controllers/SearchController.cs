using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Services;
using BEWorkNest.Data;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class SearchController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly AiService _aiService;
        private readonly ILogger<SearchController> _logger;
        private readonly UserBehaviorService _userBehaviorService;
        private readonly JwtService _jwtService;

        public SearchController(
            ApplicationDbContext context,
            AiService aiService,
            ILogger<SearchController> logger,
            UserBehaviorService userBehaviorService,
            JwtService jwtService)
        {
            _context = context;
            _aiService = aiService;
            _logger = logger;
            _userBehaviorService = userBehaviorService;
            _jwtService = jwtService;
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
                            userId = _jwtService.GetUserIdFromToken(token);
                            userRole = _jwtService.GetRoleFromToken(token);
                            isAuthenticated = !string.IsNullOrEmpty(userId);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to extract user info from JWT token");
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpGet("suggestions")]
        public async Task<IActionResult> GetSearchSuggestions([FromQuery] string query, [FromQuery] string userRole = "candidate")
        {
            try
            {
                if (string.IsNullOrWhiteSpace(query))
                {
                    return BadRequest(new { message = "Query is required" });
                }

                var suggestions = await _aiService.GetSearchSuggestionsAsync(query, userRole);

                return Ok(new { suggestions });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search suggestions");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("filters")]
        public async Task<IActionResult> GetSearchFilters([FromQuery] string query, [FromQuery] string userRole = "candidate")
        {
            try
            {
                if (string.IsNullOrWhiteSpace(query))
                {
                    return BadRequest(new { message = "Query is required" });
                }

                var filters = await _aiService.GetSearchFiltersAsync(query, userRole);

                return Ok(new { filters });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search filters");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("jobs")]
        public async Task<IActionResult> SearchJobs([FromQuery] SearchJobDto searchDto)
        {
            try
            {
                var query = _context.JobPosts
                    .Include(j => j.Recruiter)
                    .ThenInclude(r => r.Company)
                    .AsQueryable();

                // Apply filters
                if (!string.IsNullOrWhiteSpace(searchDto.Keyword))
                {
                    query = query.Where(j =>
                        j.Title.Contains(searchDto.Keyword) ||
                        j.Description.Contains(searchDto.Keyword) ||
                        j.Requirements.Contains(searchDto.Keyword));
                }

                if (!string.IsNullOrWhiteSpace(searchDto.Location))
                {
                    query = query.Where(j => j.Location.Contains(searchDto.Location));
                }

                if (!string.IsNullOrWhiteSpace(searchDto.JobType))
                {
                    query = query.Where(j => j.JobType == searchDto.JobType);
                }

                if (searchDto.MinSalary.HasValue)
                {
                    query = query.Where(j => j.Salary >= searchDto.MinSalary.Value);
                }

                if (searchDto.MaxSalary.HasValue)
                {
                    query = query.Where(j => j.Salary <= searchDto.MaxSalary.Value);
                }

                if (!string.IsNullOrWhiteSpace(searchDto.ExperienceLevel))
                {
                    query = query.Where(j => j.ExperienceLevel == searchDto.ExperienceLevel);
                }

                // Apply sorting
                query = searchDto.SortBy?.ToLower() switch
                {
                    "salary" => searchDto.SortOrder == "desc" ? query.OrderByDescending(j => j.Salary) : query.OrderBy(j => j.Salary),
                    "date" => searchDto.SortOrder == "desc" ? query.OrderByDescending(j => j.CreatedAt) : query.OrderBy(j => j.CreatedAt),
                    _ => query.OrderByDescending(j => j.CreatedAt)
                };

                // Apply pagination
                var totalCount = await query.CountAsync();
                var jobs = await query
                    .Skip((searchDto.Page - 1) * searchDto.PageSize)
                    .Take(searchDto.PageSize)
                    .Select(j => new JobPostDto
                    {
                        Id = j.Id,
                        Title = j.Title,
                        Description = j.Description,
                        Requirements = j.Requirements,
                        Location = j.Location,
                        Salary = j.Salary,
                        JobType = j.JobType,
                        ExperienceLevel = j.ExperienceLevel,
                        CreatedAt = j.CreatedAt,
                        Recruiter = new UserDto
                        {
                            Id = j.Recruiter.Id,
                            FirstName = j.Recruiter.FirstName,
                            LastName = j.Recruiter.LastName,
                            Email = j.Recruiter.Email ?? "",
                            Role = j.Recruiter.Role,
                            Company = j.Recruiter.Company != null ? new CompanyDto
                            {
                                Id = j.Recruiter.Company.Id,
                                Name = j.Recruiter.Company.Name,
                                Location = j.Recruiter.Company.Location ?? "",
                            } : null
                        }
                    })
                    .ToListAsync();

                // Track search behavior if user is authenticated
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();
                if (isAuthenticated && !string.IsNullOrEmpty(userId) && !string.IsNullOrWhiteSpace(searchDto.Keyword))
                {
                    var filters = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        location = searchDto.Location,
                        jobType = searchDto.JobType,
                        minSalary = searchDto.MinSalary,
                        maxSalary = searchDto.MaxSalary,
                        experienceLevel = searchDto.ExperienceLevel
                    });

                    _ = Task.Run(() => _userBehaviorService.TrackSearchAsync(userId, searchDto.Keyword, filters));
                }

                return Ok(new
                {
                    jobs,
                    totalCount,
                    page = searchDto.Page,
                    pageSize = searchDto.PageSize,
                    totalPages = (int)Math.Ceiling((double)totalCount / searchDto.PageSize)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching jobs");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("job-recommendations")]
        [AllowAnonymous]
        public async Task<IActionResult> GetJobRecommendations()
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }


                var user = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                // Get user profile for AI
                var userProfile = await _userBehaviorService.GetUserProfileForAIAsync(userId);

                // Get user behavior history for personalized recommendations
                var searchHistory = await _userBehaviorService.GetUserSearchHistoryAsync(userId, 50);
                var applicationHistory = await _userBehaviorService.GetUserApplicationHistoryAsync(userId, 30);

                // Get personalized recommendations from AI
                var recommendations = await _aiService.GetPersonalizedJobRecommendationsAsync(
                    userId, userProfile, searchHistory, applicationHistory);

                // Log recommendations for future improvement
                foreach (var recommendation in recommendations)
                {
                    _ = Task.Run(() => LogJobRecommendationAsync(userId, recommendation));
                }

                return Ok(new { recommendations });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting job recommendations");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("candidate-recommendations/{jobId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCandidateRecommendations(string jobId)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has recruiter role
            if (userRole != "recruiter")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem gợi ý ứng viên.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
                });
            }

            try
            {
                if (!int.TryParse(jobId, out int jobIdInt))
                {
                    return BadRequest(new { message = "Invalid job ID" });
                }

                var job = await _context.JobPosts
                    .Include(j => j.Recruiter)
                    .ThenInclude(r => r.Company)
                    .FirstOrDefaultAsync(j => j.Id == jobIdInt);

                if (job == null)
                {
                    return NotFound(new { message = "Job not found" });
                }

                // Get candidate profiles for matching
                var candidateProfiles = await _userBehaviorService.GetCandidateProfilesForMatchingAsync(100);

                // Build job details for AI
                var jobDetails = new Dictionary<string, object>
                {
                    ["id"] = job.Id,
                    ["title"] = job.Title,
                    ["description"] = job.Description,
                    ["requirements"] = job.Requirements,
                    ["location"] = job.Location,
                    ["salary"] = job.Salary,
                    ["jobType"] = job.JobType,
                    ["experienceLevel"] = job.ExperienceLevel,
                    ["company"] = job.Recruiter.Company?.Name ?? "",
                    ["recruiter"] = $"{job.Recruiter.FirstName} {job.Recruiter.LastName}"
                };

                // Get candidate matches from AI
                var candidateMatches = await _aiService.GetCandidateMatchesForJobAsync(jobDetails, candidateProfiles);

                return Ok(new { recommendations = candidateMatches });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate recommendations");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("search-history")]
        [AllowAnonymous]
        public async Task<IActionResult> GetSearchHistory()
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }


                var searchHistory = await _userBehaviorService.GetUserSearchHistoryAsync(userId, 100);

                return Ok(new { searchHistory });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search history");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpPost("save-search")]
        [AllowAnonymous]
        public async Task<IActionResult> SaveSearch([FromBody] SaveSearchDto saveSearchDto)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "AUTHENTICATION_REQUIRED"
                    });
                }


                // Save search as favorite with additional tracking
                var filters = System.Text.Json.JsonSerializer.Serialize(saveSearchDto.SearchCriteria);
                await _userBehaviorService.TrackSearchAsync(userId, saveSearchDto.SearchCriteria.Keyword ?? "", filters);

                return Ok(new { message = "Search saved successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving search");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        // Helper method to log job recommendations for analytics
        private async Task LogJobRecommendationAsync(string userId, JobRecommendation recommendation)
        {
            try
            {
                // Find the job in database (if it exists)
                var job = await _context.JobPosts
                    .FirstOrDefaultAsync(j => j.Title == recommendation.Title &&
                                              j.Location == recommendation.Location);

                if (job != null)
                {
                    var recommendationLog = new JobRecommendationLog
                    {
                        UserId = userId,
                        JobId = job.Id,
                        RecommendationScore = recommendation.MatchPercentage,
                        RecommendationReason = recommendation.Reason,
                        RecommendedAt = DateTime.UtcNow
                    };

                    _context.JobRecommendationLogs.Add(recommendationLog);
                    await _context.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging job recommendation for user {UserId}", userId);
            }
        }
    }

    public class SearchJobDto
    {
        public string? Keyword { get; set; }
        public string? Location { get; set; }
        public string? JobType { get; set; }
        public decimal? MinSalary { get; set; }
        public decimal? MaxSalary { get; set; }
        public string? ExperienceLevel { get; set; }
        public string? SortBy { get; set; } = "date";
        public string? SortOrder { get; set; } = "desc";
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    public class SaveSearchDto
    {
        public string Name { get; set; } = string.Empty;
        public SearchJobDto SearchCriteria { get; set; } = new SearchJobDto();
    }
}
