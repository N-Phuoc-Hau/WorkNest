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
} 