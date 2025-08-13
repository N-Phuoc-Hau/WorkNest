using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class CreateChatRoomDto
    {
        [Required]
        public string RecruiterId { get; set; } = string.Empty;
        
        [Required]
        public string CandidateId { get; set; } = string.Empty;
        
        public string? JobId { get; set; }
        
        public Dictionary<string, object>? RecruiterInfo { get; set; }
        public Dictionary<string, object>? CandidateInfo { get; set; }
        public Dictionary<string, object>? JobInfo { get; set; }
    }

    public class SendTextMessageDto
    {
        [Required]
        public string RoomId { get; set; } = string.Empty;
        
        [Required]
        public string Content { get; set; } = string.Empty;
    }

    public class SendImageMessageDto
    {
        [Required]
        public string RoomId { get; set; } = string.Empty;
        
        [Required]
        public IFormFile ImageFile { get; set; } = null!;
        
        public string? Caption { get; set; }
    }

    public class ChatMessageDto
    {
        public string Id { get; set; } = string.Empty;
        public string SenderId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string MessageType { get; set; } = "text";
        public DateTime Timestamp { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsRead { get; set; }
        public Dictionary<string, object>? SenderInfo { get; set; }
    }

    public class ChatRoomDto
    {
        public string Id { get; set; } = string.Empty;
        public string RecruiterId { get; set; } = string.Empty;
        public string CandidateId { get; set; } = string.Empty;
        public string? JobId { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public string? LastMessage { get; set; }
        public Dictionary<string, object>? RecruiterInfo { get; set; }
        public Dictionary<string, object>? CandidateInfo { get; set; }
        public Dictionary<string, object>? JobInfo { get; set; }
        public int UnreadCount { get; set; }
    }
}
