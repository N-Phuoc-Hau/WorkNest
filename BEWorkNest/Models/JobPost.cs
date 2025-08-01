using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class JobPost
    {
        [Key]
        public int Id { get; set; }
        public string RecruiterId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Specialized { get; set; } = "Chưa phân loại";
        public string Description { get; set; } = string.Empty;
        public string Requirements { get; set; } = string.Empty;
        public string Benefits { get; set; } = string.Empty;
        public decimal Salary { get; set; }

        public string WorkingHours { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string JobType { get; set; } = "Full-time";
        public string ExperienceLevel { get; set; } = "Entry Level";
        public DateTime DeadLine { get; set; } = DateTime.UtcNow.AddDays(30);
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        // Navigation properties
        [ForeignKey("RecruiterId")]
        public User Recruiter { get; set; } = null!;
        public ICollection<Application> Applications { get; set; } = new List<Application>();
        public ICollection<FavoriteJob> FavoriteJobs { get; set; } = new List<FavoriteJob>();
    }
}
