using BEWorkNest.Data;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Models;
using BEWorkNest.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class FavoriteController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        
        public FavoriteController(ApplicationDbContext context)
        {
            _context = context;
        }
        
        [HttpPost("{jobId}")]
        [AllowAnonymous]
        public async Task<IActionResult> AddToFavorite(int jobId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            // Check if job exists
            var job = await _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .FirstOrDefaultAsync(j => j.Id == jobId);
            
            if (job == null || job.Recruiter.Company == null)
            {
                return NotFound(new { message = "Job not found" });
            }
            
            // Check if already favorited
            var existingFavorite = await _context.FavoriteJobs
                .FirstOrDefaultAsync(f => f.UserId == userId && f.JobId == jobId);
            
            if (existingFavorite != null)
            {
                return BadRequest(new { message = "Job is already in favorites" });
            }
            
            // Add to favorites
            var favorite = new FavoriteJob
            {
                UserId = userId ?? string.Empty,
                JobId = jobId,
                CreatedAt = DateTime.UtcNow
            };
            
            _context.FavoriteJobs.Add(favorite);
            await _context.SaveChangesAsync();
            
            return Ok(new { message = "Job added to favorites successfully" });
        }
        
        [HttpDelete("{jobId}")]
        [AllowAnonymous]
        public async Task<IActionResult> RemoveFromFavorite(int jobId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var favorite = await _context.FavoriteJobs
                .FirstOrDefaultAsync(f => f.UserId == userId && f.JobId == jobId);
            
            if (favorite == null)
            {
                return NotFound(new { message = "Favorite not found" });
            }
            
            _context.FavoriteJobs.Remove(favorite);
            await _context.SaveChangesAsync();
            
            return Ok(new { message = "Job removed from favorites successfully" });
        }
        
        [HttpGet("my-favorites")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyFavorites([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var favorites = await _context.FavoriteJobs
                .Where(f => f.UserId == userId)
                .Include(f => f.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .OrderByDescending(f => f.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
            
            var favoriteJobs = favorites.Select(f => new FavoriteJobDto
            {
                Id = f.Id,
                JobId = f.Job.Id,
                JobTitle = f.Job.Title,
                CompanyName = f.Job.Recruiter.Company?.Name ?? "Unknown Company",
                Location = f.Job.Location,
                Salary = f.Job.Salary.ToString(),
                JobType = f.Job.JobType,
                CreatedAt = f.CreatedAt,
                JobPostedAt = f.Job.CreatedAt,
                IsActive = f.Job.IsActive
            }).ToList();
            
            var totalFavorites = await _context.FavoriteJobs
                .CountAsync(f => f.UserId == userId);
            
            return Ok(new
            {
                favorites = favoriteJobs,
                totalCount = totalFavorites,
                currentPage = page,
                pageSize = pageSize,
                totalPages = (int)Math.Ceiling((double)totalFavorites / pageSize)
            });
        }
        
        [HttpGet("check/{jobId}")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckFavoriteStatus(int jobId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var isFavorited = await _context.FavoriteJobs
                .AnyAsync(f => f.UserId == userId && f.JobId == jobId);
            
            return Ok(new { isFavorited });
        }
        
        [HttpGet("stats")]
        [AllowAnonymous]
        public async Task<IActionResult> GetFavoriteStats()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var totalFavorites = await _context.FavoriteJobs
                .CountAsync(f => f.UserId == userId);
            
            var activeFavorites = await _context.FavoriteJobs
                .Where(f => f.UserId == userId)
                .Include(f => f.Job)
                .CountAsync(f => f.Job.IsActive);
            
            var recentFavorites = await _context.FavoriteJobs
                .Where(f => f.UserId == userId && f.CreatedAt >= DateTime.UtcNow.AddDays(-7))
                .CountAsync();
            
            return Ok(new
            {
                totalFavorites,
                activeFavorites,
                recentFavorites
            });
        }
    }
}
