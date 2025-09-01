using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models
{
    public class Analytics
    {
        [Key]
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // job_view, application, search, etc.
        public string Action { get; set; } = string.Empty; // view, apply, search, etc.
        public string? TargetId { get; set; } // job_id, user_id, etc.
        public string? Metadata { get; set; } // JSON data
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation property
        public User User { get; set; } = null!;
    }

    public class DashboardStats
    {
        public int TotalJobs { get; set; }
        public int ActiveJobs { get; set; }
        public int TotalApplications { get; set; }
        public int PendingApplications { get; set; }
        public int ApprovedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public int TotalUsers { get; set; }
        public int NewUsersThisMonth { get; set; }
        public decimal AverageSalary { get; set; }
        public List<ChartData> JobViewsByDay { get; set; } = new List<ChartData>();
        public List<ChartData> ApplicationsByDay { get; set; } = new List<ChartData>();
        public List<ChartData> TopJobCategories { get; set; } = new List<ChartData>();
        public List<ChartData> TopLocations { get; set; } = new List<ChartData>();
    }

    public class ChartData
    {
        public string Label { get; set; } = string.Empty;
        public double Value { get; set; }
        public string? Color { get; set; }
    }

    public class RecruiterDashboard
    {
        public int TotalJobPosts { get; set; }
        public int ActiveJobPosts { get; set; }
        public int TotalApplications { get; set; }
        public int PendingApplications { get; set; }
        public int ApprovedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public int TotalViews { get; set; }
        public int ViewsThisMonth { get; set; }
        public List<JobPerformance> TopPerformingJobs { get; set; } = new List<JobPerformance>();
        public List<ApplicationTrend> ApplicationTrends { get; set; } = new List<ApplicationTrend>();
        public List<ChartData> ApplicationsByStatus { get; set; } = new List<ChartData>();
        public List<ChartData> ViewsByDay { get; set; } = new List<ChartData>();
    }

    public class CandidateDashboard
    {
        public int TotalApplications { get; set; }
        public int PendingApplications { get; set; }
        public int ApprovedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public int SavedJobs { get; set; }
        public int FollowedCompanies { get; set; }
        public List<ApplicationStatusInfo> RecentApplications { get; set; } = new List<ApplicationStatusInfo>();
        public List<ChartData> ApplicationStatusDistribution { get; set; } = new List<ChartData>();
        public List<ChartData> ApplicationsByMonth { get; set; } = new List<ChartData>();
    }

    public class JobPerformance
    {
        public int JobId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public int Views { get; set; }
        public int Applications { get; set; }
        public double ConversionRate { get; set; }
        public DateTime PostedDate { get; set; }
    }

    public class ApplicationTrend
    {
        public DateTime Date { get; set; }
        public int Applications { get; set; }
        public int Views { get; set; }
    }

    public class ApplicationStatusInfo
    {
        public int ApplicationId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime AppliedDate { get; set; }
        public DateTime? UpdatedDate { get; set; }
    }

    // Advanced Analytics Models
    public class DetailedAnalytics
    {
        public RecruiterAnalytics Recruiter { get; set; } = new RecruiterAnalytics();
        public CompanyAnalytics Company { get; set; } = new CompanyAnalytics();
        public JobAnalytics Jobs { get; set; } = new JobAnalytics();
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    }

    public class RecruiterAnalytics
    {
        public int TotalJobsPosted { get; set; }
        public int ActiveJobs { get; set; }
        public int InactiveJobs { get; set; }
        public int TotalApplicationsReceived { get; set; }
        public int PendingApplications { get; set; }
        public int AcceptedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public int TotalJobViews { get; set; }
        public int UniqueJobViewers { get; set; }
        public int CompanyFollowers { get; set; }
        public decimal AverageApplicationsPerJob { get; set; }
        public decimal AverageViewsPerJob { get; set; }
        public decimal ApplicationToViewRatio { get; set; }
        public List<JobDetailedPerformance> JobPerformance { get; set; } = new List<JobDetailedPerformance>();
        public List<ChartData> ApplicationsByMonth { get; set; } = new List<ChartData>();
        public List<ChartData> ViewsByMonth { get; set; } = new List<ChartData>();
        public List<ChartData> TopJobCategories { get; set; } = new List<ChartData>();
        public List<ChartData> ApplicationStatusDistribution { get; set; } = new List<ChartData>();
        public List<FollowerInfo> RecentFollowers { get; set; } = new List<FollowerInfo>();
    }

    public class CompanyAnalytics
    {
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = string.Empty;
        public string CompanyLocation { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public int TotalFollowers { get; set; }
        public int NewFollowersThisMonth { get; set; }
        public int TotalJobsPosted { get; set; }
        public int TotalApplicationsReceived { get; set; }
        public DateTime CompanyCreatedAt { get; set; }
        public List<ChartData> FollowerGrowth { get; set; } = new List<ChartData>();
        public List<CompanyReview> RecentReviews { get; set; } = new List<CompanyReview>();
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
    }

    public class JobAnalytics
    {
        public List<JobDetailedPerformance> AllJobs { get; set; } = new List<JobDetailedPerformance>();
        public JobDetailedPerformance? BestPerformingJob { get; set; }
        public JobDetailedPerformance? MostViewedJob { get; set; }
        public JobDetailedPerformance? MostAppliedJob { get; set; }
        public List<ChartData> JobsByCategory { get; set; } = new List<ChartData>();
        public List<ChartData> JobsByLocation { get; set; } = new List<ChartData>();
        public List<ChartData> JobsByExperienceLevel { get; set; } = new List<ChartData>();
        public List<ChartData> SalaryDistribution { get; set; } = new List<ChartData>();
    }

    public class JobDetailedPerformance
    {
        public int JobId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public string JobCategory { get; set; } = string.Empty;
        public string JobLocation { get; set; } = string.Empty;
        public string ExperienceLevel { get; set; } = string.Empty;
        public decimal Salary { get; set; }
        public DateTime PostedDate { get; set; }
        public DateTime? DeadLine { get; set; }
        public bool IsActive { get; set; }
        public int TotalViews { get; set; }
        public int UniqueViews { get; set; }
        public int TotalApplications { get; set; }
        public int PendingApplications { get; set; }
        public int AcceptedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public decimal ViewToApplicationRatio { get; set; }
        public decimal AcceptanceRate { get; set; }
        public int FavoriteCount { get; set; }
        public List<ChartData> ViewsByDay { get; set; } = new List<ChartData>();
        public List<ChartData> ApplicationsByDay { get; set; } = new List<ChartData>();
        public List<ApplicantInfo> RecentApplicants { get; set; } = new List<ApplicantInfo>();
    }

    public class FollowerInfo
    {
        public string UserId { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public string? UserAvatar { get; set; }
        public DateTime FollowedDate { get; set; }
    }

    public class ApplicantInfo
    {
        public int ApplicationId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public string? UserAvatar { get; set; }
        public string ApplicationStatus { get; set; } = string.Empty;
        public DateTime AppliedDate { get; set; }
        public string? CvUrl { get; set; }
        public string? CoverLetter { get; set; }
    }

    public class CompanyReview
    {
        public int ReviewId { get; set; }
        public string ReviewerName { get; set; } = string.Empty;
        public decimal Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
        public DateTime ReviewDate { get; set; }
    }

    // Excel Export Models
    public class ExcelExportData
    {
        public List<JobExportData> Jobs { get; set; } = new List<JobExportData>();
        public List<ApplicationExportData> Applications { get; set; } = new List<ApplicationExportData>();
        public List<FollowerExportData> Followers { get; set; } = new List<FollowerExportData>();
        public List<AnalyticsExportData> Analytics { get; set; } = new List<AnalyticsExportData>();
    }

    public class JobExportData
    {
        public int JobId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public decimal Salary { get; set; }
        public string ExperienceLevel { get; set; } = string.Empty;
        public DateTime PostedDate { get; set; }
        public DateTime? DeadLine { get; set; }
        public bool IsActive { get; set; }
        public int TotalViews { get; set; }
        public int TotalApplications { get; set; }
        public int PendingApplications { get; set; }
        public int AcceptedApplications { get; set; }
        public int RejectedApplications { get; set; }
        public decimal ConversionRate { get; set; }
    }

    public class ApplicationExportData
    {
        public int ApplicationId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public string ApplicantName { get; set; } = string.Empty;
        public string ApplicantEmail { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime AppliedDate { get; set; }
        public DateTime? UpdatedDate { get; set; }
        public string? CoverLetter { get; set; }
    }

    public class FollowerExportData
    {
        public string FollowerName { get; set; } = string.Empty;
        public string FollowerEmail { get; set; } = string.Empty;
        public DateTime FollowedDate { get; set; }
        public bool IsActive { get; set; }
    }

    public class AnalyticsExportData
    {
        public DateTime Date { get; set; }
        public string EventType { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public string? TargetId { get; set; }
        public string? Metadata { get; set; }
        public int Count { get; set; }
    }
} 