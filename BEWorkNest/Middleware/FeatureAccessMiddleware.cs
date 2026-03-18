using BEWorkNest.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;

namespace BEWorkNest.Middleware
{
    /// <summary>
    /// Attribute to require specific subscription feature access
    /// </summary>
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class, AllowMultiple = false)]
    public class RequireFeatureAttribute : Attribute, IAsyncActionFilter
    {
        public string FeatureName { get; }
        public bool TrackUsage { get; }

        public RequireFeatureAttribute(string featureName, bool trackUsage = true)
        {
            FeatureName = featureName;
            TrackUsage = trackUsage;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var subscriptionService = context.HttpContext.RequestServices.GetService<ISubscriptionService>();
            var logger = context.HttpContext.RequestServices.GetService<ILogger<RequireFeatureAttribute>>();

            if (subscriptionService == null)
            {
                logger?.LogError("ISubscriptionService not found in DI container");
                context.Result = new StatusCodeResult(500);
                return;
            }

            var userId = context.HttpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                logger?.LogWarning("User ID not found in claims");
                context.Result = new UnauthorizedObjectResult(new
                {
                    success = false,
                    message = "User not authenticated"
                });
                return;
            }

            try
            {
                // Check feature access
                var hasAccess = await subscriptionService.CheckFeatureAccess(userId, FeatureName);

                if (!hasAccess)
                {
                    logger?.LogWarning($"User {userId} does not have access to feature {FeatureName}");
                    
                    var usage = await subscriptionService.GetFeatureUsage(userId, FeatureName);
                    
                    context.Result = new ObjectResult(new
                    {
                        success = false,
                        message = $"You don't have access to this feature. Please upgrade your subscription.",
                        featureName = FeatureName,
                        usageCount = usage?.UsageCount ?? 0,
                        limit = usage?.Limit ?? 0,
                        upgradeRequired = true
                    })
                    {
                        StatusCode = 403
                    };
                    return;
                }

                // Track usage if enabled
                if (TrackUsage)
                {
                    await subscriptionService.TrackFeatureUsage(userId, FeatureName);
                }

                // Allow the action to execute
                await next();
            }
            catch (Exception ex)
            {
                logger?.LogError(ex, $"Error checking feature access for {FeatureName}");
                context.Result = new StatusCodeResult(500);
            }
        }
    }

    /// <summary>
    /// Middleware to add subscription info to HTTP context
    /// </summary>
    public class SubscriptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<SubscriptionMiddleware> _logger;

        public SubscriptionMiddleware(RequestDelegate next, ILogger<SubscriptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context, ISubscriptionService subscriptionService)
        {
            if (context.User.Identity?.IsAuthenticated == true)
            {
                var userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);
                
                if (!string.IsNullOrEmpty(userId))
                {
                    try
                    {
                        var subscription = await subscriptionService.GetUserActiveSubscription(userId);
                        
                        if (subscription != null)
                        {
                            // Add subscription info to HttpContext.Items for easy access
                            context.Items["UserSubscription"] = subscription;
                            context.Items["SubscriptionPlan"] = subscription.Plan?.Name ?? "Free";
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error loading subscription for user {userId}");
                    }
                }
            }

            await _next(context);
        }
    }

    /// <summary>
    /// Extension methods for middleware registration
    /// </summary>
    public static class SubscriptionMiddlewareExtensions
    {
        public static IApplicationBuilder UseSubscriptionMiddleware(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<SubscriptionMiddleware>();
        }
    }
}
