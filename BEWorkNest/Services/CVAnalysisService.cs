using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;
using BEWorkNest.Services;

namespace BEWorkNest.Services
{
    public class CVAnalysisService
    {
        private readonly ApplicationDbContext _context;
        private readonly AiService _aiService;
        private readonly CVProcessingService _cvProcessingService;
        private readonly CloudinaryService _cloudinaryService;
        private readonly ILogger<CVAnalysisService> _logger;

        public CVAnalysisService(
            ApplicationDbContext context,
            AiService aiService,
            CVProcessingService cvProcessingService,
            CloudinaryService cloudinaryService,
            ILogger<CVAnalysisService> logger)
        {
            _context = context;
            _aiService = aiService;
            _cvProcessingService = cvProcessingService;
            _cloudinaryService = cloudinaryService;
            _logger = logger;
        }

        /// <summary>
        /// Phân tích CV từ file upload
        /// </summary>
        public async Task<CVAnalysisResponse> AnalyzeCVFromFileAsync(string userId, IFormFile cvFile)
        {
            try
            {
                _logger.LogInformation("Starting CV analysis from file for user: {UserId}", userId);

                // Validate file
                if (!_cvProcessingService.IsValidCVFile(cvFile))
                {
                    throw new ArgumentException("Invalid CV file format or size");
                }

                // Upload CV to Cloudinary
                string cvUrl = "";
                string cvPublicId = "";
                try
                {
                    cvUrl = await _cloudinaryService.UploadPdfAsync(cvFile, "cvs");
                    cvPublicId = _cloudinaryService.GetPublicIdFromUrl(cvUrl);
                    _logger.LogInformation("CV uploaded to Cloudinary: {CVUrl}", cvUrl);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to upload CV to Cloudinary, continuing with analysis");
                }

                // Extract text from CV file
                var cvText = await _cvProcessingService.ExtractTextFromCVAsync(cvFile);
                if (string.IsNullOrWhiteSpace(cvText))
                {
                    throw new ArgumentException("Could not extract text from CV file");
                }

                // Clean extracted text
                var cleanedText = _cvProcessingService.CleanExtractedText(cvText);

                // Perform analysis with CV file info
                return await AnalyzeCVTextAsync(userId, cleanedText, cvUrl, cvFile.FileName, cvPublicId, cvFile.Length);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error analyzing CV from file for user: {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Phân tích CV từ text
        /// </summary>
        public async Task<CVAnalysisResponse> AnalyzeCVTextAsync(string userId, string cvText)
        {
            return await AnalyzeCVTextAsync(userId, cvText, null, null, null, null);
        }

        /// <summary>
        /// Phân tích CV từ text với thông tin file CV
        /// </summary>
        public async Task<CVAnalysisResponse> AnalyzeCVTextAsync(string userId, string cvText, string? cvUrl, string? cvFileName, string? cvPublicId, long? cvFileSize)
        {
            try
            {
                _logger.LogInformation("Starting CV analysis from text for user: {UserId}", userId);

                // Get all active job posts for recommendations
                var activeJobs = await GetActiveJobsForRecommendationsAsync();

                // Use AI service to analyze CV
                var aiAnalysisResult = await _aiService.AnalyzeCVForJobAsync(cvText, new Dictionary<string, object>
                {
                    ["availableJobs"] = activeJobs.Select(j => new Dictionary<string, object>
                    {
                        ["id"] = j.Id,
                        ["title"] = j.Title,
                        ["company"] = j.Recruiter?.Company?.Name ?? "Unknown",
                        ["location"] = j.Location,
                        ["salary"] = j.Salary.ToString(),
                        ["jobType"] = j.JobType,
                        ["experienceLevel"] = j.ExperienceLevel,
                        ["skillsRequired"] = j.Requirements, // Use Requirements as skills
                        ["description"] = j.Description,
                        ["requirements"] = j.Requirements
                    }).ToList()
                });

                // Get job recommendations using AI
                var aiJobRecommendations = await _aiService.GetJobRecommendationsFromDatabaseAsync(cvText, userId);
                
                // Convert to analytics format
                var jobRecommendations = aiJobRecommendations.Select(rec => new JobRecommendationAnalytics
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
                    MatchReasons = new List<string> { rec.Reason },
                    RecommendationLevel = GetRecommendationLevel(rec.MatchPercentage),
                    PostedDate = rec.PostedDate,
                    ApplicationDeadline = rec.DeadLine,
                    IsActive = true
                }).ToList();

                // Create response
                var analysisId = Guid.NewGuid().ToString();
                var response = new CVAnalysisResponse
                {
                    AnalysisId = analysisId,
                    UserId = userId,
                    Profile = MapToCVProfile(aiAnalysisResult.CandidateInfo),
                    Scores = CalculateScoreBreakdown(aiAnalysisResult),
                    Strengths = aiAnalysisResult.Strengths,
                    Weaknesses = aiAnalysisResult.Weaknesses,
                    ImprovementSuggestions = aiAnalysisResult.ImprovementSuggestions,
                    RecommendedJobs = jobRecommendations,
                    DetailedAnalysis = aiAnalysisResult.DetailedAnalysis,
                    AnalyzedAt = DateTime.UtcNow
                };

                // Save analysis history
                await SaveAnalysisHistoryAsync(response, cvText, cvUrl, cvFileName, cvPublicId, cvFileSize);

                // Save job match analytics
                await SaveJobMatchAnalyticsAsync(userId, jobRecommendations);

                // Track analytics event
                await TrackAnalyticsEventAsync(userId, "cv_analysis", "analyze", analysisId);

                _logger.LogInformation("CV analysis completed for user: {UserId}, Analysis ID: {AnalysisId}", 
                    userId, analysisId);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error analyzing CV text for user: {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Lấy lịch sử phân tích CV của user
        /// </summary>
        public async Task<List<CVAnalysisHistory>> GetAnalysisHistoryAsync(string userId, int pageSize = 10, int pageNumber = 1)
        {
            try
            {
                return await _context.CVAnalysisHistories
                    .Where(ca => ca.UserId == userId)
                    .OrderByDescending(ca => ca.CreatedAt)
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting analysis history for user: {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Lấy chi tiết phân tích CV theo ID
        /// </summary>
        public async Task<CVAnalysisResponse?> GetAnalysisDetailAsync(string userId, string analysisId)
        {
            try
            {
                var history = await _context.CVAnalysisHistories
                    .FirstOrDefaultAsync(ca => ca.UserId == userId && ca.AnalysisId == analysisId);

                if (history == null)
                    return null;

                // Deserialize the analysis result
                var response = JsonSerializer.Deserialize<CVAnalysisResponse>(history.AnalysisResult);
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting analysis detail for user: {UserId}, Analysis ID: {AnalysisId}", 
                    userId, analysisId);
                throw;
            }
        }

        /// <summary>
        /// Lấy gợi ý việc làm dựa trên CV
        /// </summary>
        public async Task<List<JobRecommendationAnalytics>> GetJobRecommendationsForCVAsync(string userId, string cvText, int maxRecommendations = 10)
        {
            try
            {
                // Get user profile for personalization
                var userProfile = await GetUserProfileForRecommendationsAsync(userId);

                // Get search and application history
                var searchHistory = await GetUserSearchHistoryAsync(userId);
                var applicationHistory = await GetUserApplicationHistoryAsync(userId);

                // Use AI service to get personalized recommendations
                var recommendations = await _aiService.GetPersonalizedJobRecommendationsAsync(
                    userId, 
                    userProfile, 
                    searchHistory, 
                    applicationHistory);

                // Convert to analytics format and add detailed scoring
                var analyticsRecommendations = new List<JobRecommendationAnalytics>();

                foreach (var rec in recommendations.Take(maxRecommendations))
                {
                    var job = await _context.JobPosts
                        .Include(j => j.Recruiter)
                        .ThenInclude(r => r.Company)
                        .FirstOrDefaultAsync(j => j.Title.Contains(rec.Title) && j.IsActive);

                    if (job != null)
                    {
                        var analyticsRec = new JobRecommendationAnalytics
                        {
                            JobId = job.Id,
                            JobTitle = job.Title,
                            CompanyName = job.Recruiter?.Company?.Name ?? "Unknown",
                            Location = job.Location,
                            SalaryRange = job.Salary.ToString("C"),
                            JobType = job.JobType,
                            ExperienceLevel = job.ExperienceLevel,
                            MatchScore = rec.MatchPercentage,
                            MatchedSkills = rec.SkillsRequired,
                            MissingSkills = new List<string>(), // Will be calculated by AI
                            MatchReasons = new List<string> { rec.Reason },
                            RecommendationLevel = GetRecommendationLevel(rec.MatchPercentage),
                            SalaryFitScore = CalculateSalaryFitScore(userProfile, job.Salary),
                            LocationFitScore = CalculateLocationFitScore(userProfile, job.Location),
                            SkillFitScore = rec.MatchPercentage / 100.0,
                            ExperienceFitScore = CalculateExperienceFitScore(userProfile, job.ExperienceLevel),
                            PostedDate = job.CreatedAt,
                            ApplicationDeadline = job.CreatedAt.AddMonths(1), // Default deadline
                            IsActive = job.IsActive
                        };

                        analyticsRecommendations.Add(analyticsRec);
                    }
                }

                return analyticsRecommendations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting job recommendations for user: {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Lấy thống kê phân tích CV của user
        /// </summary>
        public async Task<CVAnalysisStats> GetAnalysisStatsAsync(string userId)
        {
            try
            {
                var stats = await _context.CVAnalysisHistories
                    .Where(ca => ca.UserId == userId)
                    .GroupBy(ca => ca.UserId)
                    .Select(g => new CVAnalysisStats
                    {
                        TotalAnalyses = g.Count(),
                        AverageScore = g.Average(ca => ca.OverallScore),
                        HighestScore = g.Max(ca => ca.OverallScore),
                        LowestScore = g.Min(ca => ca.OverallScore),
                        TotalJobRecommendations = g.Sum(ca => ca.JobRecommendationsCount),
                        LastAnalysisDate = g.Max(ca => ca.CreatedAt),
                        FirstAnalysisDate = g.Min(ca => ca.CreatedAt)
                    })
                    .FirstOrDefaultAsync();

                return stats ?? new CVAnalysisStats();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting analysis stats for user: {UserId}", userId);
                throw;
            }
        }

        #region Private Helper Methods

        private async Task<List<JobPost>> GetActiveJobsForRecommendationsAsync()
        {
            return await _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(j => j.IsActive && j.DeadLine > DateTime.UtcNow)
                .OrderByDescending(j => j.CreatedAt)
                .Take(100) // Limit for performance
                .ToListAsync();
        }

        private async Task<List<JobRecommendationAnalytics>> GetPersonalizedJobRecommendationsAsync(
            string userId, string cvText, CVAnalysisResult aiResult)
        {
            try
            {
                var userProfile = await GetUserProfileForRecommendationsAsync(userId);
                var searchHistory = await GetUserSearchHistoryAsync(userId);
                var applicationHistory = await GetUserApplicationHistoryAsync(userId);

                var recommendations = await _aiService.GetPersonalizedJobRecommendationsAsync(
                    userId, userProfile, searchHistory, applicationHistory);

                var result = new List<JobRecommendationAnalytics>();

                foreach (var rec in recommendations)
                {
                    // Find matching job in database
                    var job = await _context.JobPosts
                        .Include(j => j.Recruiter)
                        .ThenInclude(r => r.Company)
                        .FirstOrDefaultAsync(j => j.Title.ToLower().Contains(rec.Title.ToLower()) && j.IsActive);

                    if (job != null)
                    {
                        var analytics = new JobRecommendationAnalytics
                        {
                            JobId = job.Id,
                            JobTitle = job.Title,
                            CompanyName = job.Recruiter?.Company?.Name ?? "Unknown",
                            Location = job.Location,
                            SalaryRange = job.Salary.ToString("C"),
                            JobType = job.JobType,
                            ExperienceLevel = job.ExperienceLevel,
                            MatchScore = rec.MatchPercentage,
                            MatchedSkills = rec.SkillsRequired,
                            MatchReasons = new List<string> { rec.Reason },
                            RecommendationLevel = GetRecommendationLevel(rec.MatchPercentage),
                            PostedDate = job.CreatedAt,
                            ApplicationDeadline = job.CreatedAt.AddMonths(1), // Default deadline
                            IsActive = job.IsActive
                        };

                        result.Add(analytics);
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting personalized job recommendations");
                return new List<JobRecommendationAnalytics>();
            }
        }

        private CVProfile MapToCVProfile(CandidateInfo candidateInfo)
        {
            return new CVProfile
            {
                Skills = candidateInfo.Skills,
                TechnicalSkills = candidateInfo.Skills.Where(s => IsTechnicalSkill(s)).ToList(),
                SoftSkills = candidateInfo.Skills.Where(s => !IsTechnicalSkill(s)).ToList(),
                ExperienceYears = candidateInfo.ExperienceYears,
                EducationLevel = candidateInfo.Education,
                Projects = candidateInfo.Projects,
                WorkHistory = candidateInfo.PreviousPositions.Select(p => new WorkExperience 
                { 
                    Position = p, 
                    Company = "Previous Company" 
                }).ToList()
            };
        }

        private CVScoreBreakdown CalculateScoreBreakdown(CVAnalysisResult aiResult)
        {
            var breakdown = new CVScoreBreakdown
            {
                OverallScore = aiResult.MatchScore,
                SkillsScore = Math.Min(100, aiResult.CandidateInfo.Skills.Count * 10),
                ExperienceScore = Math.Min(100, aiResult.CandidateInfo.ExperienceYears * 5),
                EducationScore = string.IsNullOrEmpty(aiResult.CandidateInfo.Education) ? 50 : 80,
                ProjectsScore = Math.Min(100, aiResult.CandidateInfo.Projects.Count * 20),
                CertificationsScore = 70 // Default score
            };

            return breakdown;
        }

        private async Task SaveAnalysisHistoryAsync(CVAnalysisResponse response, string cvText)
        {
            await SaveAnalysisHistoryAsync(response, cvText, null, null, null, null);
        }

        private async Task SaveAnalysisHistoryAsync(CVAnalysisResponse response, string cvText, string? cvUrl, string? cvFileName, string? cvPublicId, long? cvFileSize)
        {
            var history = new CVAnalysisHistory
            {
                AnalysisId = response.AnalysisId,
                UserId = response.UserId,
                CVText = cvText,
                AnalysisResult = JsonSerializer.Serialize(response),
                OverallScore = response.Scores.OverallScore,
                JobRecommendationsCount = response.RecommendedJobs.Count,
                CreatedAt = response.AnalyzedAt,
                CVUrl = cvUrl,
                CVFileName = cvFileName,
                CVPublicId = cvPublicId,
                CVFileSize = cvFileSize
            };

            _context.CVAnalysisHistories.Add(history);
            await _context.SaveChangesAsync();
        }

        private async Task SaveJobMatchAnalyticsAsync(string userId, List<JobRecommendationAnalytics> recommendations)
        {
            foreach (var rec in recommendations)
            {
                var existing = await _context.JobMatchAnalytics
                    .FirstOrDefaultAsync(jma => jma.JobId == rec.JobId && jma.UserId == userId);

                if (existing != null)
                {
                    existing.MatchScore = rec.MatchScore;
                    existing.MatchDetails = JsonSerializer.Serialize(rec);
                    existing.AnalyzedAt = DateTime.UtcNow;
                }
                else
                {
                    var analytics = new JobMatchAnalytics
                    {
                        JobId = rec.JobId,
                        UserId = userId,
                        MatchScore = rec.MatchScore,
                        MatchDetails = JsonSerializer.Serialize(rec),
                        AnalyzedAt = DateTime.UtcNow
                    };

                    _context.JobMatchAnalytics.Add(analytics);
                }
            }

            await _context.SaveChangesAsync();
        }

        private async Task TrackAnalyticsEventAsync(string userId, string type, string action, string targetId)
        {
            var analytics = new Analytics
            {
                UserId = userId,
                Type = type,
                Action = action,
                TargetId = targetId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Analytics.Add(analytics);
            await _context.SaveChangesAsync();
        }

        private async Task<Dictionary<string, object>> GetUserProfileForRecommendationsAsync(string userId)
        {
            var user = await _context.Users
                .Include(u => u.UserProfile)
                .FirstOrDefaultAsync(u => u.Id == userId);

            var profile = new Dictionary<string, object>();

            if (user != null)
            {
                profile["fullName"] = $"{user.FirstName} {user.LastName}".Trim();
                profile["email"] = user.Email ?? "";
                profile["phoneNumber"] = user.PhoneNumber ?? "";
                profile["isRecruiter"] = user.Role?.ToLower() == "recruiter";

                if (user.UserProfile != null)
                {
                    profile["skills"] = user.UserProfile.Skills ?? "";
                    profile["experience"] = user.UserProfile.Experience ?? "";
                    profile["education"] = user.UserProfile.Education ?? "";
                    profile["bio"] = user.UserProfile.Bio ?? "";
                    profile["linkedIn"] = "";
                    profile["github"] = "";
                    profile["portfolio"] = "";
                }
            }

            return profile;
        }

        private async Task<List<Dictionary<string, object>>> GetUserSearchHistoryAsync(string userId)
        {
            var searchHistoryData = await _context.SearchHistories
                .Where(sh => sh.UserId == userId)
                .OrderByDescending(sh => sh.CreatedAt)
                .Take(10)
                .ToListAsync();

            var searchHistory = searchHistoryData.Select(sh => new Dictionary<string, object>
                {
                    ["searchTerm"] = sh.SearchQuery,
                    ["searchDate"] = sh.SearchTime,
                    ["resultCount"] = 0 // Default value as we don't have this in model
                })
                .ToList();

            return searchHistory;
        }

        private async Task<List<Dictionary<string, object>>> GetUserApplicationHistoryAsync(string userId)
        {
            var applicationData = await _context.Applications
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(a => a.ApplicantId == userId)
                .OrderByDescending(a => a.CreatedAt)
                .Take(10)
                .ToListAsync();

            var applicationHistory = applicationData.Select(a => new Dictionary<string, object>
                {
                    ["jobTitle"] = a.Job.Title,
                    ["companyName"] = a.Job.Recruiter?.Company?.Name ?? "Unknown",
                    ["appliedDate"] = a.CreatedAt,
                    ["status"] = a.Status
                })
                .ToList();

            return applicationHistory;
        }

        private string GetRecommendationLevel(int matchScore)
        {
            return matchScore switch
            {
                >= 80 => "Highly Recommended",
                >= 60 => "Good Match",
                >= 40 => "Potential Match",
                _ => "Low Match"
            };
        }

        private double CalculateSalaryFitScore(Dictionary<string, object> userProfile, decimal? jobSalary)
        {
            // This is a simplified calculation - you can enhance it based on user's salary expectations
            return 0.8; // Default good fit
        }

        private double CalculateLocationFitScore(Dictionary<string, object> userProfile, string jobLocation)
        {
            // This is a simplified calculation - you can enhance it based on user's location preferences
            return 0.9; // Default good fit
        }

        private double CalculateExperienceFitScore(Dictionary<string, object> userProfile, string experienceLevel)
        {
            // This is a simplified calculation - you can enhance it based on user's actual experience
            return 0.85; // Default good fit
        }

        private bool IsTechnicalSkill(string skill)
        {
            var technicalKeywords = new[] { "programming", "coding", "development", "software", "database", 
                "java", "c#", "python", "javascript", "react", "angular", "vue", "node", "sql", "aws", "azure" };
            
            return technicalKeywords.Any(keyword => skill.ToLower().Contains(keyword));
        }

        #endregion
    }

    public class CVAnalysisStats
    {
        public int TotalAnalyses { get; set; }
        public double AverageScore { get; set; }
        public int HighestScore { get; set; }
        public int LowestScore { get; set; }
        public int TotalJobRecommendations { get; set; }
        public DateTime? LastAnalysisDate { get; set; }
        public DateTime? FirstAnalysisDate { get; set; }
    }
}
