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
    public class FollowController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly NotificationService _notificationService;
        private readonly EmailService _emailService;

        public FollowController(ApplicationDbContext context, NotificationService notificationService, EmailService emailService)
        {
            _context = context;
            _notificationService = notificationService;
            _emailService = emailService;
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> FollowCompany([FromBody] CreateFollowDto createDto)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var customRole = User.FindFirst("role")?.Value;

            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has candidate role
            var hasCandidateRole = userRole == "candidate" || customRole == "candidate";
            if (!hasCandidateRole)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể theo dõi công ty.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            // Check if company exists
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == createDto.CompanyId && c.IsActive);

            if (company == null)
            {
                return NotFound("Company not found");
            }

            // Check if user is trying to follow their own company
            if (company.UserId == userId)
            {
                return BadRequest("You cannot follow your own company");
            }

            // Check if already following
            var existingFollow = await _context.Follows
                .FirstOrDefaultAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId);

            if (existingFollow != null)
            {
                if (existingFollow.IsActive)
                {
                    return BadRequest("You are already following this company");
                }
                else
                {
                    // Reactivate the follow
                    existingFollow.IsActive = true;
                    existingFollow.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                    return Ok(new { message = "Successfully followed company" });
                }
            }

            var follow = new Follow
            {
                FollowerId = userId,
                RecruiterId = company.UserId
            };

            _context.Follows.Add(follow);
            await _context.SaveChangesAsync();

            // Send welcome email
            try
            {
                var user = await _context.Users.FindAsync(userId);
                var followedCompany = await _context.Companies.FindAsync(createDto.CompanyId);
                
                if (user != null && followedCompany != null)
                {
                    await _emailService.SendFollowNotificationAsync(
                        user.Email ?? "", 
                        user.UserName ?? "", 
                        followedCompany.Name ?? ""
                    );
                }
            }
            catch (Exception)
            {
                // Log error but don't fail the follow operation
                // _logger.LogError(ex, "Failed to send follow notification email");
            }
            
            return Ok(new { message = "Followed successfully" });
        }

        [HttpDelete("{companyId}")]
        [AllowAnonymous]
        public async Task<IActionResult> UnfollowCompany(int companyId)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var customRole = User.FindFirst("role")?.Value;

            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has candidate role
            var hasCandidateRole = userRole == "candidate" || customRole == "candidate";
            if (!hasCandidateRole)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể bỏ theo dõi công ty.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == companyId && c.IsActive);

            if (company == null)
            {
                return NotFound("Company not found");
            }

            var follow = await _context.Follows
                .FirstOrDefaultAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId && f.IsActive);

            if (follow == null)
            {
                return NotFound("Follow relationship not found");
            }

            // Soft delete
            follow.IsActive = false;
            follow.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Successfully unfollowed company" });
        }

        [HttpGet("my-following")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyFollowing(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var customRole = User.FindFirst("role")?.Value;

            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has candidate role
            var hasCandidateRole = userRole == "candidate" || customRole == "candidate";
            if (!hasCandidateRole)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem danh sách theo dõi của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            var query = _context.Follows
                .Include(f => f.Recruiter)
                .ThenInclude(r => r.Company)
                .ThenInclude(c => c!.Images)
                .Where(f => f.FollowerId == userId && f.IsActive);

            var totalCount = await query.CountAsync();
            var follows = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var followDtos = follows.Select(f => new FollowDto
            {
                Id = f.Id,
                CreatedAt = f.CreatedAt,
                Recruiter = new UserDto
                {
                    Id = f.Recruiter.Id,
                    Email = f.Recruiter.Email!,
                    FirstName = f.Recruiter.FirstName,
                    LastName = f.Recruiter.LastName,
                    Role = f.Recruiter.Role,
                    Avatar = f.Recruiter.Avatar,
                    CreatedAt = f.Recruiter.CreatedAt,
                    Company = f.Recruiter.Company != null ? new CompanyDto
                    {
                        Id = f.Recruiter.Company.Id,
                        Name = f.Recruiter.Company.Name,
                        TaxCode = f.Recruiter.Company.TaxCode,
                        Description = f.Recruiter.Company.Description,
                        Location = f.Recruiter.Company.Location,
                        IsVerified = f.Recruiter.Company.IsVerified,
                        Images = f.Recruiter.Company.Images.Select(i => i.ImageUrl).ToList()
                    } : null
                }
            }).ToList();

            return Ok(new
            {
                data = followDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpGet("followers")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyFollowers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var customRole = User.FindFirst("role")?.Value;

            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has recruiter role
            var hasRecruiterRole = userRole == "recruiter" || customRole == "recruiter";
            if (!hasRecruiterRole)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem danh sách người theo dõi.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            var query = _context.Follows
                .Include(f => f.Follower)
                .Where(f => f.RecruiterId == userId && f.IsActive);

            var totalCount = await query.CountAsync();
            var follows = await query
                .OrderByDescending(f => f.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var followDtos = follows.Select(f => new FollowDto
            {
                Id = f.Id,
                CreatedAt = f.CreatedAt,
                Follower = new UserDto
                {
                    Id = f.Follower.Id,
                    Email = f.Follower.Email!,
                    FirstName = f.Follower.FirstName,
                    LastName = f.Follower.LastName,
                    Role = f.Follower.Role,
                    Avatar = f.Follower.Avatar,
                    CreatedAt = f.Follower.CreatedAt
                }
            }).ToList();

            return Ok(new
            {
                data = followDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpGet("company/{companyId}/is-following")]
        [AllowAnonymous]
        public async Task<IActionResult> IsFollowing(int companyId)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var customRole = User.FindFirst("role")?.Value;

            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has candidate role
            var hasCandidateRole = userRole == "candidate" || customRole == "candidate";
            if (!hasCandidateRole)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể kiểm tra trạng thái theo dõi.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == companyId && c.IsActive);

            if (company == null)
            {
                return NotFound("Company not found");
            }

            var isFollowing = await _context.Follows
                .AnyAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId && f.IsActive);

            return Ok(new { isFollowing });
        }
    }
}
