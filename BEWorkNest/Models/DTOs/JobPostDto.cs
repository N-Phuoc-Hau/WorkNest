using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class JobPostDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Specialized { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Requirements { get; set; } = string.Empty;
        public string Benefits { get; set; } = string.Empty;
        public decimal Salary { get; set; }
        public string WorkingHours { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string JobType { get; set; } = string.Empty;
        public string ExperienceLevel { get; set; } = string.Empty;
        public DateTime DeadLine { get; set; }
        public DateTime CreatedAt { get; set; }
        public UserDto Recruiter { get; set; } = null!;
        public int ApplicationCount { get; set; }
    }

    public class CreateJobPostDto
    {
        [Required]
        public string Title { get; set; } = string.Empty;
        
        public string Specialized { get; set; } = "Chưa phân loại";
        
        [Required]
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public string Requirements { get; set; } = string.Empty;
        
        [Required]
        public string Benefits { get; set; } = string.Empty;
        
        [Required]
        public decimal Salary { get; set; }
        
        [Required]
        public string WorkingHours { get; set; } = string.Empty;
        
        [Required]
        public string Location { get; set; } = string.Empty;
        
        [Required]
        public string JobType { get; set; } = "Full-time";
        
        [Required]
        public string ExperienceLevel { get; set; } = "Entry Level";
        
        [Required]
        public DateTime DeadLine { get; set; }
    }

    public class UpdateJobPostDto
    {
        public string? Title { get; set; }
        public string? Specialized { get; set; }
        public string? Description { get; set; }
        public string? Requirements { get; set; }
        public string? Benefits { get; set; }
        public decimal? Salary { get; set; }
        public string? WorkingHours { get; set; }
        public string? Location { get; set; }
        public string? JobType { get; set; }
        public string? ExperienceLevel { get; set; }
        public DateTime? DeadLine { get; set; }
    }
}
