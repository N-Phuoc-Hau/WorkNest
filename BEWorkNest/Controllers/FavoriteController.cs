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
        private readonly JwtService _jwtService;
        
        public FavoriteController(ApplicationDbContext context, JwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
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
        
        [HttpPost("{jobId}")]
        [Authorize]
        public async Task<IActionResult> AddToFavorite(int jobId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                // Check if job exists
                var job = await _context.JobPosts
                    .Include(j => j.Recruiter)
                    .ThenInclude(r => r.Company)
                    .FirstOrDefaultAsync(j => j.Id == jobId && j.IsActive);
                
                if (job == null || job.Recruiter.Company == null)
                {
                    return NotFound(new { 
                        message = "Không tìm thấy công việc",
                        errorCode = "JOB_NOT_FOUND"
                    });
                }
                
                // Check if already favorited
                var existingFavorite = await _context.FavoriteJobs
                    .FirstOrDefaultAsync(f => f.UserId == userId && f.JobId == jobId);
                
                if (existingFavorite != null)
                {
                    return BadRequest(new { 
                        message = "Công việc đã được thêm vào yêu thích",
                        errorCode = "ALREADY_FAVORITED"
                    });
                }

                // Add to favorites
                var favorite = new FavoriteJob
                {
                    UserId = userId,
                    JobId = jobId,
                    CreatedAt = DateTime.Now
                };
                
                _context.FavoriteJobs.Add(favorite);
                await _context.SaveChangesAsync();
                
                return Ok(new { 
                    message = "Thêm công việc vào yêu thích thành công",
                    data = new {
                        favoriteId = favorite.Id,
                        jobId = jobId,
                        jobTitle = job.Title,
                        companyName = job.Recruiter.Company.Name
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi thêm công việc vào yêu thích", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
        
        [HttpDelete("{jobId}")]
        [Authorize]
        public async Task<IActionResult> RemoveFromFavorite(int jobId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var favorite = await _context.FavoriteJobs
                    .FirstOrDefaultAsync(f => f.UserId == userId && f.JobId == jobId);
                
                if (favorite == null)
                {
                    return NotFound(new { 
                        message = "Không tìm thấy công việc yêu thích",
                        errorCode = "FAVORITE_NOT_FOUND"
                    });
                }
                
                _context.FavoriteJobs.Remove(favorite);
                await _context.SaveChangesAsync();
                
                return Ok(new { 
                    message = "Xóa công việc khỏi yêu thích thành công",
                    data = new {
                        favoriteId = favorite.Id,
                        jobId = jobId
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi xóa công việc khỏi yêu thích", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
        
        [HttpGet("my-favorites")]
        [Authorize]
        public async Task<IActionResult> GetMyFavorites([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

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
                    message = "Lấy danh sách công việc yêu thích thành công",
                    data = favoriteJobs,
                    totalCount = totalFavorites,
                    currentPage = page,
                    pageSize = pageSize,
                    totalPages = (int)Math.Ceiling((double)totalFavorites / pageSize)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy danh sách công việc yêu thích", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
        
        [HttpGet("check/{jobId}")]
        [Authorize]
        public async Task<IActionResult> CheckFavoriteStatus(int jobId)
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var isFavorited = await _context.FavoriteJobs
                    .AnyAsync(f => f.UserId == userId && f.JobId == jobId);
                
                return Ok(new { 
                    message = "Kiểm tra trạng thái yêu thích thành công",
                    data = new {
                        jobId = jobId,
                        isFavorited = isFavorited
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi kiểm tra trạng thái yêu thích", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
        
        [HttpGet("stats")]
        [Authorize]
        public async Task<IActionResult> GetFavoriteStats()
        {
            try
            {
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var totalFavorites = await _context.FavoriteJobs
                    .CountAsync(f => f.UserId == userId);
                
                var activeFavorites = await _context.FavoriteJobs
                    .Where(f => f.UserId == userId)
                    .Include(f => f.Job)
                    .CountAsync(f => f.Job.IsActive);
                
                var recentFavorites = await _context.FavoriteJobs
                    .Where(f => f.UserId == userId && f.CreatedAt >= DateTime.Now.AddDays(-7))
                    .CountAsync();
                
                return Ok(new
                {
                    message = "Lấy thống kê công việc yêu thích thành công",
                    data = new
                    {
                        totalFavorites,
                        activeFavorites,
                        recentFavorites
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy thống kê công việc yêu thích", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
    }
}
