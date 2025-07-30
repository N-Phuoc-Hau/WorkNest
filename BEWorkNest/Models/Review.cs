using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class Review
    {
        [Key]
        public int Id { get; set; }
        public string ReviewerId { get; set; } = string.Empty;
        public string ReviewedUserId { get; set; } = string.Empty;
        public int Rating { get; set; } // 1-5
        public string Comment { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        // Navigation properties
        [ForeignKey("ReviewerId")]
        public User Reviewer { get; set; } = null!;
        
        [ForeignKey("ReviewedUserId")]
        public User ReviewedUser { get; set; } = null!;
    }
}
