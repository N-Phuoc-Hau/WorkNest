using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class CreateApplicationDto
    {
        [Required]
        public int JobId { get; set; }
        
        [Required]
        public string CoverLetter { get; set; } = string.Empty;
        
        [Required]
        public IFormFile CvFile { get; set; } = null!; // PDF file only
    }

    public class UpdateApplicationDto
    {
        public string? CoverLetter { get; set; }
        public IFormFile? CvFile { get; set; } // PDF file only (optional for update)
    }

    public class ApplicationDto
    {
        public int Id { get; set; }
        public string? CvUrl { get; set; }
        public string CoverLetter { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public UserDto Applicant { get; set; } = null!;
        public JobPostDto Job { get; set; } = null!;
    }

    public class UpdateApplicationStatusDto
    {
        [Required]
        public string Status { get; set; } = string.Empty;
    }
}
