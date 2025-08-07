using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class RegisterDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string Role { get; set; } = "candidate"; // candidate, recruiter, admin
        
        public string? Avatar { get; set; }
    }

    public class RegisterFormDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string Role { get; set; } = "candidate"; // candidate, recruiter, admin
        
        public IFormFile? Avatar { get; set; }
        
        // Alternative: accept avatar URL if file is not provided
        public string? AvatarUrl { get; set; }
    }

    public class LoginDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class LoginResponseDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime AccessTokenExpiresAt { get; set; }
        public DateTime RefreshTokenExpiresAt { get; set; }
        public UserDto User { get; set; } = null!;
    }

    public class RefreshTokenDto
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }

    public class RefreshTokenResponseDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime AccessTokenExpiresAt { get; set; }
        public DateTime RefreshTokenExpiresAt { get; set; }
    }

    public class RevokeTokenDto
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }

    public class RegisterRecruiterFormDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string CompanyName { get; set; } = string.Empty;
        
        [Required]
        public string TaxCode { get; set; } = string.Empty;
        
        [Required]
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public string Location { get; set; } = string.Empty;
        
        public IFormFile? Avatar { get; set; }
        
        // Alternative: accept avatar URL if file is not provided
        public string? AvatarUrl { get; set; }
        
        [Required]
        public List<IFormFile> Images { get; set; } = new List<IFormFile>();
        
        // Alternative: accept image URLs if files are not provided
        public List<string>? ImageUrls { get; set; }
    }
}
