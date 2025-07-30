using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty; // "job_posted", "application_status", "follow_notification"
        
        public bool IsRead { get; set; } = false;
        
        public string? RelatedEntityId { get; set; } // JobId, CompanyId, etc.
        
        public string? ActionUrl { get; set; } // Deep link for mobile/web
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
