using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;
using System.Text.Json;

namespace BEWorkNest.Services
{
    public class UserBehaviorService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UserBehaviorService> _logger;

        public UserBehaviorService(ApplicationDbContext context, ILogger<UserBehaviorService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Track user search behavior
        /// </summary>
        public async Task TrackSearchAsync(string userId, string searchQuery, string? filters = null)
        {
            try
            {
                var searchHistory = new SearchHistory
                {
                    UserId = userId,
                    SearchQuery = searchQuery,
                    SearchFilters = filters,
                    SearchTime = DateTime.UtcNow
                };

                _context.SearchHistories.Add(searchHistory);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking search for user {UserId}", userId);
            }
        }

        /// <summary>
        /// Track job view behavior
        /// </summary>
        public async Task TrackJobViewAsync(string userId, int jobId, string jobTitle, TimeSpan? viewDuration = null)
        {
            try
            {
                var jobView = new JobViewHistory
                {
                    UserId = userId,
                    JobId = jobId,
                    JobTitle = jobTitle,
                    ViewedAt = DateTime.UtcNow,
                    ViewDurationSeconds = (int?)viewDuration?.TotalSeconds
                };

                _context.JobViewHistories.Add(jobView);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking job view for user {UserId}, job {JobId}", userId, jobId);
            }
        }

        /// <summary>
        /// Track application behavior
        /// </summary>
        public async Task TrackApplicationAsync(string userId, int jobId, string jobTitle, string applicationStatus)
        {
            try
            {
                var applicationHistory = new ApplicationHistory
                {
                    UserId = userId,
                    JobId = jobId,
                    JobTitle = jobTitle,
                    ApplicationStatus = applicationStatus,
                    AppliedAt = DateTime.UtcNow
                };

                _context.ApplicationHistories.Add(applicationHistory);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking application for user {UserId}, job {JobId}", userId, jobId);
            }
        }

        /// <summary>
        /// Get user search history for AI analysis
        /// </summary>
        public async Task<List<Dictionary<string, object>>> GetUserSearchHistoryAsync(string userId, int limit = 50)
        {
            try
            {
                var searchHistory = await _context.SearchHistories
                    .Where(s => s.UserId == userId)
                    .OrderByDescending(s => s.SearchTime)
                    .Take(limit)
                    .ToListAsync();

                return searchHistory.Select(s => new Dictionary<string, object>
                {
                    ["search_query"] = s.SearchQuery,
                    ["search_filters"] = s.SearchFilters ?? "",
                    ["search_time"] = s.SearchTime,
                    ["frequency"] = searchHistory.Count(h => h.SearchQuery == s.SearchQuery)
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search history for user {UserId}", userId);
                return new List<Dictionary<string, object>>();
            }
        }

        /// <summary>
        /// Get user job view history for AI analysis
        /// </summary>
        public async Task<List<Dictionary<string, object>>> GetUserJobViewHistoryAsync(string userId, int limit = 50)
        {
            try
            {
                var jobViewHistory = await _context.JobViewHistories
                    .Where(j => j.UserId == userId)
                    .Include(j => j.Job)
                    .ThenInclude(job => job.Recruiter)
                    .ThenInclude(r => r.Company)
                    .OrderByDescending(j => j.ViewedAt)
                    .Take(limit)
                    .ToListAsync();

                return jobViewHistory.Select(j => new Dictionary<string, object>
                {
                    ["job_id"] = j.JobId,
                    ["job_title"] = j.JobTitle,
                    ["job_type"] = j.Job?.JobType ?? "",
                    ["location"] = j.Job?.Location ?? "",
                    ["salary"] = j.Job?.Salary ?? 0,
                    ["company"] = j.Job?.Recruiter?.Company?.Name ?? "",
                    ["viewed_at"] = j.ViewedAt,
                    ["view_duration"] = j.ViewDurationSeconds ?? 0,
                    ["experience_level"] = j.Job?.ExperienceLevel ?? ""
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting job view history for user {UserId}", userId);
                return new List<Dictionary<string, object>>();
            }
        }

        /// <summary>
        /// Get user application history for AI analysis
        /// </summary>
        public async Task<List<Dictionary<string, object>>> GetUserApplicationHistoryAsync(string userId, int limit = 50)
        {
            try
            {
                var applications = await _context.Applications
                    .Where(a => a.ApplicantId == userId)
                    .Include(a => a.Job)
                    .ThenInclude(j => j.Recruiter)
                    .ThenInclude(r => r.Company)
                    .OrderByDescending(a => a.CreatedAt)
                    .Take(limit)
                    .ToListAsync();

                return applications.Select(a => new Dictionary<string, object>
                {
                    ["application_id"] = a.Id,
                    ["job_id"] = a.JobId,
                    ["job_title"] = a.Job.Title,
                    ["job_type"] = a.Job.JobType,
                    ["location"] = a.Job.Location,
                    ["salary"] = a.Job.Salary,
                    ["company"] = a.Job.Recruiter.Company?.Name ?? "",
                    ["application_status"] = a.Status.ToString(),
                    ["applied_at"] = a.CreatedAt,
                    ["experience_level"] = a.Job.ExperienceLevel
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting application history for user {UserId}", userId);
                return new List<Dictionary<string, object>>();
            }
        }

        /// <summary>
        /// Get user profile for AI recommendations
        /// </summary>
        public async Task<Dictionary<string, object>> GetUserProfileForAIAsync(string userId)
        {
            try
            {
                var user = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Id == userId);

                if (user == null)
                    return new Dictionary<string, object>();

                // Get user preferences based on search and application history
                var searchKeywords = await GetTopSearchKeywordsAsync(userId);
                var preferredLocations = await GetPreferredLocationsAsync(userId);
                var preferredJobTypes = await GetPreferredJobTypesAsync(userId);
                var salaryRange = await GetPreferredSalaryRangeAsync(userId);

                return new Dictionary<string, object>
                {
                    ["user_id"] = user.Id,
                    ["first_name"] = user.FirstName,
                    ["last_name"] = user.LastName,
                    ["role"] = user.Role,
                    ["company"] = user.Company?.Name ?? "",
                    ["company_location"] = user.Company?.Location ?? "",
                    ["preferred_keywords"] = searchKeywords,
                    ["preferred_locations"] = preferredLocations,
                    ["preferred_job_types"] = preferredJobTypes,
                    ["salary_range"] = salaryRange,
                    ["profile_created"] = user.CreatedAt,
                    ["last_active"] = user.UpdatedAt
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user profile for AI for user {UserId}", userId);
                return new Dictionary<string, object>();
            }
        }

        /// <summary>
        /// Get candidate profiles for recruiter AI matching
        /// </summary>
        public async Task<List<Dictionary<string, object>>> GetCandidateProfilesForMatchingAsync(int limit = 100)
        {
            try
            {
                var candidates = await _context.Users
                    .Where(u => u.Role == "candidate" && u.IsActive)
                    .Take(limit)
                    .ToListAsync();

                var candidateProfiles = new List<Dictionary<string, object>>();

                foreach (var candidate in candidates)
                {
                    var searchHistory = await GetUserSearchHistoryAsync(candidate.Id, 10);
                    var applicationHistory = await GetUserApplicationHistoryAsync(candidate.Id, 10);
                    
                    candidateProfiles.Add(new Dictionary<string, object>
                    {
                        ["candidate_id"] = candidate.Id,
                        ["candidate_name"] = $"{candidate.FirstName} {candidate.LastName}",
                        ["email"] = candidate.Email ?? "",
                        ["search_history"] = searchHistory,
                        ["application_history"] = applicationHistory,
                        ["last_active"] = candidate.UpdatedAt,
                        ["member_since"] = candidate.CreatedAt
                    });
                }

                return candidateProfiles;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate profiles for matching");
                return new List<Dictionary<string, object>>();
            }
        }

        #region Private Helper Methods

        private async Task<List<string>> GetTopSearchKeywordsAsync(string userId)
        {
            try
            {
                var keywords = await _context.SearchHistories
                    .Where(s => s.UserId == userId && !string.IsNullOrEmpty(s.SearchQuery))
                    .GroupBy(s => s.SearchQuery.ToLower())
                    .OrderByDescending(g => g.Count())
                    .Take(10)
                    .Select(g => g.Key)
                    .ToListAsync();

                return keywords;
            }
            catch
            {
                return new List<string>();
            }
        }

        private async Task<List<string>> GetPreferredLocationsAsync(string userId)
        {
            try
            {
                var locations = await _context.JobViewHistories
                    .Where(j => j.UserId == userId)
                    .Include(j => j.Job)
                    .Where(j => j.Job != null && !string.IsNullOrEmpty(j.Job.Location))
                    .GroupBy(j => j.Job.Location.ToLower())
                    .OrderByDescending(g => g.Count())
                    .Take(5)
                    .Select(g => g.Key)
                    .ToListAsync();

                return locations;
            }
            catch
            {
                return new List<string>();
            }
        }

        private async Task<List<string>> GetPreferredJobTypesAsync(string userId)
        {
            try
            {
                var jobTypes = await _context.JobViewHistories
                    .Where(j => j.UserId == userId)
                    .Include(j => j.Job)
                    .Where(j => j.Job != null && !string.IsNullOrEmpty(j.Job.JobType))
                    .GroupBy(j => j.Job.JobType.ToLower())
                    .OrderByDescending(g => g.Count())
                    .Take(5)
                    .Select(g => g.Key)
                    .ToListAsync();

                return jobTypes;
            }
            catch
            {
                return new List<string>();
            }
        }

        private async Task<Dictionary<string, decimal>> GetPreferredSalaryRangeAsync(string userId)
        {
            try
            {
                var salaries = await _context.JobViewHistories
                    .Where(j => j.UserId == userId)
                    .Include(j => j.Job)
                    .Where(j => j.Job != null && j.Job.Salary > 0)
                    .Select(j => j.Job.Salary)
                    .ToListAsync();

                if (salaries.Any())
                {
                    return new Dictionary<string, decimal>
                    {
                        ["min_salary"] = salaries.Min(),
                        ["max_salary"] = salaries.Max(),
                        ["avg_salary"] = salaries.Average()
                    };
                }

                return new Dictionary<string, decimal>();
            }
            catch
            {
                return new Dictionary<string, decimal>();
            }
        }

        #endregion
    }
}
