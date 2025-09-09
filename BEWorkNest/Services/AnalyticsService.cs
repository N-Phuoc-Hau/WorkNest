using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;

namespace BEWorkNest.Services
{
    public class AnalyticsService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AnalyticsService> _logger;

        public AnalyticsService(ApplicationDbContext context, ILogger<AnalyticsService> logger)
        {
            _context = context;
            _logger = logger;
        }

        // Track analytics event
        public async Task TrackEventAsync(string userId, string type, string action, string? targetId = null, string? metadata = null)
        {
            try
            {
                var analytics = new Analytics
                {
                    UserId = userId,
                    Type = type,
                    Action = action,
                    TargetId = targetId,
                    Metadata = metadata,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Analytics.Add(analytics);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking analytics event");
            }
        }

        // Get admin dashboard stats
        public async Task<DashboardStats> GetAdminDashboardStatsAsync()
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            var stats = new DashboardStats
            {
                TotalJobs = await _context.JobPosts.CountAsync(),
                ActiveJobs = await _context.JobPosts.Where(j => j.IsActive).CountAsync(),
                TotalApplications = await _context.Applications.CountAsync(),
                PendingApplications = await _context.Applications.Where(a => a.Status == ApplicationStatus.Pending).CountAsync(),
                ApprovedApplications = await _context.Applications.Where(a => a.Status == ApplicationStatus.Accepted).CountAsync(),
                RejectedApplications = await _context.Applications.Where(a => a.Status == ApplicationStatus.Rejected).CountAsync(),
                TotalUsers = await _context.Users.CountAsync(),
                NewUsersThisMonth = await _context.Users.Where(u => u.CreatedAt >= startOfMonth).CountAsync(),
                AverageSalary = await _context.JobPosts.Where(j => j.Salary > 0).AverageAsync(j => j.Salary)
            };

            // Get job views by day (last 7 days)
            var last7Days = Enumerable.Range(0, 7).Select(i => now.AddDays(-i).Date).ToList();
            stats.JobViewsByDay = await GetJobViewsByDayAsync(last7Days);

            // Get applications by day (last 7 days)
            stats.ApplicationsByDay = await GetApplicationsByDayAsync(last7Days);

            // Get top job categories
            stats.TopJobCategories = await GetTopJobCategoriesAsync();

            // Get top locations
            stats.TopLocations = await GetTopLocationsAsync();

            return stats;
        }

        // Get recruiter dashboard
        public async Task<RecruiterDashboard> GetRecruiterDashboardAsync(string recruiterId)
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            var dashboard = new RecruiterDashboard
            {
                TotalJobPosts = await _context.JobPosts.Where(j => j.RecruiterId == recruiterId).CountAsync(),
                ActiveJobPosts = await _context.JobPosts.Where(j => j.RecruiterId == recruiterId && j.IsActive).CountAsync(),
                TotalApplications = await _context.Applications
                    .Where(a => a.Job.RecruiterId == recruiterId)
                    .CountAsync(),
                PendingApplications = await _context.Applications
                    .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Pending)
                    .CountAsync(),
                ApprovedApplications = await _context.Applications
                    .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Accepted)
                    .CountAsync(),
                RejectedApplications = await _context.Applications
                    .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Rejected)
                    .CountAsync(),
                TotalViews = await _context.Analytics
                    .Where(a => a.Type == "job_view" && a.TargetId != null)
                    .Join(_context.JobPosts.Where(j => j.RecruiterId == recruiterId),
                          a => a.TargetId,
                          j => j.Id.ToString(),
                          (a, j) => a)
                    .CountAsync(),
                ViewsThisMonth = await _context.Analytics
                    .Where(a => a.Type == "job_view" && a.CreatedAt >= startOfMonth && a.TargetId != null)
                    .Join(_context.JobPosts.Where(j => j.RecruiterId == recruiterId),
                          a => a.TargetId,
                          j => j.Id.ToString(),
                          (a, j) => a)
                    .CountAsync()
            };

            // Get top performing jobs
            dashboard.TopPerformingJobs = await GetTopPerformingJobsAsync(recruiterId);

            // Get application trends
            dashboard.ApplicationTrends = await GetApplicationTrendsAsync(recruiterId);

            // Get applications by status
            dashboard.ApplicationsByStatus = await GetApplicationsByStatusAsync(recruiterId);

            // Get views by day
            var last7Days = Enumerable.Range(0, 7).Select(i => now.AddDays(-i).Date).ToList();
            dashboard.ViewsByDay = await GetViewsByDayAsync(recruiterId, last7Days);

            return dashboard;
        }

        // Get candidate dashboard
        public async Task<CandidateDashboard> GetCandidateDashboardAsync(string candidateId)
        {
            var dashboard = new CandidateDashboard
            {
                TotalApplications = await _context.Applications.Where(a => a.ApplicantId == candidateId).CountAsync(),
                PendingApplications = await _context.Applications.Where(a => a.ApplicantId == candidateId && a.Status == ApplicationStatus.Pending).CountAsync(),
                ApprovedApplications = await _context.Applications.Where(a => a.ApplicantId == candidateId && a.Status == ApplicationStatus.Accepted).CountAsync(),
                RejectedApplications = await _context.Applications.Where(a => a.ApplicantId == candidateId && a.Status == ApplicationStatus.Rejected).CountAsync(),
                SavedJobs = await _context.FavoriteJobs.Where(f => f.UserId == candidateId).CountAsync(),
                FollowedCompanies = await _context.Follows.Where(f => f.FollowerId == candidateId).CountAsync()
            };

            // Get recent applications
            dashboard.RecentApplications = await GetRecentApplicationsAsync(candidateId);

            // Get application status distribution
            dashboard.ApplicationStatusDistribution = await GetApplicationStatusDistributionAsync(candidateId);

            // Get applications by month
            dashboard.ApplicationsByMonth = await GetApplicationsByMonthAsync(candidateId);

            return dashboard;
        }

        // Helper methods
        private async Task<List<ChartData>> GetJobViewsByDayAsync(List<DateTime> dates)
        {
            var views = await _context.Analytics
                .Where(a => a.Type == "job_view" && dates.Contains(a.CreatedAt.Date))
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToListAsync();

            return dates.Select(date => new ChartData
            {
                Label = date.ToString("MM/dd"),
                Value = views.FirstOrDefault(v => v.Date == date)?.Count ?? 0,
                Color = "#2196F3"
            }).ToList();
        }

        private async Task<List<ChartData>> GetApplicationsByDayAsync(List<DateTime> dates)
        {
            var applications = await _context.Applications
                .Where(a => dates.Contains(a.CreatedAt.Date))
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToListAsync();

            return dates.Select(date => new ChartData
            {
                Label = date.ToString("MM/dd"),
                Value = applications.FirstOrDefault(a => a.Date == date)?.Count ?? 0,
                Color = "#4CAF50"
            }).ToList();
        }

        private async Task<List<ChartData>> GetTopJobCategoriesAsync()
        {
            var categories = await _context.JobPosts
                .GroupBy(j => j.JobType)
                .Select(g => new { Category = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .Take(5)
                .ToListAsync();

            var colors = new[] { "#FF5722", "#FF9800", "#FFC107", "#8BC34A", "#2196F3" };

            return categories.Select((cat, index) => new ChartData
            {
                Label = cat.Category,
                Value = cat.Count,
                Color = colors[index % colors.Length]
            }).ToList();
        }

        private async Task<List<ChartData>> GetTopLocationsAsync()
        {
            var locations = await _context.JobPosts
                .GroupBy(j => j.Location)
                .Select(g => new { Location = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .Take(5)
                .ToListAsync();

            var colors = new[] { "#9C27B0", "#673AB7", "#3F51B5", "#2196F3", "#03A9F4" };

            return locations.Select((loc, index) => new ChartData
            {
                Label = loc.Location,
                Value = loc.Count,
                Color = colors[index % colors.Length]
            }).ToList();
        }

        private async Task<List<JobPerformance>> GetTopPerformingJobsAsync(string recruiterId)
        {
            return await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .Select(j => new JobPerformance
                {
                    JobId = j.Id,
                    JobTitle = j.Title,
                    Views = _context.Analytics.Count(a => a.Type == "job_view" && a.TargetId == j.Id.ToString()),
                    Applications = _context.Applications.Count(a => a.JobId == j.Id),
                    PostedDate = j.CreatedAt
                })
                .OrderByDescending(j => j.Views)
                .Take(5)
                .ToListAsync();
        }

        private async Task<List<ApplicationTrend>> GetApplicationTrendsAsync(string recruiterId)
        {
            var last7Days = Enumerable.Range(0, 7).Select(i => DateTime.UtcNow.AddDays(-i).Date).ToList();

            return await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && last7Days.Contains(a.CreatedAt.Date))
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new ApplicationTrend
                {
                    Date = g.Key,
                    Applications = g.Count(),
                    Views = _context.Analytics.Count(a => a.Type == "job_view" && a.CreatedAt.Date == g.Key)
                })
                .OrderBy(t => t.Date)
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetApplicationsByStatusAsync(string recruiterId)
        {
            var statuses = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .GroupBy(a => a.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            var colors = new Dictionary<ApplicationStatus, string>
            {
                [ApplicationStatus.Pending] = "#FF9800",
                [ApplicationStatus.Accepted] = "#4CAF50",
                [ApplicationStatus.Rejected] = "#F44336"
            };

            return statuses.Select(s => new ChartData
            {
                Label = s.Status.ToString(),
                Value = s.Count,
                Color = colors.GetValueOrDefault(s.Status, "#9E9E9E")
            }).ToList();
        }

        private async Task<List<ChartData>> GetViewsByDayAsync(string recruiterId, List<DateTime> dates)
        {
            var views = await _context.Analytics
                .Where(a => a.Type == "job_view" && dates.Contains(a.CreatedAt.Date) && a.TargetId != null)
                .Join(_context.JobPosts.Where(j => j.RecruiterId == recruiterId),
                      a => a.TargetId,
                      j => j.Id.ToString(),
                      (a, j) => a)
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToListAsync();

            return dates.Select(date => new ChartData
            {
                Label = date.ToString("MM/dd"),
                Value = views.FirstOrDefault(v => v.Date == date)?.Count ?? 0,
                Color = "#2196F3"
            }).ToList();
        }

        private async Task<List<ApplicationStatusInfo>> GetRecentApplicationsAsync(string candidateId)
        {
            return await _context.Applications
                .Where(a => a.ApplicantId == candidateId)
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .OrderByDescending(a => a.CreatedAt)
                .Take(5)
                .Select(a => new ApplicationStatusInfo
                {
                    ApplicationId = a.Id,
                    JobTitle = a.Job.Title,
                    CompanyName = a.Job.Recruiter.Company != null ? a.Job.Recruiter.Company.Name : "",
                    Status = a.Status.ToString(),
                    AppliedDate = a.CreatedAt,
                    UpdatedDate = a.UpdatedAt
                })
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetApplicationStatusDistributionAsync(string candidateId)
        {
            var statuses = await _context.Applications
                .Where(a => a.ApplicantId == candidateId)
                .GroupBy(a => a.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            var colors = new Dictionary<ApplicationStatus, string>
            {
                [ApplicationStatus.Pending] = "#FF9800",
                [ApplicationStatus.Accepted] = "#4CAF50",
                [ApplicationStatus.Rejected] = "#F44336"
            };

            return statuses.Select(s => new ChartData
            {
                Label = s.Status.ToString(),
                Value = s.Count,
                Color = colors.GetValueOrDefault(s.Status, "#9E9E9E")
            }).ToList();
        }

        private async Task<List<ChartData>> GetApplicationsByMonthAsync(string candidateId)
        {
            var last6Months = Enumerable.Range(0, 6).Select(i => DateTime.UtcNow.AddMonths(-i)).ToList();

            var applications = await _context.Applications
                .Where(a => a.ApplicantId == candidateId && last6Months.Contains(a.CreatedAt))
                .GroupBy(a => new { a.CreatedAt.Year, a.CreatedAt.Month })
                .Select(g => new { Year = g.Key.Year, Month = g.Key.Month, Count = g.Count() })
                .ToListAsync();

            return last6Months.Select(date => new ChartData
            {
                Label = date.ToString("MMM yyyy"),
                Value = applications.FirstOrDefault(a => a.Year == date.Year && a.Month == date.Month)?.Count ?? 0,
                Color = "#4CAF50"
            }).ToList();
        }

        // NEW DETAILED ANALYTICS METHODS
        public async Task<DetailedAnalytics> GetDetailedAnalyticsAsync(string recruiterId)
        {
            var recruiterAnalytics = await GetRecruiterDetailedAnalyticsAsync(recruiterId);
            var companyAnalytics = await GetCompanyAnalyticsAsync(recruiterId);
            var jobAnalytics = await GetJobAnalyticsAsync(recruiterId);

            return new DetailedAnalytics
            {
                Recruiter = recruiterAnalytics,
                Company = companyAnalytics,
                Jobs = jobAnalytics,
                GeneratedAt = DateTime.UtcNow
            };
        }

        public async Task<DetailedAnalytics> GetSimplifiedAnalyticsAsync(string recruiterId)
        {
            var recruiterAnalytics = await GetRecruiterSimplifiedAnalyticsAsync(recruiterId);
            var companyAnalytics = await GetCompanyAnalyticsAsync(recruiterId);
            var jobAnalytics = await GetJobSimplifiedAnalyticsAsync(recruiterId);

            return new DetailedAnalytics
            {
                Recruiter = recruiterAnalytics,
                Company = companyAnalytics,
                Jobs = jobAnalytics,
                GeneratedAt = DateTime.UtcNow
            };
        }

        private async Task<RecruiterAnalytics> GetRecruiterDetailedAnalyticsAsync(string recruiterId)
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            // Basic stats
            var totalJobsPosted = await _context.JobPosts.CountAsync(j => j.RecruiterId == recruiterId);
            var activeJobs = await _context.JobPosts.CountAsync(j => j.RecruiterId == recruiterId && j.IsActive);
            var inactiveJobs = totalJobsPosted - activeJobs;

            var totalApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .CountAsync();

            var pendingApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Pending)
                .CountAsync();

            var acceptedApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Accepted)
                .CountAsync();

            var rejectedApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Rejected)
                .CountAsync();

            // View analytics
            var jobIds = await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .Select(j => j.Id.ToString())
                .ToListAsync();

            var totalJobViews = await _context.Analytics
                .Where(a => a.Type == "job_view" && jobIds.Contains(a.TargetId!))
                .CountAsync();

            var uniqueJobViewers = await _context.Analytics
                .Where(a => a.Type == "job_view" && jobIds.Contains(a.TargetId!))
                .Select(a => a.UserId)
                .Distinct()
                .CountAsync();

            // Company followers
            var company = await _context.Companies.FirstOrDefaultAsync(c => c.UserId == recruiterId);
            var companyFollowers = 0;
            if (company != null)
            {
                companyFollowers = await _context.Follows
                    .CountAsync(f => f.RecruiterId == recruiterId && f.IsActive);
            }

            // Calculate averages and ratios
            var averageApplicationsPerJob = totalJobsPosted > 0 ? (decimal)totalApplications / totalJobsPosted : 0;
            var averageViewsPerJob = totalJobsPosted > 0 ? (decimal)totalJobViews / totalJobsPosted : 0;
            var applicationToViewRatio = totalJobViews > 0 ? (decimal)totalApplications / totalJobViews : 0;

            // Get detailed job performance
            var jobPerformance = await GetJobDetailedPerformanceAsync(recruiterId);

            // Get monthly data
            var applicationsByMonth = await GetRecruiterApplicationsByMonthAsync(recruiterId);
            var viewsByMonth = await GetViewsByMonthAsync(recruiterId);

            // Get top job categories
            var topJobCategories = await GetTopJobCategoriesForRecruiterAsync(recruiterId);

            // Get application status distribution
            var applicationStatusDistribution = await GetApplicationStatusDistributionForRecruiterAsync(recruiterId);

            // Get recent followers
            var recentFollowers = await GetRecentFollowersAsync(recruiterId);

            return new RecruiterAnalytics
            {
                TotalJobsPosted = totalJobsPosted,
                ActiveJobs = activeJobs,
                InactiveJobs = inactiveJobs,
                TotalApplicationsReceived = totalApplications,
                PendingApplications = pendingApplications,
                AcceptedApplications = acceptedApplications,
                RejectedApplications = rejectedApplications,
                TotalJobViews = totalJobViews,
                UniqueJobViewers = uniqueJobViewers,
                CompanyFollowers = companyFollowers,
                AverageApplicationsPerJob = averageApplicationsPerJob,
                AverageViewsPerJob = averageViewsPerJob,
                ApplicationToViewRatio = applicationToViewRatio,
                JobPerformance = jobPerformance,
                ApplicationsByMonth = applicationsByMonth,
                ViewsByMonth = viewsByMonth,
                TopJobCategories = topJobCategories,
                ApplicationStatusDistribution = applicationStatusDistribution,
                RecentFollowers = recentFollowers
            };
        }

        private async Task<CompanyAnalytics> GetCompanyAnalyticsAsync(string recruiterId)
        {
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.UserId == recruiterId);

            if (company == null)
            {
                return new CompanyAnalytics
                {
                    CompanyName = "Chưa có thông tin công ty",
                    CompanyLocation = "Chưa cập nhật",
                    IsVerified = false
                };
            }

            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);

            var totalFollowers = await _context.Follows
                .CountAsync(f => f.RecruiterId == recruiterId && f.IsActive);

            var newFollowersThisMonth = await _context.Follows
                .CountAsync(f => f.RecruiterId == recruiterId && f.IsActive && f.CreatedAt >= startOfMonth);

            var totalJobsPosted = await _context.JobPosts
                .CountAsync(j => j.RecruiterId == recruiterId);

            var totalApplicationsReceived = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .CountAsync();

            // Follower growth
            var followerGrowth = await GetFollowerGrowthAsync(recruiterId);

            // Company reviews - sử dụng review cho recruiter thay vì company
            var recentReviews = await GetRecruiterRecentReviewsAsync(recruiterId);
            var averageRating = await GetRecruiterAverageRatingAsync(recruiterId);
            var totalReviews = await _context.Reviews.CountAsync(r => r.ReviewedUserId == recruiterId);

            return new CompanyAnalytics
            {
                CompanyId = company.Id,
                CompanyName = company.Name,
                CompanyLocation = company.Location,
                IsVerified = company.IsVerified,
                TotalFollowers = totalFollowers,
                NewFollowersThisMonth = newFollowersThisMonth,
                TotalJobsPosted = totalJobsPosted,
                TotalApplicationsReceived = totalApplicationsReceived,
                CompanyCreatedAt = company.CreatedAt,
                FollowerGrowth = followerGrowth,
                RecentReviews = recentReviews,
                AverageRating = averageRating,
                TotalReviews = totalReviews
            };
        }

        private async Task<JobAnalytics> GetJobAnalyticsAsync(string recruiterId)
        {
            var allJobs = await GetJobDetailedPerformanceAsync(recruiterId);
            
            var bestPerformingJob = allJobs.OrderByDescending(j => j.ViewToApplicationRatio).FirstOrDefault();
            var mostViewedJob = allJobs.OrderByDescending(j => j.TotalViews).FirstOrDefault();
            var mostAppliedJob = allJobs.OrderByDescending(j => j.TotalApplications).FirstOrDefault();

            var jobsByCategory = await GetJobsByCategoryAsync(recruiterId);
            var jobsByLocation = await GetJobsByLocationAsync(recruiterId);
            var jobsByExperienceLevel = await GetJobsByExperienceLevelAsync(recruiterId);
            var salaryDistribution = await GetSalaryDistributionAsync(recruiterId);

            return new JobAnalytics
            {
                AllJobs = allJobs,
                BestPerformingJob = bestPerformingJob,
                MostViewedJob = mostViewedJob,
                MostAppliedJob = mostAppliedJob,
                JobsByCategory = jobsByCategory,
                JobsByLocation = jobsByLocation,
                JobsByExperienceLevel = jobsByExperienceLevel,
                SalaryDistribution = salaryDistribution
            };
        }

        private async Task<List<JobDetailedPerformance>> GetJobDetailedPerformanceAsync(string recruiterId)
        {
            var jobs = await _context.JobPosts
                .Include(j => j.Applications)
                .Include(j => j.FavoriteJobs)
                .Where(j => j.RecruiterId == recruiterId)
                .ToListAsync();

            var jobPerformanceList = new List<JobDetailedPerformance>();

            foreach (var job in jobs)
            {
                var jobIdStr = job.Id.ToString();
                
                var totalViews = await _context.Analytics
                    .CountAsync(a => a.Type == "job_view" && a.TargetId == jobIdStr);

                var uniqueViews = await _context.Analytics
                    .Where(a => a.Type == "job_view" && a.TargetId == jobIdStr)
                    .Select(a => a.UserId)
                    .Distinct()
                    .CountAsync();

                var totalApplications = job.Applications.Count(a => a.IsActive);
                var pendingApplications = job.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Pending);
                var acceptedApplications = job.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Accepted);
                var rejectedApplications = job.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Rejected);

                var viewToApplicationRatio = totalViews > 0 ? (decimal)totalApplications / totalViews : 0;
                var acceptanceRate = totalApplications > 0 ? (decimal)acceptedApplications / totalApplications : 0;

                var favoriteCount = job.FavoriteJobs.Count;

                // Get views and applications by day (last 30 days)
                var viewsByDay = await GetJobViewsByDayAsync(job.Id, 30);
                var applicationsByDay = await GetJobApplicationsByDayAsync(job.Id, 30);

                // Get recent applicants
                var recentApplicants = await GetJobRecentApplicantsAsync(job.Id);

                jobPerformanceList.Add(new JobDetailedPerformance
                {
                    JobId = job.Id,
                    JobTitle = job.Title,
                    JobCategory = job.Specialized,
                    JobLocation = job.Location,
                    ExperienceLevel = job.ExperienceLevel,
                    Salary = job.Salary,
                    PostedDate = job.CreatedAt,
                    DeadLine = job.DeadLine,
                    IsActive = job.IsActive,
                    TotalViews = totalViews,
                    UniqueViews = uniqueViews,
                    TotalApplications = totalApplications,
                    PendingApplications = pendingApplications,
                    AcceptedApplications = acceptedApplications,
                    RejectedApplications = rejectedApplications,
                    ViewToApplicationRatio = viewToApplicationRatio,
                    AcceptanceRate = acceptanceRate,
                    FavoriteCount = favoriteCount,
                    ViewsByDay = viewsByDay,
                    ApplicationsByDay = applicationsByDay,
                    RecentApplicants = recentApplicants
                });
            }

            return jobPerformanceList.OrderByDescending(j => j.TotalViews).ToList();
        }

        private async Task<List<ChartData>> GetRecruiterApplicationsByMonthAsync(string recruiterId)
        {
            var last12Months = Enumerable.Range(0, 12).Select(i => DateTime.UtcNow.AddMonths(-i)).ToList();

            var applications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .GroupBy(a => new { a.CreatedAt.Year, a.CreatedAt.Month })
                .Select(g => new { Year = g.Key.Year, Month = g.Key.Month, Count = g.Count() })
                .ToListAsync();

            return last12Months.Select(date => new ChartData
            {
                Label = date.ToString("MMM yyyy"),
                Value = applications.FirstOrDefault(a => a.Year == date.Year && a.Month == date.Month)?.Count ?? 0,
                Color = "#2196F3"
            }).Reverse().ToList();
        }

        private async Task<List<ChartData>> GetViewsByMonthAsync(string recruiterId)
        {
            var last12Months = Enumerable.Range(0, 12).Select(i => DateTime.UtcNow.AddMonths(-i)).ToList();

            var jobIds = await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .Select(j => j.Id.ToString())
                .ToListAsync();

            var views = await _context.Analytics
                .Where(a => a.Type == "job_view" && jobIds.Contains(a.TargetId!))
                .GroupBy(a => new { a.CreatedAt.Year, a.CreatedAt.Month })
                .Select(g => new { Year = g.Key.Year, Month = g.Key.Month, Count = g.Count() })
                .ToListAsync();

            return last12Months.Select(date => new ChartData
            {
                Label = date.ToString("MMM yyyy"),
                Value = views.FirstOrDefault(v => v.Year == date.Year && v.Month == date.Month)?.Count ?? 0,
                Color = "#4CAF50"
            }).Reverse().ToList();
        }

        private async Task<List<ChartData>> GetTopJobCategoriesForRecruiterAsync(string recruiterId)
        {
            return await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .GroupBy(j => j.Specialized)
                .Select(g => new ChartData
                {
                    Label = g.Key,
                    Value = g.Count(),
                    Color = "#FF9800"
                })
                .OrderByDescending(x => x.Value)
                .Take(10)
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetApplicationStatusDistributionForRecruiterAsync(string recruiterId)
        {
            var statuses = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .GroupBy(a => a.Status)
                .Select(g => new ChartData
                {
                    Label = g.Key.ToString(),
                    Value = g.Count(),
                    Color = g.Key == ApplicationStatus.Pending ? "#FFC107" :
                            g.Key == ApplicationStatus.Accepted ? "#4CAF50" : "#F44336"
                })
                .ToListAsync();

            return statuses;
        }

        private async Task<List<FollowerInfo>> GetRecentFollowersAsync(string recruiterId)
        {
            return await _context.Follows
                .Include(f => f.Follower)
                .Where(f => f.RecruiterId == recruiterId && f.IsActive)
                .OrderByDescending(f => f.CreatedAt)
                .Take(10)
                .Select(f => new FollowerInfo
                {
                    UserId = f.FollowerId,
                    UserName = f.Follower.FirstName + " " + f.Follower.LastName,
                    UserEmail = f.Follower.Email ?? "",
                    UserAvatar = f.Follower.Avatar,
                    FollowedDate = f.CreatedAt
                })
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetFollowerGrowthAsync(string recruiterId)
        {
            var last6Months = Enumerable.Range(0, 6).Select(i => DateTime.UtcNow.AddMonths(-i)).ToList();

            var followers = await _context.Follows
                .Where(f => f.RecruiterId == recruiterId && f.IsActive)
                .GroupBy(f => new { f.CreatedAt.Year, f.CreatedAt.Month })
                .Select(g => new { Year = g.Key.Year, Month = g.Key.Month, Count = g.Count() })
                .ToListAsync();

            return last6Months.Select(date => new ChartData
            {
                Label = date.ToString("MMM yyyy"),
                Value = followers.FirstOrDefault(f => f.Year == date.Year && f.Month == date.Month)?.Count ?? 0,
                Color = "#9C27B0"
            }).Reverse().ToList();
        }

        private async Task<List<CompanyReview>> GetRecruiterRecentReviewsAsync(string recruiterId)
        {
            return await _context.Reviews
                .Include(r => r.Reviewer)
                .Where(r => r.ReviewedUserId == recruiterId)
                .OrderByDescending(r => r.CreatedAt)
                .Take(5)
                .Select(r => new CompanyReview
                {
                    ReviewId = r.Id,
                    ReviewerName = r.Reviewer.FirstName + " " + r.Reviewer.LastName,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    ReviewDate = r.CreatedAt
                })
                .ToListAsync();
        }

        private async Task<decimal> GetRecruiterAverageRatingAsync(string recruiterId)
        {
            var ratings = await _context.Reviews
                .Where(r => r.ReviewedUserId == recruiterId)
                .Select(r => r.Rating)
                .ToListAsync();

            return ratings.Any() ? (decimal)ratings.Average() : 0;
        }

        private async Task<List<ChartData>> GetJobsByCategoryAsync(string recruiterId)
        {
            return await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .GroupBy(j => j.Specialized)
                .Select(g => new ChartData
                {
                    Label = g.Key,
                    Value = g.Count(),
                    Color = "#2196F3"
                })
                .OrderByDescending(x => x.Value)
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetJobsByLocationAsync(string recruiterId)
        {
            return await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .GroupBy(j => j.Location)
                .Select(g => new ChartData
                {
                    Label = g.Key,
                    Value = g.Count(),
                    Color = "#4CAF50"
                })
                .OrderByDescending(x => x.Value)
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetJobsByExperienceLevelAsync(string recruiterId)
        {
            return await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .GroupBy(j => j.ExperienceLevel)
                .Select(g => new ChartData
                {
                    Label = g.Key,
                    Value = g.Count(),
                    Color = "#FF5722"
                })
                .OrderByDescending(x => x.Value)
                .ToListAsync();
        }

        private async Task<List<ChartData>> GetSalaryDistributionAsync(string recruiterId)
        {
            var jobs = await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId && j.Salary > 0)
                .Select(j => j.Salary)
                .ToListAsync();

            if (!jobs.Any()) return new List<ChartData>();

            var ranges = new List<(string Label, decimal Min, decimal Max)>
            {
                ("Dưới 10 triệu", 0, 10000000),
                ("10-20 triệu", 10000000, 20000000),
                ("20-30 triệu", 20000000, 30000000),
                ("30-50 triệu", 30000000, 50000000),
                ("Trên 50 triệu", 50000000, decimal.MaxValue)
            };

            return ranges.Select(range => new ChartData
            {
                Label = range.Label,
                Value = jobs.Count(s => s >= range.Min && s < range.Max),
                Color = "#795548"
            }).Where(x => x.Value > 0).ToList();
        }

        private async Task<List<ChartData>> GetJobViewsByDayAsync(int jobId, int days)
        {
            var startDate = DateTime.UtcNow.AddDays(-days);
            var jobIdStr = jobId.ToString();

            var views = await _context.Analytics
                .Where(a => a.Type == "job_view" && a.TargetId == jobIdStr && a.CreatedAt >= startDate)
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToListAsync();

            var dateRange = Enumerable.Range(0, days).Select(i => DateTime.UtcNow.AddDays(-i).Date).ToList();

            return dateRange.Select(date => new ChartData
            {
                Label = date.ToString("dd/MM"),
                Value = views.FirstOrDefault(v => v.Date == date)?.Count ?? 0,
                Color = "#2196F3"
            }).Reverse().ToList();
        }

        private async Task<List<ChartData>> GetJobApplicationsByDayAsync(int jobId, int days)
        {
            var startDate = DateTime.UtcNow.AddDays(-days);

            var applications = await _context.Applications
                .Where(a => a.JobId == jobId && a.CreatedAt >= startDate)
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .ToListAsync();

            var dateRange = Enumerable.Range(0, days).Select(i => DateTime.UtcNow.AddDays(-i).Date).ToList();

            return dateRange.Select(date => new ChartData
            {
                Label = date.ToString("dd/MM"),
                Value = applications.FirstOrDefault(a => a.Date == date)?.Count ?? 0,
                Color = "#4CAF50"
            }).Reverse().ToList();
        }

        private async Task<List<ApplicantInfo>> GetJobRecentApplicantsAsync(int jobId)
        {
            return await _context.Applications
                .Include(a => a.Applicant)
                .Where(a => a.JobId == jobId && a.IsActive)
                .OrderByDescending(a => a.CreatedAt)
                .Take(10)
                .Select(a => new ApplicantInfo
                {
                    ApplicationId = a.Id,
                    UserId = a.ApplicantId,
                    UserName = a.Applicant.FirstName + " " + a.Applicant.LastName,
                    UserEmail = a.Applicant.Email ?? "",
                    UserAvatar = a.Applicant.Avatar,
                    ApplicationStatus = a.Status.ToString(),
                    AppliedDate = a.CreatedAt,
                    CvUrl = a.CvUrl,
                    CoverLetter = a.CoverLetter
                })
                .ToListAsync();
        }

        // Simplified methods for better performance in home screen
        private async Task<RecruiterAnalytics> GetRecruiterSimplifiedAnalyticsAsync(string recruiterId)
        {
            var now = DateTime.UtcNow;
            
            // Basic stats only - no detailed performance data
            var totalJobsPosted = await _context.JobPosts.CountAsync(j => j.RecruiterId == recruiterId);
            var activeJobs = await _context.JobPosts.CountAsync(j => j.RecruiterId == recruiterId && j.IsActive);
            var inactiveJobs = totalJobsPosted - activeJobs;

            var totalApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId)
                .CountAsync();

            var pendingApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Pending)
                .CountAsync();

            var acceptedApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Accepted)
                .CountAsync();

            var rejectedApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == recruiterId && a.Status == ApplicationStatus.Rejected)
                .CountAsync();

            // Simplified view analytics
            var jobIds = await _context.JobPosts
                .Where(j => j.RecruiterId == recruiterId)
                .Select(j => j.Id.ToString())
                .ToListAsync();

            var totalJobViews = await _context.Analytics
                .Where(a => a.Type == "job_view" && jobIds.Contains(a.TargetId!))
                .CountAsync();

            var uniqueJobViewers = await _context.Analytics
                .Where(a => a.Type == "job_view" && jobIds.Contains(a.TargetId!))
                .Select(a => a.UserId)
                .Distinct()
                .CountAsync();

            // Company followers
            var companyFollowers = await _context.Follows
                .CountAsync(f => f.RecruiterId == recruiterId && f.IsActive);

            // Calculate basic averages
            var averageApplicationsPerJob = totalJobsPosted > 0 ? (decimal)totalApplications / totalJobsPosted : 0;
            var averageViewsPerJob = totalJobsPosted > 0 ? (decimal)totalJobViews / totalJobsPosted : 0;
            var applicationToViewRatio = totalJobViews > 0 ? (decimal)totalApplications / totalJobViews : 0;

            return new RecruiterAnalytics
            {
                TotalJobsPosted = totalJobsPosted,
                ActiveJobs = activeJobs,
                InactiveJobs = inactiveJobs,
                TotalApplicationsReceived = totalApplications,
                PendingApplications = pendingApplications,
                AcceptedApplications = acceptedApplications,
                RejectedApplications = rejectedApplications,
                TotalJobViews = totalJobViews,
                UniqueJobViewers = uniqueJobViewers,
                CompanyFollowers = companyFollowers,
                AverageApplicationsPerJob = averageApplicationsPerJob,
                AverageViewsPerJob = averageViewsPerJob,
                ApplicationToViewRatio = applicationToViewRatio,
                JobPerformance = new List<JobDetailedPerformance>(), // Empty for simplified
                ApplicationsByMonth = new List<ChartData>(), // Empty for simplified
                ViewsByMonth = new List<ChartData>(), // Empty for simplified  
                TopJobCategories = new List<ChartData>(), // Empty for simplified
                ApplicationStatusDistribution = new List<ChartData>(), // Empty for simplified
                RecentFollowers = new List<FollowerInfo>() // Empty for simplified
            };
        }

        private async Task<JobAnalytics> GetJobSimplifiedAnalyticsAsync(string recruiterId)
        {
            // Get only basic stats for top 3 performing jobs
            var topJobs = await _context.JobPosts
                .Include(j => j.Applications)
                .Where(j => j.RecruiterId == recruiterId)
                .OrderByDescending(j => j.Applications.Count)
                .Take(3)
                .Select(j => new JobDetailedPerformance
                {
                    JobId = j.Id,
                    JobTitle = j.Title,
                    JobCategory = j.Specialized,
                    JobLocation = j.Location,
                    ExperienceLevel = j.ExperienceLevel,
                    Salary = j.Salary,
                    PostedDate = j.CreatedAt,
                    DeadLine = j.DeadLine,
                    IsActive = j.IsActive,
                    TotalViews = 0, // Skip for performance
                    UniqueViews = 0, // Skip for performance
                    TotalApplications = j.Applications.Count(a => a.IsActive),
                    PendingApplications = j.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Pending),
                    AcceptedApplications = j.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Accepted),
                    RejectedApplications = j.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Rejected),
                    ViewToApplicationRatio = 0, // Skip for performance
                    AcceptanceRate = j.Applications.Count(a => a.IsActive) > 0 ? 
                        (decimal)j.Applications.Count(a => a.IsActive && a.Status == ApplicationStatus.Accepted) / j.Applications.Count(a => a.IsActive) : 0,
                    FavoriteCount = 0, // Skip for performance
                    ViewsByDay = new List<ChartData>(), // Empty for simplified
                    ApplicationsByDay = new List<ChartData>(), // Empty for simplified
                    RecentApplicants = new List<ApplicantInfo>() // Empty for simplified
                })
                .ToListAsync();

            return new JobAnalytics
            {
                AllJobs = topJobs,
                BestPerformingJob = topJobs.FirstOrDefault(),
                MostViewedJob = topJobs.FirstOrDefault(),
                MostAppliedJob = topJobs.OrderByDescending(j => j.TotalApplications).FirstOrDefault()
            };
        }
    }
} 