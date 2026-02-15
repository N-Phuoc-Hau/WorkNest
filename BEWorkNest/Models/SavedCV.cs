using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class SavedCV
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        [Required]
        public string FilePath { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string FileName { get; set; } = string.Empty;

        [StringLength(10)]
        public string FileExtension { get; set; } = string.Empty;

        public long FileSize { get; set; }

        [Column(TypeName = "text")]
        public string? ExtractedText { get; set; }

        // Skills and profile data extracted from CV
        [Column(TypeName = "text")]
        public string? Skills { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? WorkExperience { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? Education { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? Projects { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? Certifications { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? Languages { get; set; } // JSON array

        public int? ExperienceYears { get; set; }

        public string? CurrentPosition { get; set; }

        public bool IsDefault { get; set; } = false;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Analysis data from AI
        public int? OverallScore { get; set; }

        [Column(TypeName = "text")]
        public string? AnalysisResult { get; set; } // JSON from last analysis

        public DateTime? LastAnalyzedAt { get; set; }

        // Usage tracking
        public int UsageCount { get; set; } = 0;

        public DateTime? LastUsedAt { get; set; }

        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        public virtual ICollection<Application> Applications { get; set; } = new List<Application>();
    }
}