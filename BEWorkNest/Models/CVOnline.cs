using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace BEWorkNest.Models
{
    /// <summary>
    /// CV Online Profile - User creates CV directly on platform
    /// </summary>
    public class CVOnlineProfile
    {
        [Key]
        public int Id { get; set; }

        // UserId is set by controller from JWT token, not from request body
        public string UserId { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty; // "Software Engineer CV", "My Resume 2024"

        // Personal Information
        [Required]
        [StringLength(100)]
        public string FullName { get; set; } = string.Empty;

        [StringLength(200)]
        public string? Email { get; set; }

        [StringLength(20)]
        public string? Phone { get; set; }

        [StringLength(500)]
        public string? Address { get; set; }

        [StringLength(100)]
        public string? City { get; set; }

        [StringLength(100)]
        public string? Country { get; set; }

        [StringLength(500)]
        public string? Website { get; set; }

        [StringLength(500)]
        public string? LinkedIn { get; set; }

        [StringLength(500)]
        public string? GitHub { get; set; }

        [StringLength(500)]
        public string? Portfolio { get; set; }

        public string? ProfilePhotoUrl { get; set; }

        // Professional Summary
        [Column(TypeName = "text")]
        public string? Summary { get; set; }

        [StringLength(200)]
        public string? CurrentPosition { get; set; }

        public int? YearsOfExperience { get; set; }

        // Template & Styling
        public int? TemplateId { get; set; } // Reference to CV template

        [StringLength(50)]
        public string? Theme { get; set; } = "default"; // "modern", "classic", "creative"

        [StringLength(20)]
        public string? PrimaryColor { get; set; } = "#3B82F6";

        [StringLength(20)]
        public string? SecondaryColor { get; set; } = "#1F2937";

        // Settings
        public bool IsPublic { get; set; } = false; // Public CV can be shared via link

        [StringLength(50)]
        public string? PublicSlug { get; set; } // Unique URL slug for public access

        public bool IsDefault { get; set; } = false; // Default CV for applications

        public bool ShowPhoto { get; set; } = true;

        public bool ShowContactInfo { get; set; } = true;

        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastPublishedAt { get; set; }

        public int ViewCount { get; set; } = 0; // For public CVs

        public int DownloadCount { get; set; } = 0;

        // Navigation Properties
        [ForeignKey("UserId")]
        [JsonIgnore]
        public virtual User? User { get; set; }

        [ForeignKey("TemplateId")]
        [JsonIgnore]
        public virtual CVTemplate? Template { get; set; }

        public virtual ICollection<CVWorkExperience> WorkExperiences { get; set; } = new List<CVWorkExperience>();

        public virtual ICollection<CVEducation> Educations { get; set; } = new List<CVEducation>();

        public virtual ICollection<CVSkill> Skills { get; set; } = new List<CVSkill>();

        public virtual ICollection<CVProject> Projects { get; set; } = new List<CVProject>();

        public virtual ICollection<CVCertification> Certifications { get; set; } = new List<CVCertification>();

        public virtual ICollection<CVLanguage> Languages { get; set; } = new List<CVLanguage>();

        public virtual ICollection<CVReference> References { get; set; } = new List<CVReference>();
    }

    /// <summary>
    /// CV Template - Pre-designed CV templates
    /// </summary>
    public class CVTemplate
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty; // "Modern Professional", "Classic ATS"

        [StringLength(500)]
        public string? Description { get; set; }

        public string? ThumbnailUrl { get; set; }

        public string? PreviewUrl { get; set; }

        [StringLength(50)]
        public string Category { get; set; } = "general"; // "tech", "creative", "business"

        public bool IsPremium { get; set; } = false; // Requires subscription

        public bool IsActive { get; set; } = true;

        public int UsageCount { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Template configuration (JSON)
        [Column(TypeName = "text")]
        public string? LayoutConfig { get; set; }

        public virtual ICollection<CVOnlineProfile> CVProfiles { get; set; } = new List<CVOnlineProfile>();
    }

    /// <summary>
    /// Work Experience Entry
    /// </summary>
    public class CVWorkExperience
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(200)]
        public string JobTitle { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Company { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Location { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool IsCurrentJob { get; set; } = false;

        [Column(TypeName = "text")]
        public string? Description { get; set; }

        [Column(TypeName = "text")]
        public string? Achievements { get; set; } // JSON array of strings

        [Column(TypeName = "text")]
        public string? Technologies { get; set; } // JSON array of tech used

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Education Entry
    /// </summary>
    public class CVEducation
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(200)]
        public string Degree { get; set; } = string.Empty; // "Bachelor of Computer Science"

        [Required]
        [StringLength(200)]
        public string Institution { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Location { get; set; }

        [StringLength(50)]
        public string? GPA { get; set; }

        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        public bool IsCurrentlyStudying { get; set; } = false;

        [Column(TypeName = "text")]
        public string? Description { get; set; }

        [Column(TypeName = "text")]
        public string? Courses { get; set; } // JSON array of relevant courses

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Skill Entry
    /// </summary>
    public class CVSkill
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(50)]
        public string? Category { get; set; } // "Programming", "Design", "Soft Skills"

        public int? ProficiencyLevel { get; set; } // 1-5 or 1-100

        public int? YearsOfExperience { get; set; }

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Project Entry
    /// </summary>
    public class CVProject
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Link { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Column(TypeName = "text")]
        public string? Description { get; set; }

        [Column(TypeName = "text")]
        public string? Technologies { get; set; } // JSON array

        [Column(TypeName = "text")]
        public string? Achievements { get; set; } // JSON array

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Certification Entry
    /// </summary>
    public class CVCertification
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [StringLength(200)]
        public string? IssuingOrganization { get; set; }

        public DateTime? IssueDate { get; set; }

        public DateTime? ExpiryDate { get; set; }

        [StringLength(100)]
        public string? CredentialId { get; set; }

        [StringLength(500)]
        public string? CredentialUrl { get; set; }

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Language Entry
    /// </summary>
    public class CVLanguage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(50)]
        public string? ProficiencyLevel { get; set; } // "Native", "Fluent", "Intermediate", "Basic"

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }

    /// <summary>
    /// Reference Entry
    /// </summary>
    public class CVReference
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CVProfileId { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(100)]
        public string? Position { get; set; }

        [StringLength(100)]
        public string? Company { get; set; }

        [StringLength(200)]
        public string? Email { get; set; }

        [StringLength(20)]
        public string? Phone { get; set; }

        public int DisplayOrder { get; set; } = 0;

        [ForeignKey("CVProfileId")]
        [JsonIgnore]
        public virtual CVOnlineProfile? CVProfile { get; set; }
    }
}
