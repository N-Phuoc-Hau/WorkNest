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
        private readonly JwtService _jwtService;

        public FollowController(ApplicationDbContext context, NotificationService notificationService, EmailService emailService, JwtService jwtService)
        {
            _context = context;
            _notificationService = notificationService;
            _emailService = emailService;
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
                        catch (Exception ex)
                        {
                            Console.WriteLine($"Error extracting user info from token: {ex.Message}");
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpPost]
        [Authorize(Roles = "candidate")]
        public async Task<IActionResult> FollowCompany([FromBody] CreateFollowDto createDto)
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

                // Database User Validation
                var dbUser = await _context.Users.FindAsync(userId);
                if (dbUser == null)
                {
                    return BadRequest(new { 
                        message = "Người dùng không tồn tại trong hệ thống",
                        errorCode = "USER_NOT_FOUND"
                    });
                }

                if (!dbUser.IsActive)
                {
                    return BadRequest(new { 
                        message = "Tài khoản đã bị vô hiệu hóa",
                        errorCode = "ACCOUNT_DISABLED"
                    });
                }

                // Role Check
                var hasCandidateRole = dbUser.Role == "candidate" || userRole == "candidate";
                if (!hasCandidateRole)
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể theo dõi công ty.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                // Check if company exists
                var company = await _context.Companies
                    .Include(c => c.User)
                    .FirstOrDefaultAsync(c => c.Id == createDto.CompanyId && c.IsActive);

                if (company == null)
                {
                    return NotFound(new { 
                        message = "Không tìm thấy công ty",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                // Check if user is trying to follow their own company
                if (company.UserId == userId)
                {
                    return BadRequest(new { 
                        message = "Bạn không thể theo dõi công ty của chính mình",
                        errorCode = "CANNOT_FOLLOW_OWN_COMPANY"
                    });
                }

                // Check if already following
                var existingFollow = await _context.Follows
                    .FirstOrDefaultAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId);

                if (existingFollow != null)
                {
                    if (existingFollow.IsActive)
                    {
                        return BadRequest(new { 
                            message = "Bạn đã theo dõi công ty này rồi",
                            errorCode = "ALREADY_FOLLOWING"
                        });
                    }
                    else
                    {
                        // Reactivate the follow
                        existingFollow.IsActive = true;
                        existingFollow.UpdatedAt = DateTime.Now;
                        await _context.SaveChangesAsync();
                        return Ok(new { 
                            message = "Theo dõi công ty thành công",
                            data = new {
                                companyId = company.Id,
                                companyName = company.Name
                            }
                        });
                    }
                }

                var follow = new Follow
                {
                    FollowerId = userId,
                    RecruiterId = company.UserId
                };

                _context.Follows.Add(follow);
                await _context.SaveChangesAsync();

                // Send welcome email (optional, don't fail if it doesn't work)
                try
                {
                    var user = await _context.Users.FindAsync(userId);
                    if (user != null)
                    {
                        await _emailService.SendFollowNotificationAsync(
                            user.Email ?? "", 
                            user.UserName ?? user.FirstName + " " + user.LastName, 
                            company.Name ?? ""
                        );
                    }
                }
                catch (Exception)
                {
                    // Log error but don't fail the follow operation
                }
                
                return Ok(new { 
                    message = "Theo dõi công ty thành công",
                    data = new {
                        companyId = company.Id,
                        companyName = company.Name
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi theo dõi công ty", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpDelete("{companyId}")]
        [Authorize(Roles = "candidate")]
        public async Task<IActionResult> UnfollowCompany(int companyId)
        {
            try
            {
                var (userId, _, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                // Check if company exists
                var company = await _context.Companies
                    .FirstOrDefaultAsync(c => c.Id == companyId && c.IsActive);

                if (company == null)
                {
                    return NotFound(new { 
                        message = "Không tìm thấy công ty",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                var follow = await _context.Follows
                    .FirstOrDefaultAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId && f.IsActive);

                if (follow == null)
                {
                    return BadRequest(new { 
                        message = "Bạn chưa theo dõi công ty này",
                        errorCode = "NOT_FOLLOWING"
                    });
                }

                follow.IsActive = false;
                follow.UpdatedAt = DateTime.Now;
                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Hủy theo dõi công ty thành công",
                    data = new {
                        companyId = companyId,
                        companyName = company.Name
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi hủy theo dõi công ty", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("my-following")]
        [Authorize(Roles = "candidate")]
        public async Task<IActionResult> GetMyFollowing(
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var (userId, _, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var query = _context.Follows
                    .Where(f => f.FollowerId == userId && f.IsActive)
                    .Include(f => f.Recruiter)
                    .ThenInclude(r => r.Company);

                var totalCount = await query.CountAsync();
                var follows = await query
                    .OrderByDescending(f => f.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var followingList = follows.Select(f => new CompanyDto
                {
                    Id = f.Recruiter.Company!.Id,
                    UserId = f.Recruiter.Id,
                    Name = f.Recruiter.Company.Name,
                    TaxCode = f.Recruiter.Company.TaxCode,
                    Description = f.Recruiter.Company.Description,
                    Location = f.Recruiter.Company.Location,
                    IsVerified = f.Recruiter.Company.IsVerified,
                    IsActive = f.Recruiter.Company.IsActive,
                    CreatedAt = f.Recruiter.Company.CreatedAt,
                    UpdatedAt = f.Recruiter.Company.UpdatedAt,
                    Images = new List<string>() // You might want to include images if needed
                }).ToList();

                return Ok(new
                {
                    message = "Lấy danh sách công ty đang theo dõi thành công",
                    data = followingList,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy danh sách công ty đang theo dõi", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("my-followers")]
        [Authorize(Roles = "recruiter")]
        public async Task<IActionResult> GetMyFollowers(
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var (userId, _, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var query = _context.Follows
                    .Where(f => f.RecruiterId == userId && f.IsActive)
                    .Include(f => f.Follower);

                var totalCount = await query.CountAsync();
                var follows = await query
                    .OrderByDescending(f => f.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var followersList = follows.Select(f => new UserDto
                {
                    Id = f.Follower.Id,
                    Email = f.Follower.Email!,
                    FirstName = f.Follower.FirstName,
                    LastName = f.Follower.LastName,
                    Role = f.Follower.Role,
                    Avatar = f.Follower.Avatar,
                    CreatedAt = f.CreatedAt
                }).ToList();

                return Ok(new
                {
                    message = "Lấy danh sách người theo dõi thành công",
                    data = followersList,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy danh sách người theo dõi", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("check/{companyId}")]
        [Authorize(Roles = "candidate")]
        public async Task<IActionResult> IsFollowing(int companyId)
        {
            try
            {
                var (userId, _, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                var company = await _context.Companies
                    .FirstOrDefaultAsync(c => c.Id == companyId && c.IsActive);

                if (company == null)
                {
                    return NotFound(new { 
                        message = "Không tìm thấy công ty",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                var isFollowing = await _context.Follows
                    .AnyAsync(f => f.FollowerId == userId && f.RecruiterId == company.UserId && f.IsActive);

                return Ok(new
                {
                    message = "Kiểm tra trạng thái theo dõi thành công",
                    data = new
                    {
                        companyId = companyId,
                        isFollowing = isFollowing
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi kiểm tra trạng thái theo dõi", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
    }
}
