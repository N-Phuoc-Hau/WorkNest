using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class Follow
    {
        [Key]
        public int Id { get; set; }
        public string FollowerId { get; set; } = string.Empty;
        public string RecruiterId { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;

        // Navigation properties
        [ForeignKey("FollowerId")]
        public User Follower { get; set; } = null!;
        
        [ForeignKey("RecruiterId")]
        public User Recruiter { get; set; } = null!;
    }
}
