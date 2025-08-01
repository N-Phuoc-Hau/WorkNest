using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Services;
using BEWorkNest.Models;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class DashboardController : ControllerBase
    {
        private readonly AnalyticsService _analyticsService;
        private readonly ILogger<DashboardController> _logger;

        public DashboardController(
            AnalyticsService analyticsService,
            ILogger<DashboardController> logger)
        {
            _analyticsService = analyticsService;
            _logger = logger;
        }

        [HttpGet("admin")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAdminDashboard()
        {
            try
            {
                var stats = await _analyticsService.GetAdminDashboardStatsAsync();
                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting admin dashboard");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("recruiter")]
        [AllowAnonymous]
        public async Task<IActionResult> GetRecruiterDashboard()
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var dashboard = await _analyticsService.GetRecruiterDashboardAsync(userId);
                return Ok(dashboard);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting recruiter dashboard");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("candidate")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCandidateDashboard()
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                var dashboard = await _analyticsService.GetCandidateDashboardAsync(userId);
                return Ok(dashboard);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate dashboard");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpPost("track")]
        public async Task<IActionResult> TrackEvent([FromBody] TrackEventDto trackEventDto)
        {
            try
            {
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (userId == null)
                {
                    return Unauthorized();
                }

                await _analyticsService.TrackEventAsync(
                    userId,
                    trackEventDto.Type,
                    trackEventDto.Action,
                    trackEventDto.TargetId,
                    trackEventDto.Metadata
                );

                return Ok(new { message = "Event tracked successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking event");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }
    }

    public class TrackEventDto
    {
        public string Type { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty;
        public string? TargetId { get; set; }
        public string? Metadata { get; set; }
    }
} 