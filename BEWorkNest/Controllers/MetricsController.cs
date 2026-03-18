using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Middleware;
using System.Diagnostics;

namespace BEWorkNest.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MetricsController : ControllerBase
{
    private readonly ILogger<MetricsController> _logger;

    public MetricsController(ILogger<MetricsController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get real-time performance metrics
    /// </summary>
    [HttpGet]
    public IActionResult GetMetrics()
    {
        var metrics = RequestMetricsMiddleware.GetMetrics();
        var process = Process.GetCurrentProcess();

        return Ok(new
        {
            timestamp = DateTime.UtcNow,
            uptime = DateTime.UtcNow - Process.GetCurrentProcess().StartTime.ToUniversalTime(),
            request_metrics = metrics,
            system_metrics = new
            {
                memory_mb = process.WorkingSet64 / 1024 / 1024,
                cpu_time_seconds = process.TotalProcessorTime.TotalSeconds,
                thread_count = process.Threads.Count,
                handle_count = process.HandleCount
            }
        });
    }

    /// <summary>
    /// Get health status with detailed metrics
    /// </summary>
    [HttpGet("health")]
    public IActionResult GetHealthWithMetrics()
    {
        var metrics = RequestMetricsMiddleware.GetMetrics();
        var isHealthy = metrics.SuccessRate > 95 && metrics.P95ResponseTime < 1000;

        return Ok(new
        {
            status = isHealthy ? "healthy" : "degraded",
            timestamp = DateTime.UtcNow,
            checks = new
            {
                success_rate = new
                {
                    value = metrics.SuccessRate,
                    threshold = 95.0,
                    status = metrics.SuccessRate > 95 ? "pass" : "fail"
                },
                p95_latency = new
                {
                    value_ms = metrics.P95ResponseTime,
                    threshold_ms = 1000,
                    status = metrics.P95ResponseTime < 1000 ? "pass" : "warn"
                },
                total_requests = metrics.TotalRequests
            }
        });
    }

    /// <summary>
    /// Reset metrics (for testing purposes)
    /// </summary>
    [HttpPost("reset")]
    public IActionResult ResetMetrics()
    {
        RequestMetricsMiddleware.Reset();
        _logger.LogInformation("Metrics have been reset");
        
        return Ok(new
        {
            message = "Metrics reset successfully",
            timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Prometheus-compatible metrics endpoint
    /// </summary>
    [HttpGet("prometheus")]
    [Produces("text/plain")]
    public IActionResult GetPrometheusMetrics()
    {
        var metrics = RequestMetricsMiddleware.GetMetrics();
        var process = Process.GetCurrentProcess();

        var prometheusOutput = $@"# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total {metrics.TotalRequests}

# HELP http_requests_successful Total number of successful HTTP requests
# TYPE http_requests_successful counter
http_requests_successful {metrics.SuccessfulRequests}

# HELP http_requests_failed Total number of failed HTTP requests
# TYPE http_requests_failed counter
http_requests_failed {metrics.FailedRequests}

# HELP http_request_duration_ms HTTP request latencies in milliseconds
# TYPE http_request_duration_ms summary
http_request_duration_ms{{quantile=""0.5""}} {metrics.MedianResponseTime}
http_request_duration_ms{{quantile=""0.95""}} {metrics.P95ResponseTime}
http_request_duration_ms{{quantile=""0.99""}} {metrics.P99ResponseTime}
http_request_duration_ms_sum {metrics.AverageResponseTime * metrics.TotalRequests}
http_request_duration_ms_count {metrics.TotalRequests}

# HELP process_memory_bytes Process memory usage in bytes
# TYPE process_memory_bytes gauge
process_memory_bytes {process.WorkingSet64}

# HELP process_cpu_seconds_total Total CPU time consumed
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total {process.TotalProcessorTime.TotalSeconds}
";

        return Content(prometheusOutput, "text/plain");
    }
}
