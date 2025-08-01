using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class CreateFollowDto
    {
        [Required]
        public int CompanyId { get; set; }
    }

    public class FollowDto
    {
        public int Id { get; set; }
        public UserDto Follower { get; set; } = null!;
        public UserDto Recruiter { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }
}
