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

        public SearchController(
            ApplicationDbContext context,
            AiService aiService,
            ILogger<SearchController> logger)
        {
            _context = context;
            _aiService = aiService;
            _logger = logger;
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
                            Email = j.Recruiter.Email,
                            Role = j.Recruiter.Role,
                            Company = j.Recruiter.Company != null ? new CompanyDto
                            {
                                Id = j.Recruiter.Company.Id,
                                Name = j.Recruiter.Company.Name,
                                Location = j.Recruiter.Company.Location,
                            } : null
                        }
                    })
                    .ToListAsync();

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
        [Authorize]
        public async Task<IActionResult> GetJobRecommendations()
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var user = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                {
                    return NotFound(new { message = "User not found" });
                }

                // Build user profile for AI
                var userProfile = new Dictionary<string, object>
                {
                    ["id"] = user.Id,
                    ["firstName"] = user.FirstName,
                    ["lastName"] = user.LastName,
                    ["role"] = user.Role,
                    ["company"] = user.Company?.Name ?? "",
                    ["location"] = user.Company?.Location ?? ""
                };

                var recommendations = await _aiService.GetJobRecommendationsAsync(userId, user.Role, userProfile);
                
                return Ok(new { recommendations });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting job recommendations");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("candidate-recommendations/{jobId}")]
        [Authorize]
        public async Task<IActionResult> GetCandidateRecommendations(string jobId)
        {
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

                var recommendations = await _aiService.GetCandidateRecommendationsAsync(jobId, jobDetails);
                
                return Ok(new { recommendations });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate recommendations");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("search-history")]
        [Authorize]
        public async Task<IActionResult> GetSearchHistory()
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                // TODO: Implement search history tracking
                // For now, return empty list
                return Ok(new { searchHistory = new List<object>() });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search history");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpPost("save-search")]
        [Authorize]
        public async Task<IActionResult> SaveSearch([FromBody] SaveSearchDto saveSearchDto)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                // TODO: Implement save search functionality
                // For now, just return success
                return Ok(new { message = "Search saved successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving search");
                return StatusCode(500, new { message = "Internal server error" });
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