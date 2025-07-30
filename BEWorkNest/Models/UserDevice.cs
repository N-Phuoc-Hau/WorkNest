using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class UserDevice
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        [Required]
        [MaxLength(500)]
        public string FcmToken { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string DeviceType { get; set; } = string.Empty; // "android", "ios", "web"
        
        [MaxLength(100)]
        public string? DeviceName { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime LastUsed { get; set; } = DateTime.UtcNow;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
