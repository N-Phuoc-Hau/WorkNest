namespace BEWorkNest.DTOs
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
        public int JobId { get; set; }
    }

    public class NotificationDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public string? RelatedEntityId { get; set; }
        public string? ActionUrl { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class MarkNotificationReadDto
    {
        public int NotificationId { get; set; }
    }

    public class DeviceTokenDto
    {
        public string FcmToken { get; set; } = string.Empty;
        public string DeviceType { get; set; } = string.Empty; // "android", "ios", "web"
        public string? DeviceName { get; set; }
    }

    public class CreateFollowDto
    {
        public int CompanyId { get; set; }
    }

    public class FollowDto
    {
        public int Id { get; set; }
        public UserDto Follower { get; set; } = null!;
        public UserDto Recruiter { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
    }

    public class UserDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string? Avatar { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public CompanyDto? Company { get; set; }
    }

    public class CompanyDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string TaxCode { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<string> Images { get; set; } = new List<string>();
    }
}
