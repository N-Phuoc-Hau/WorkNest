using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class ReviewDto
    {
        public int Id { get; set; }
        public UserDto Reviewer { get; set; } = null!;
        public UserDto ReviewedUser { get; set; } = null!;
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    public class CreateReviewDto
    {
        [Required]
        [Range(1, 5, ErrorMessage = "Rating phải từ 1 đến 5")]
        public int Rating { get; set; }
        
        [Required]
        public string Comment { get; set; } = string.Empty;
    }

    public class CreateCandidateReviewDto : CreateReviewDto
    {
        [Required]
        public int CompanyId { get; set; }
    }

    public class CreateRecruiterReviewDto : CreateReviewDto
    {
        [Required]
        public string CandidateId { get; set; } = string.Empty;
    }

    public class FollowDto
    {
        public int Id { get; set; }
        public UserDto Follower { get; set; } = null!;
        public UserDto Recruiter { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }

    public class CreateFollowDto
    {
        [Required]
        public int CompanyId { get; set; }
    }
}
