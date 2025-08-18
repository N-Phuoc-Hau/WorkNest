using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public enum InterviewStatus
    {
        Scheduled,
        InProgress,
        Completed,
        Cancelled,
        Rescheduled
    }

    public class Interview
    {
        [Key]
        public int Id { get; set; }

        public int ApplicationId { get; set; }
        public string CandidateId { get; set; } = string.Empty;
        public string RecruiterId { get; set; } = string.Empty;
        public int JobId { get; set; }

        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime ScheduledAt { get; set; }
        public string? MeetingLink { get; set; }
        public string? Location { get; set; }
        public InterviewStatus Status { get; set; } = InterviewStatus.Scheduled;
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("ApplicationId")]
        public Application Application { get; set; } = null!;

        [ForeignKey("CandidateId")]
        public User Candidate { get; set; } = null!;

        [ForeignKey("RecruiterId")]
        public User Recruiter { get; set; } = null!;

        [ForeignKey("JobId")]
        public JobPost Job { get; set; } = null!;
    }
}
