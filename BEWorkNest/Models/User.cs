using Microsoft.AspNetCore.Identity;

namespace BEWorkNest.Models
{
    public class User : IdentityUser
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Role { get; set; } = "candidate"; // candidate, recruiter, admin
        public string? Avatar { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;
        
        // Navigation properties
        public UserProfile? UserProfile { get; set; }

        // Navigation properties
        public Company? Company { get; set; }
        public ICollection<JobPost> JobPosts { get; set; } = new List<JobPost>();
        public ICollection<Application> Applications { get; set; } = new List<Application>();
        public ICollection<Follow> Following { get; set; } = new List<Follow>();
        public ICollection<Follow> Followers { get; set; } = new List<Follow>();
        public ICollection<Review> GivenReviews { get; set; } = new List<Review>();
        public ICollection<Review> ReceivedReviews { get; set; } = new List<Review>();
        public ICollection<FavoriteJob> FavoriteJobs { get; set; } = new List<FavoriteJob>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<UserDevice> UserDevices { get; set; } = new List<UserDevice>();
    }
}
