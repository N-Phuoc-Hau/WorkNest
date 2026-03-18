using Microsoft.Extensions.Caching.Memory;
using System.Collections.Concurrent;

namespace BEWorkNest.Middleware;

public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    private readonly ILogger<RateLimitingMiddleware> _logger;
    private static readonly ConcurrentDictionary<string, int> _requestCounts = new();

    // Configuration - Increased for load testing scenarios
    // For production, consider lowering these or using distributed rate limiting
    private const int MaxRequestsPerMinute = 300;      // Was 60 - increased for load testing
    private const int MaxRequestsPer10Seconds = 100;   // Was 20 - increased for load testing

    public RateLimitingMiddleware(RequestDelegate next, IMemoryCache cache, ILogger<RateLimitingMiddleware> logger)
    {
        _next = next;
        _cache = cache;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientId = GetClientId(context);
        var endpoint = $"{context.Request.Method}:{context.Request.Path}";
        
        // Skip rate limiting for specific endpoints
        if (context.Request.Path.StartsWithSegments("/health") || 
            context.Request.Path.StartsWithSegments("/swagger") ||
            context.Request.Path.StartsWithSegments("/api/metrics"))
        {
            await _next(context);
            return;
        }

        // Check rate limits
        if (!await IsRequestAllowed(clientId, endpoint))
        {
            _logger.LogWarning($"Rate limit exceeded for client {clientId} on endpoint {endpoint}");
            
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            context.Response.Headers["Retry-After"] = "60";
            
            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                message = "Too many requests. Please try again later.",
                retryAfter = 60
            });
            
            return;
        }

        await _next(context);
    }

    private string GetClientId(HttpContext context)
    {
        // Try to get user ID from claims
        var userId = context.User?.Identity?.Name;
        if (!string.IsNullOrEmpty(userId))
            return userId;

        // Fallback to IP address
        var ipAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return ipAddress;
    }

    private async Task<bool> IsRequestAllowed(string clientId, string endpoint)
    {
        var cacheKey = $"ratelimit:{clientId}:{endpoint}";
        var minute = DateTime.UtcNow.ToString("yyyyMMddHHmm");
        var tenSecondWindow = DateTime.UtcNow.ToString("yyyyMMddHHmmss").Substring(0, 14) + "0"; // Round to 10s

        var minuteKey = $"{cacheKey}:minute:{minute}";
        var tenSecKey = $"{cacheKey}:10s:{tenSecondWindow}";

        // Check 10-second window
        var tenSecCount = _cache.GetOrCreate(tenSecKey, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(15);
            entry.Size = 1; // Required when SizeLimit is set
            return 0;
        });

        if (tenSecCount >= MaxRequestsPer10Seconds)
            return false;

        // Check 1-minute window
        var minuteCount = _cache.GetOrCreate(minuteKey, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(2);
            entry.Size = 1; // Required when SizeLimit is set
            return 0;
        });

        if (minuteCount >= MaxRequestsPerMinute)
            return false;

        // Increment counters
        var tenSecOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(15),
            Size = 1 // Required when SizeLimit is set
        };
        
        var minuteOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(2),
            Size = 1 // Required when SizeLimit is set
        };

        _cache.Set(tenSecKey, tenSecCount + 1, tenSecOptions);
        _cache.Set(minuteKey, minuteCount + 1, minuteOptions);

        return true;
    }
}
