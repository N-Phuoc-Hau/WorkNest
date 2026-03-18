using BEWorkNest.Models;
using BEWorkNest.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class SubscriptionController : ControllerBase
    {
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<SubscriptionController> _logger;
        private readonly Services.JwtService _jwtService;

        public SubscriptionController(
            ISubscriptionService subscriptionService,
            ILogger<SubscriptionController> logger,
            Services.JwtService jwtService)
        {
            _subscriptionService = subscriptionService;
            _logger = logger;
            _jwtService = jwtService;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // If not found from claims, try to extract from Authorization header
            if (string.IsNullOrEmpty(userId) && Request.Headers.ContainsKey("Authorization"))
            {
                var authHeader = Request.Headers["Authorization"].FirstOrDefault();
                if (authHeader != null && authHeader.StartsWith("Bearer "))
                {
                    var token = authHeader.Substring("Bearer ".Length).Trim();
                    if (!string.IsNullOrEmpty(token))
                    {
                        try
                        {
                            userId = _jwtService.GetUserIdFromToken(token);
                            userRole = _jwtService.GetRoleFromToken(token);
                            isAuthenticated = !string.IsNullOrEmpty(userId);
                        }
                        catch (Exception)
                        {
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        /// <summary>
        /// Get all available subscription plans
        /// </summary>
        [HttpGet("plans")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<List<SubscriptionPlanDto>>>> GetPlans()
        {
            try
            {
                var plans = await _subscriptionService.GetAllPlans();
                
                var planDtos = plans.Select(p => new SubscriptionPlanDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    Description = p.Description,
                    Price = p.Price,
                    DurationDays = p.DurationDays,
                    Features = p.Features?.Select(f => new SubscriptionFeatureDto
                    {
                        FeatureName = f.FeatureName,
                        FeatureValue = f.FeatureValue
                    }).ToList() ?? new List<SubscriptionFeatureDto>()
                }).ToList();

                return Ok(new ApiResponse<List<SubscriptionPlanDto>>
                {
                    Success = true,
                    Message = "Subscription plans retrieved successfully",
                    Data = planDtos
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting subscription plans");
                return StatusCode(500, new ApiResponse<List<SubscriptionPlanDto>>
                {
                    Success = false,
                    Message = "Error retrieving subscription plans"
                });
            }
        }

        /// <summary>
        /// Get current user's active subscription
        /// </summary>
        [HttpGet("my-subscription")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<UserSubscriptionDto>>> GetMySubscription()
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new ApiResponse<UserSubscriptionDto>
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn",
                        Data = null
                    });
                }

                var subscription = await _subscriptionService.GetUserActiveSubscription(userId);

                if (subscription == null)
                {
                    return Ok(new ApiResponse<UserSubscriptionDto>
                    {
                        Success = true,
                        Message = "No active subscription found",
                        Data = null
                    });
                }

                var subscriptionDto = new UserSubscriptionDto
                {
                    Id = subscription.Id,
                    PlanName = subscription.Plan?.Name ?? "",
                    PlanDescription = subscription.Plan?.Description,
                    StartDate = subscription.StartDate,
                    EndDate = subscription.EndDate,
                    IsActive = subscription.IsActive,
                    AutoRenew = subscription.AutoRenew,
                    Features = subscription.Plan?.Features?.Select(f => new SubscriptionFeatureDto
                    {
                        FeatureName = f.FeatureName,
                        FeatureValue = f.FeatureValue
                    }).ToList() ?? new List<SubscriptionFeatureDto>()
                };

                return Ok(new ApiResponse<UserSubscriptionDto>
                {
                    Success = true,
                    Message = "Subscription retrieved successfully",
                    Data = subscriptionDto
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user subscription");
                return StatusCode(500, new ApiResponse<UserSubscriptionDto>
                {
                    Success = false,
                    Message = "Error retrieving subscription"
                });
            }
        }

        /// <summary>
        /// Check if user has access to a specific feature
        /// </summary>
        [HttpGet("check-feature/{featureName}")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<FeatureAccessDto>>> CheckFeatureAccess(string featureName)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new ApiResponse<FeatureAccessDto>
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn",
                        Data = null
                    });
                }

                var hasAccess = await _subscriptionService.CheckFeatureAccess(userId, featureName);
                
                var usage = await _subscriptionService.GetFeatureUsage(userId, featureName);

                var accessDto = new FeatureAccessDto
                {
                    FeatureName = featureName,
                    HasAccess = hasAccess,
                    UsageCount = usage?.UsageCount ?? 0,
                    Limit = usage?.Limit ?? 0,
                    ResetDate = usage?.ResetDate
                };

                return Ok(new ApiResponse<FeatureAccessDto>
                {
                    Success = true,
                    Message = hasAccess ? "Feature access granted" : "Feature access denied",
                    Data = accessDto
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking feature access for {featureName}");
                return StatusCode(500, new ApiResponse<FeatureAccessDto>
                {
                    Success = false,
                    Message = "Error checking feature access"
                });
            }
        }

        /// <summary>
        /// Cancel current subscription
        /// </summary>
        [HttpPost("cancel/{subscriptionId}")]
        [AllowAnonymous]
        public async Task<ActionResult<ApiResponse<bool>>> CancelSubscription(int subscriptionId)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new ApiResponse<bool>
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn",
                        Data = false
                    });
                }

                var success = await _subscriptionService.CancelSubscription(userId, subscriptionId);

                return Ok(new ApiResponse<bool>
                {
                    Success = success,
                    Message = success ? "Subscription cancelled successfully" : "Failed to cancel subscription",
                    Data = success
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error cancelling subscription {subscriptionId}");
                return StatusCode(500, new ApiResponse<bool>
                {
                    Success = false,
                    Message = "Error cancelling subscription"
                });
            }
        }
    }

    // DTOs
    public class SubscriptionPlanDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public int DurationDays { get; set; }
        public List<SubscriptionFeatureDto> Features { get; set; } = new();
    }

    public class SubscriptionFeatureDto
    {
        public string FeatureName { get; set; } = "";
        public string FeatureValue { get; set; } = "";
    }

    public class UserSubscriptionDto
    {
        public int Id { get; set; }
        public string PlanName { get; set; } = "";
        public string? PlanDescription { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; }
        public bool AutoRenew { get; set; }
        public List<SubscriptionFeatureDto> Features { get; set; } = new();
    }

    public class FeatureAccessDto
    {
        public string FeatureName { get; set; } = "";
        public bool HasAccess { get; set; }
        public int UsageCount { get; set; }
        public int Limit { get; set; }
        public DateTime? ResetDate { get; set; }
    }

    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = "";
        public T? Data { get; set; }
    }
}
