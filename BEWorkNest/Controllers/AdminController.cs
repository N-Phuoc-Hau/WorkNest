using BEWorkNest.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BEWorkNest.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<AdminController> _logger;

        public AdminController(ApplicationDbContext context, ILogger<AdminController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Seed subscription plans and features
        /// WARNING: Only run this once to initialize the database
        /// </summary>
        [HttpPost("seed-subscription-plans")]
        [AllowAnonymous] // Change to [Authorize(Roles = "Admin")] in production
        public IActionResult SeedSubscriptionPlans()
        {
            try
            {
                PaymentSeeder.SeedSubscriptionPlans(_context);
                
                _logger.LogInformation("Subscription plans and features seeded successfully");
                
                return Ok(new
                {
                    success = true,
                    message = "Subscription plans and features seeded successfully",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding subscription plans");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Error seeding subscription plans: " + ex.Message
                });
            }
        }

        /// <summary>
        /// Get system health information
        /// </summary>
        [HttpGet("health")]
        [AllowAnonymous]
        public IActionResult GetHealth()
        {
            return Ok(new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                version = "1.0.0",
                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"
            });
        }
    }
}
