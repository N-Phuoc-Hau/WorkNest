using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace BEWorkNest.Models
{
    // Subscription Plan (Gói thành viên)
    public class SubscriptionPlan
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty; // Free, Basic, Pro, Enterprise
        
        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        
        public int DurationDays { get; set; } // 30, 90, 365
        
        [MaxLength(10)]
        public string Currency { get; set; } = "VND";
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual ICollection<SubscriptionFeature> Features { get; set; } = new List<SubscriptionFeature>();
        public virtual ICollection<UserSubscription> Subscriptions { get; set; } = new List<UserSubscription>();
    }

    // Features in each plan
    public class SubscriptionFeature
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public int SubscriptionPlanId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string FeatureName { get; set; } = string.Empty; // "unlimited_applications", "cv_builder", "video_call"
        
        [MaxLength(100)]
        public string FeatureValue { get; set; } = string.Empty; // "true", "5", "unlimited"
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("SubscriptionPlanId")]
        public virtual SubscriptionPlan SubscriptionPlan { get; set; } = null!;
    }

    // User's subscription
    public class UserSubscription
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        [Required]
        public int SubscriptionPlanId { get; set; }
        
        public DateTime StartDate { get; set; } = DateTime.UtcNow;
        
        public DateTime EndDate { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public bool AutoRenew { get; set; } = false;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
        
        [ForeignKey("SubscriptionPlanId")]
        public virtual SubscriptionPlan Plan { get; set; } = null!;
        
        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
    }

    // Payment transactions
    public class Payment
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        public int? UserSubscriptionId { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }
        
        [MaxLength(10)]
        public string Currency { get; set; } = "VND";
        
        [Required]
        [MaxLength(50)]
        public string PaymentMethod { get; set; } = string.Empty; // VNPay, Momo, ZaloPay, BankTransfer
        
        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Pending"; // Pending, Success, Failed, Refunded
        
        [MaxLength(200)]
        public string? TransactionId { get; set; } // From payment gateway
        
        [MaxLength(50)]
        public string? ResponseCode { get; set; } // Response code from payment gateway
        
        [MaxLength(45)]
        public string? IpAddress { get; set; } // IP address of the user
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? PaidAt { get; set; }
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [Column(TypeName = "text")]
        public string? PaymentGatewayResponse { get; set; } // JSON response
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
        
        [ForeignKey("UserSubscriptionId")]
        public virtual UserSubscription? UserSubscription { get; set; }
    }

    // Feature Usage Tracking
    public class FeatureUsage
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string FeatureName { get; set; } = string.Empty;
        
        public int UsageCount { get; set; } = 0;
        
        public int Limit { get; set; }
        
        public DateTime ResetDate { get; set; } // Monthly reset
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;
    }

    // Payment Gateway Config (Optional - có thể lưu trong appsettings)
    public class PaymentGatewayConfig
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Gateway { get; set; } = string.Empty; // VNPay, Momo, ZaloPay
        
        [MaxLength(500)]
        public string ApiUrl { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string MerchantId { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string SecretKey { get; set; } = string.Empty;
        
        public bool IsActive { get; set; } = true;
        
        [MaxLength(50)]
        public string Environment { get; set; } = "Sandbox"; // Sandbox, Production
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
