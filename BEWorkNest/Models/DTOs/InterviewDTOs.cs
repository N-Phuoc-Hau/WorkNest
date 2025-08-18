using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class CreateInterviewDto
    {
        [Required(ErrorMessage = "Application ID is required")]
        public int ApplicationId { get; set; }

        [Required(ErrorMessage = "Scheduled time is required")]
        public DateTime ScheduledTime { get; set; }

        public int Duration { get; set; } = 60; // Default 60 minutes

        public string? Location { get; set; }

        public string? MeetingLink { get; set; }

        public string? Notes { get; set; }
    }

    public class UpdateInterviewStatusDto
    {
        [Required(ErrorMessage = "Status is required")]
        public string Status { get; set; } = string.Empty;

        public string? Notes { get; set; }
    }

    public class InterviewDto
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public string CandidateId { get; set; } = string.Empty;
        public string RecruiterId { get; set; } = string.Empty;
        public int JobId { get; set; }
        public string CandidateName { get; set; } = string.Empty;
        public string RecruiterName { get; set; } = string.Empty;
        public string JobTitle { get; set; } = string.Empty;
        public DateTime ScheduledTime { get; set; }
        public int Duration { get; set; }
        public string? Location { get; set; }
        public string? MeetingLink { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class ScheduleInterviewRequestDto
    {
        [Required]
        public int ApplicationId { get; set; }

        [Required]
        public DateTime ScheduledTime { get; set; }

        [Range(15, 480, ErrorMessage = "Duration must be between 15 and 480 minutes")]
        public int Duration { get; set; } = 60;

        [MaxLength(500)]
        public string? Location { get; set; }

        [Url(ErrorMessage = "Meeting link must be a valid URL")]
        public string? MeetingLink { get; set; }

        [MaxLength(1000)]
        public string? Notes { get; set; }
    }
}
