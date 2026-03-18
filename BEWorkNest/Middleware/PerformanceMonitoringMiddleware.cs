using System.Diagnostics;
using System.Text;

namespace BEWorkNest.Middleware;

public class PerformanceMonitoringMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceMonitoringMiddleware> _logger;

    public PerformanceMonitoringMiddleware(RequestDelegate next, ILogger<PerformanceMonitoringMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var requestId = Guid.NewGuid().ToString("N");
        
        context.Items["RequestId"] = requestId;
        
        // Set headers BEFORE response starts using OnStarting callback
        context.Response.OnStarting(() =>
        {
            context.Response.Headers["X-Request-Id"] = requestId;
            context.Response.Headers["X-Response-Time-Ms"] = stopwatch.ElapsedMilliseconds.ToString();
            return Task.CompletedTask;
        });

        // Log request
        var requestInfo = new StringBuilder();
        requestInfo.AppendLine($"[{requestId}] Request Started:");
        requestInfo.AppendLine($"  Method: {context.Request.Method}");
        requestInfo.AppendLine($"  Path: {context.Request.Path}");
        requestInfo.AppendLine($"  QueryString: {context.Request.QueryString}");
        requestInfo.AppendLine($"  Time: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss.fff}");
        
        _logger.LogInformation(requestInfo.ToString());

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            
            // Log response
            var responseInfo = new StringBuilder();
            responseInfo.AppendLine($"[{requestId}] Request Completed:");
            responseInfo.AppendLine($"  Status: {context.Response.StatusCode}");
            responseInfo.AppendLine($"  Duration: {stopwatch.ElapsedMilliseconds}ms");
            
            if (stopwatch.ElapsedMilliseconds > 1000)
            {
                _logger.LogWarning(responseInfo.ToString());
                _logger.LogWarning($"[{requestId}] SLOW REQUEST DETECTED: {context.Request.Method} {context.Request.Path} took {stopwatch.ElapsedMilliseconds}ms");
            }
            else if (stopwatch.ElapsedMilliseconds > 500)
            {
                _logger.LogWarning(responseInfo.ToString());
            }
            else
            {
                _logger.LogInformation(responseInfo.ToString());
            }
        }
    }
}
