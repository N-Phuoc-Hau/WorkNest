using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
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
        [Required]
        public int NotificationId { get; set; }
    }

    public class DeviceTokenDto
    {
        [Required]
        public string FcmToken { get; set; } = string.Empty;

        [Required]
        public string DeviceType { get; set; } = string.Empty; // "android", "ios", "web"

        public string? DeviceName { get; set; }
    }
}
