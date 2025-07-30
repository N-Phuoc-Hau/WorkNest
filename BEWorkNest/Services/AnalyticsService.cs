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
    }
} 