using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models
{
    public class RefreshToken
    {
        [Key]
        public string Token { get; set; } = string.Empty;
        
        public string UserId { get; set; } = string.Empty;
        
        public DateTime ExpiresAt { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public bool IsRevoked { get; set; } = false;
        
        public string? RevokedBy { get; set; }
        
        public DateTime? RevokedAt { get; set; }
        
        public string? ReplacedByToken { get; set; }
        
        public string? ReasonRevoked { get; set; }
        
        // Navigation property
        public User User { get; set; } = null!;
    }
} 