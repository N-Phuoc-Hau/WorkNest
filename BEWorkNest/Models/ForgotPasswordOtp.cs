using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models
{
    public class ForgotPasswordOtp : BaseModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [StringLength(6, MinimumLength = 6)]
        public string OtpCode { get; set; } = string.Empty;
        
        [Required]
        public DateTime ExpiresAt { get; set; }
        
        [Required]
        public bool IsUsed { get; set; } = false;
        
        // Optional: Track attempts to prevent brute force
        public int Attempts { get; set; } = 0;
        
        public bool IsValid => !IsUsed && DateTime.UtcNow <= ExpiresAt && Attempts < 3;
    }
}
