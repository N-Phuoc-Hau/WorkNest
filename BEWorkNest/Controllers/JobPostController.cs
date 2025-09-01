using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Data;
using BEWorkNest.Services;
using System.Text.Json;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class JobPostController : ControllerBase
    {
        private readonly JobPostService _jobPostService;
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;
        private readonly NotificationService _notificationService;

        public JobPostController(JobPostService jobPostService, ApplicationDbContext context, JwtService jwtService, NotificationService notificationService)
        {
            _jobPostService = jobPostService;
            _context = context;
            _jwtService = jwtService;
            _notificationService = notificationService;
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
                            // Token validation failed
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetJobPosts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null,
            [FromQuery] string? specialized = null,
            [FromQuery] string? location = null)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var (jobPosts, totalCount) = await _jobPostService.GetJobPostsAsync(page, pageSize, search, specialized, location, userId);

            return Ok(new
            {
                data = jobPosts,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetJobPost(int id)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var jobPost = await _jobPostService.GetJobPostByIdAsync(id, userId);

            if (jobPost == null)
            {
                return NotFound();
            }

            return Ok(jobPost);
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> CreateJobPost([FromBody] CreateJobPostDto createDto)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                // Step 2: Database User Validation
                var dbUser = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Id == userId);

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

                // Step 3: Role Check
                if (dbUser.Role != "recruiter")
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể tạo bài đăng tuyển dụng.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = dbUser.Role
                    });
                }

                // Step 4: Data Validation
                if (createDto == null)
                {
                    return BadRequest(new { 
                        message = "Dữ liệu không được để trống",
                        errorCode = "MISSING_DATA"
                    });
                }

                if (!ModelState.IsValid)
                {
                    var errors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) })
                        .ToArray();

                    return BadRequest(new { 
                        message = "Dữ liệu không hợp lệ", 
                        errors,
                        errorCode = "VALIDATION_FAILED"
                    });
                }

                // Step 5: Create Job Post
                var (success, message, jobId) = await _jobPostService.CreateJobPostAsync(createDto, userId);

                if (success)
                {
                    // Send notification to followers after job is created successfully
                    try
                    {
                        var jobPost = await _context.JobPosts.FindAsync(jobId);
                        if (jobPost != null)
                        {
                            await _notificationService.SendJobPostedNotificationAsync(jobPost, dbUser);
                        }
                    }
                    catch (Exception)
                    {
                        // Log error but don't fail the job creation
                        // Consider using ILogger here for proper logging
                    }

                    return Ok(new { 
                        message = "Tạo bài đăng tuyển dụng thành công", 
                        jobId,
                        data = new {
                            jobId,
                            title = createDto.Title,
                            createdBy = dbUser.Email,
                            createdAt = DateTime.Now,
                            isTestingMode = !isAuthenticated
                        }
                    });
                }

                return BadRequest(new { 
                    message = $"Tạo bài đăng thất bại: {message}",
                    errorCode = "CREATE_FAILED"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi tạo bài đăng tuyển dụng", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateJobPost(int id, [FromBody] UpdateJobPostDto updateDto)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { 
                        message = "Token không hợp lệ hoặc đã hết hạn",
                        errorCode = "INVALID_TOKEN"
                    });
                }

                // Step 2: Database User Validation
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

                // Step 3: Role Check
                if (dbUser.Role != "recruiter")
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể cập nhật bài đăng.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                var (success, message) = await _jobPostService.UpdateJobPostAsync(id, updateDto, userId);

                if (success)
                {
                    return Ok(new { 
                        message = "Cập nhật bài đăng thành công",
                        data = new {
                            jobId = id,
                            updatedBy = dbUser.Email,
                            updatedAt = DateTime.Now,
                            isTestingMode = !isAuthenticated
                        }
                    });
                }

                return BadRequest(new { 
                    message = $"Cập nhật bài đăng thất bại: {message}",
                    errorCode = "UPDATE_FAILED"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi cập nhật bài đăng", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteJobPost(int id)
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

                // Step 2: Database User Validation
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

                // Step 3: Role Check
                var hasRecruiterRole = dbUser.Role == "recruiter" || userRole == "recruiter";
                if (!hasRecruiterRole)
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xóa bài đăng.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                var (success, message) = await _jobPostService.DeleteJobPostAsync(id, userId);

                if (success)
                {
                    return Ok(new { 
                        message = "Xóa bài đăng thành công",
                        data = new {
                            jobId = id,
                            deletedBy = dbUser.Email,
                            deletedAt = DateTime.Now
                        }
                    });
                }

                return BadRequest(new { 
                    message = $"Xóa bài đăng thất bại: {message}",
                    errorCode = "DELETE_FAILED"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi xóa bài đăng", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("my-jobs")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyJobPosts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
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

                // Step 2: Database User Validation
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

                // Step 3: Role Check
                var hasRecruiterRole = dbUser.Role == "recruiter" || userRole == "recruiter";
                if (!hasRecruiterRole)
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem danh sách bài đăng của mình.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                var (jobPosts, totalCount) = await _jobPostService.GetMyJobPostsAsync(userId, page, pageSize);

                return Ok(new
                {
                    message = "Lấy danh sách bài đăng thành công",
                    data = jobPosts,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                    userInfo = new {
                        userId = dbUser.Id,
                        email = dbUser.Email
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy danh sách bài đăng", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
    }
}
