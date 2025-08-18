using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class SearchHistory : BaseModel
    {
        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [StringLength(500)]
        public string SearchQuery { get; set; } = string.Empty;

        public string? SearchFilters { get; set; }

        public DateTime SearchTime { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }

    public class JobViewHistory : BaseModel
    {
        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public int JobId { get; set; }

        [Required]
        [StringLength(200)]
        public string JobTitle { get; set; } = string.Empty;

        public DateTime ViewedAt { get; set; } = DateTime.UtcNow;

        public int? ViewDurationSeconds { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [ForeignKey("JobId")]
        public virtual JobPost Job { get; set; } = null!;
    }

    public class ApplicationHistory : BaseModel
    {
        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public int JobId { get; set; }

        [Required]
        [StringLength(200)]
        public string JobTitle { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string ApplicationStatus { get; set; } = string.Empty;

        public DateTime AppliedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [ForeignKey("JobId")]
        public virtual JobPost Job { get; set; } = null!;
    }

    public class CVAnalysisResult : BaseModel
    {
        [Required]
        public int ApplicationId { get; set; }

        [Required]
        public int JobId { get; set; }

        [Required]
        public string CandidateId { get; set; } = string.Empty;

        [Range(0, 100)]
        public int MatchScore { get; set; }

        public string ExtractedSkills { get; set; } = string.Empty; // JSON string

        public string Strengths { get; set; } = string.Empty; // JSON string

        public string Weaknesses { get; set; } = string.Empty; // JSON string

        public string ImprovementSuggestions { get; set; } = string.Empty; // JSON string

        [Column(TypeName = "text")]
        public string DetailedAnalysis { get; set; } = string.Empty;

        public DateTime AnalyzedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("ApplicationId")]
        public virtual Application Application { get; set; } = null!;

        [ForeignKey("JobId")]
        public virtual JobPost Job { get; set; } = null!;

        [ForeignKey("CandidateId")]
        public virtual User Candidate { get; set; } = null!;
    }

    public class JobRecommendationLog : BaseModel
    {
        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public int JobId { get; set; }

        [Range(0, 100)]
        public int RecommendationScore { get; set; }

        public string RecommendationReason { get; set; } = string.Empty;

        public bool WasViewed { get; set; } = false;

        public bool WasApplied { get; set; } = false;

        public DateTime RecommendedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [ForeignKey("JobId")]
        public virtual JobPost Job { get; set; } = null!;
    }
}
