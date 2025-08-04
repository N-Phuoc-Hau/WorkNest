using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class UserProfileDto
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string? Position { get; set; }
        public string? Experience { get; set; }
        public string? Education { get; set; }
        public string? Skills { get; set; }
        public string? Bio { get; set; }
        public string? Address { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? PhoneNumber { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateUserProfileDto
    {
        public string? Position { get; set; }
        public string? Experience { get; set; }
        public string? Education { get; set; }
        public string? Skills { get; set; }
        public string? Bio { get; set; }
        public string? Address { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? PhoneNumber { get; set; }
    }

    public class UpdateUserProfileDto
    {
        public string? Position { get; set; }
        public string? Experience { get; set; }
        public string? Education { get; set; }
        public string? Skills { get; set; }
        public string? Bio { get; set; }
        public string? Address { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? PhoneNumber { get; set; }
    }
} 