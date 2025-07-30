using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class Application
    {
        [Key]
        public int Id { get; set; }
        public string ApplicantId { get; set; } = string.Empty;
        public int JobId { get; set; }
        public string? CvUrl { get; set; }
        public string CoverLetter { get; set; } = string.Empty;
        public ApplicationStatus Status { get; set; } = ApplicationStatus.Pending;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        // Navigation properties
        [ForeignKey("ApplicantId")]
        public User Applicant { get; set; } = null!;
        
        [ForeignKey("JobId")]
        public JobPost Job { get; set; } = null!;
    }
}
