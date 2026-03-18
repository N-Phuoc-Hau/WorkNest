using System.Diagnostics;

namespace BEWorkNest.Middleware;

public class RequestMetricsMiddleware
{
    private readonly RequestDelegate _next;
    private static long _totalRequests = 0;
    private static long _successfulRequests = 0;
    private static long _failedRequests = 0;
    private static readonly List<long> _responseTimes = new();
    private static readonly object _lock = new();

    public RequestMetricsMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        Interlocked.Increment(ref _totalRequests);
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await _next(context);

            if (context.Response.StatusCode < 400)
            {
                Interlocked.Increment(ref _successfulRequests);
            }
            else
            {
                Interlocked.Increment(ref _failedRequests);
            }
        }
        catch
        {
            Interlocked.Increment(ref _failedRequests);
            throw;
        }
        finally
        {
            stopwatch.Stop();

            lock (_lock)
            {
                _responseTimes.Add(stopwatch.ElapsedMilliseconds);
                
                // Keep only last 1000 response times
                if (_responseTimes.Count > 1000)
                {
                    _responseTimes.RemoveAt(0);
                }
            }
        }
    }

    public static RequestMetrics GetMetrics()
    {
        lock (_lock)
        {
            var sortedTimes = _responseTimes.OrderBy(x => x).ToList();
            
            return new RequestMetrics
            {
                TotalRequests = _totalRequests,
                SuccessfulRequests = _successfulRequests,
                FailedRequests = _failedRequests,
                SuccessRate = _totalRequests > 0 ? (_successfulRequests * 100.0 / _totalRequests) : 0,
                AverageResponseTime = sortedTimes.Any() ? sortedTimes.Average() : 0,
                MedianResponseTime = sortedTimes.Any() ? GetPercentile(sortedTimes, 50) : 0,
                P95ResponseTime = sortedTimes.Any() ? GetPercentile(sortedTimes, 95) : 0,
                P99ResponseTime = sortedTimes.Any() ? GetPercentile(sortedTimes, 99) : 0,
                SampleSize = sortedTimes.Count
            };
        }
    }

    private static long GetPercentile(List<long> sortedValues, int percentile)
    {
        if (!sortedValues.Any()) return 0;
        
        int index = (int)Math.Ceiling(percentile / 100.0 * sortedValues.Count) - 1;
        index = Math.Max(0, Math.Min(sortedValues.Count - 1, index));
        
        return sortedValues[index];
    }

    public static void Reset()
    {
        lock (_lock)
        {
            _totalRequests = 0;
            _successfulRequests = 0;
            _failedRequests = 0;
            _responseTimes.Clear();
        }
    }
}

public class RequestMetrics
{
    public long TotalRequests { get; set; }
    public long SuccessfulRequests { get; set; }
    public long FailedRequests { get; set; }
    public double SuccessRate { get; set; }
    public double AverageResponseTime { get; set; }
    public long MedianResponseTime { get; set; }
    public long P95ResponseTime { get; set; }
    public long P99ResponseTime { get; set; }
    public int SampleSize { get; set; }
}
