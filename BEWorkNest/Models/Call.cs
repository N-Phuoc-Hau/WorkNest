using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    public class Call
    {
        [Key]
        public string CallId { get; set; } = Guid.NewGuid().ToString();

        [Required]
        public string InitiatorId { get; set; } = string.Empty;

        [ForeignKey("InitiatorId")]
        public virtual User? Initiator { get; set; }

        [Required]
        public string ReceiverId { get; set; } = string.Empty;

        [ForeignKey("ReceiverId")]
        public virtual User? Receiver { get; set; }

        [Required]
        public string CallType { get; set; } = "audio"; // audio or video

        [Required]
        public string Status { get; set; } = "initiated"; // initiated, ringing, active, ended, rejected, missed

        public DateTime InitiatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? StartedAt { get; set; }

        public DateTime? EndedAt { get; set; }

        public int? Duration { get; set; } // Duration in seconds

        public string? EndReason { get; set; } // ended_by_initiator, ended_by_receiver, rejected, missed, error

        public string? RoomId { get; set; } // SignalR room ID

        public string? IceServers { get; set; } // JSON string of ICE servers configuration
    }
}
