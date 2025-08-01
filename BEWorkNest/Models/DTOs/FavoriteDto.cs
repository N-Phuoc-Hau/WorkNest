using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class FavoriteJobDto
    {
        public int Id { get; set; }
        public int JobId { get; set; }
        public string JobTitle { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string Salary { get; set; } = string.Empty;
        public string JobType { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime JobPostedAt { get; set; }
        public bool IsActive { get; set; }
    }

    public class AddFavoriteDto
    {
        [Required]
        public int JobId { get; set; }
    }
}
