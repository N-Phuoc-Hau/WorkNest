using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Services
{
    public interface ISubscriptionService
    {
        Task<List<SubscriptionPlan>> GetAllPlans();
        Task<SubscriptionPlan?> GetPlanById(int id);
        Task<UserSubscription?> GetUserActiveSubscription(string userId);
        Task<bool> CheckFeatureAccess(string userId, string featureName);
        Task<FeatureUsage> TrackFeatureUsage(string userId, string featureName);
        Task<UserSubscription> CreateSubscription(string userId, int planId, int? paymentId = null);
        Task<bool> CancelSubscription(string userId, int subscriptionId);
        Task<FeatureUsage?> GetFeatureUsage(string userId, string featureName);
    }

    public class SubscriptionService : ISubscriptionService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<SubscriptionService> _logger;

        public SubscriptionService(ApplicationDbContext context, ILogger<SubscriptionService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<SubscriptionPlan>> GetAllPlans()
        {
            try
            {
                return await _context.SubscriptionPlans
                    .Include(p => p.Features)
                    .Where(p => p.IsActive)
                    .OrderBy(p => p.Price)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all subscription plans");
                throw;
            }
        }

        public async Task<SubscriptionPlan?> GetPlanById(int id)
        {
            try
            {
                return await _context.SubscriptionPlans
                    .Include(p => p.Features)
                    .FirstOrDefaultAsync(p => p.Id == id && p.IsActive);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting subscription plan {id}");
                throw;
            }
        }

        public async Task<UserSubscription?> GetUserActiveSubscription(string userId)
        {
            try
            {
                var subscription = await _context.UserSubscriptions
                    .Include(s => s.Plan)
                        .ThenInclude(p => p.Features)
                    .Where(s => s.UserId == userId && s.IsActive && s.EndDate > DateTime.UtcNow)
                    .OrderByDescending(s => s.EndDate)
                    .FirstOrDefaultAsync();

                if (subscription == null)
                {
                    _logger.LogInformation($"No active subscription found for user {userId}, returning Free plan");
                    
                    // Return Free plan as default
                    var freePlan = await _context.SubscriptionPlans
                        .Include(p => p.Features)
                        .FirstOrDefaultAsync(p => p.Name == "Free" && p.IsActive);

                    if (freePlan != null)
                    {
                        return new UserSubscription
                        {
                            UserId = userId,
                            SubscriptionPlanId = freePlan.Id,
                            Plan = freePlan,
                            StartDate = DateTime.UtcNow,
                            EndDate = DateTime.UtcNow.AddYears(1),
                            IsActive = true
                        };
                    }
                }

                return subscription;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting active subscription for user {userId}");
                throw;
            }
        }

        public async Task<bool> CheckFeatureAccess(string userId, string featureName)
        {
            try
            {
                var subscription = await GetUserActiveSubscription(userId);
                
                if (subscription?.Plan?.Features == null)
                {
                    _logger.LogWarning($"No subscription or features found for user {userId}");
                    return false;
                }

                var feature = subscription.Plan.Features
                    .FirstOrDefault(f => f.FeatureName == featureName);

                if (feature == null)
                {
                    _logger.LogInformation($"Feature {featureName} not found in plan {subscription.Plan.Name}");
                    return false;
                }

                // Check if feature is simply enabled (true/unlimited)
                if (feature.FeatureValue == "true" || feature.FeatureValue == "unlimited")
                {
                    return true;
                }

                // Check if feature is disabled
                if (feature.FeatureValue == "false")
                {
                    return false;
                }

                // Check if it's a countable feature with limits
                if (int.TryParse(feature.FeatureValue, out int limit))
                {
                    var usage = await GetOrCreateFeatureUsage(userId, featureName, limit);
                    return usage.UsageCount < usage.Limit;
                }

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking feature access for user {userId}, feature {featureName}");
                return false;
            }
        }

        public async Task<FeatureUsage> TrackFeatureUsage(string userId, string featureName)
        {
            try
            {
                var subscription = await GetUserActiveSubscription(userId);
                
                if (subscription?.Plan?.Features == null)
                {
                    throw new InvalidOperationException("No active subscription found");
                }

                var feature = subscription.Plan.Features
                    .FirstOrDefault(f => f.FeatureName == featureName);

                if (feature == null)
                {
                    throw new InvalidOperationException($"Feature {featureName} not found in plan");
                }

                // If feature is unlimited, don't track
                if (feature.FeatureValue == "unlimited")
                {
                    _logger.LogInformation($"Feature {featureName} is unlimited for user {userId}");
                    return new FeatureUsage
                    {
                        UserId = userId,
                        FeatureName = featureName,
                        UsageCount = 0,
                        Limit = int.MaxValue,
                        ResetDate = DateTime.UtcNow.AddMonths(1)
                    };
                }

                int limit = int.TryParse(feature.FeatureValue, out int l) ? l : 0;
                
                var usage = await GetOrCreateFeatureUsage(userId, featureName, limit);
                
                // Increment usage count
                usage.UsageCount++;
                usage.UpdatedAt = DateTime.UtcNow;
                
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Tracked feature usage for user {userId}, feature {featureName}: {usage.UsageCount}/{usage.Limit}");
                
                return usage;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error tracking feature usage for user {userId}, feature {featureName}");
                throw;
            }
        }

        public async Task<UserSubscription> CreateSubscription(string userId, int planId, int? paymentId = null)
        {
            try
            {
                var plan = await GetPlanById(planId);
                if (plan == null)
                {
                    throw new InvalidOperationException($"Subscription plan {planId} not found");
                }

                // Deactivate any existing active subscriptions
                var existingSubscriptions = await _context.UserSubscriptions
                    .Where(s => s.UserId == userId && s.IsActive)
                    .ToListAsync();

                foreach (var sub in existingSubscriptions)
                {
                    sub.IsActive = false;
                    sub.UpdatedAt = DateTime.UtcNow;
                }

                // Create new subscription
                var newSubscription = new UserSubscription
                {
                    UserId = userId,
                    SubscriptionPlanId = planId,
                    StartDate = DateTime.UtcNow,
                    EndDate = DateTime.UtcNow.AddDays(plan.DurationDays),
                    IsActive = true,
                    AutoRenew = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.UserSubscriptions.Add(newSubscription);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Created subscription {newSubscription.Id} for user {userId}, plan {plan.Name}");

                // Reload with plan details
                return await _context.UserSubscriptions
                    .Include(s => s.Plan)
                        .ThenInclude(p => p.Features)
                    .FirstAsync(s => s.Id == newSubscription.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating subscription for user {userId}, plan {planId}");
                throw;
            }
        }

        public async Task<bool> CancelSubscription(string userId, int subscriptionId)
        {
            try
            {
                var subscription = await _context.UserSubscriptions
                    .FirstOrDefaultAsync(s => s.Id == subscriptionId && s.UserId == userId);

                if (subscription == null)
                {
                    _logger.LogWarning($"Subscription {subscriptionId} not found for user {userId}");
                    return false;
                }

                subscription.IsActive = false;
                subscription.AutoRenew = false;
                subscription.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Cancelled subscription {subscriptionId} for user {userId}");

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error cancelling subscription {subscriptionId} for user {userId}");
                throw;
            }
        }

        public async Task<FeatureUsage?> GetFeatureUsage(string userId, string featureName)
        {
            try
            {
                return await _context.FeatureUsages
                    .FirstOrDefaultAsync(fu => fu.UserId == userId && fu.FeatureName == featureName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting feature usage for user {userId}, feature {featureName}");
                return null;
            }
        }

        private async Task<FeatureUsage> GetOrCreateFeatureUsage(string userId, string featureName, int limit)
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            var resetDate = startOfMonth.AddMonths(1);

            var usage = await _context.FeatureUsages
                .FirstOrDefaultAsync(u => u.UserId == userId && u.FeatureName == featureName);

            if (usage == null)
            {
                // Create new usage tracking
                usage = new FeatureUsage
                {
                    UserId = userId,
                    FeatureName = featureName,
                    UsageCount = 0,
                    Limit = limit,
                    ResetDate = resetDate,
                    CreatedAt = now,
                    UpdatedAt = now
                };
                
                _context.FeatureUsages.Add(usage);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Created new feature usage tracking for user {userId}, feature {featureName}");
            }
            else if (usage.ResetDate <= now)
            {
                // Reset usage for new period
                usage.UsageCount = 0;
                usage.ResetDate = resetDate;
                usage.Limit = limit;
                usage.UpdatedAt = now;
                
                await _context.SaveChangesAsync();
                
                _logger.LogInformation($"Reset feature usage for user {userId}, feature {featureName}");
            }

            return usage;
        }
    }
}
