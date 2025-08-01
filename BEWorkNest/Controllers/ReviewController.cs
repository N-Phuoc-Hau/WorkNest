using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Data;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class ReviewController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ReviewController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("candidate-review")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateCandidateReview([FromBody] CreateCandidateReviewDto createDto)
        {
            try
            {
                // Step 1: Authentication Check (with testing mode)
                var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
                var customRole = User.FindFirst("role")?.Value;

                // Use fixed candidate ID for testing if no authentication
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    userId = "candidate-user-id-for-testing"; // Fixed candidate ID for testing
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
                var hasCandidateRole = dbUser.Role == "candidate" || userRole == "candidate" || customRole == "candidate";
                if (!hasCandidateRole)
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể đánh giá nhà tuyển dụng.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
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

                // Get company and recruiter
                var company = await _context.Companies
                    .Include(c => c.User)
                    .FirstOrDefaultAsync(c => c.Id == createDto.CompanyId && c.IsActive);

                if (company == null)
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy công ty",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                var recruiterId = company.UserId;

                // Check if candidate is trying to review themselves
                if (recruiterId == userId)
                {
                    return BadRequest(new { 
                        message = "Bạn không thể đánh giá chính mình",
                        errorCode = "SELF_REVIEW_NOT_ALLOWED"
                    });
                }

                // Check if candidate has accepted application with this recruiter
                var hasAcceptedApplication = await _context.Applications
                    .AnyAsync(a => a.ApplicantId == userId && 
                                  a.Job.RecruiterId == recruiterId && 
                                  a.Status == ApplicationStatus.Accepted);

                if (!hasAcceptedApplication && isAuthenticated) // Skip this check in testing mode
                {
                    return BadRequest(new { 
                        message = "Bạn chỉ có thể đánh giá nhà tuyển dụng cho các công việc mà bạn đã được chấp nhận",
                        errorCode = "NO_ACCEPTED_APPLICATION"
                    });
                }

                // Check if review already exists
                var existingReview = await _context.Reviews
                    .FirstOrDefaultAsync(r => r.ReviewerId == userId && r.ReviewedUserId == recruiterId);

                if (existingReview != null)
                {
                    return BadRequest(new { 
                        message = "Bạn đã đánh giá nhà tuyển dụng này rồi",
                        errorCode = "REVIEW_ALREADY_EXISTS"
                    });
                }

                var review = new Review
                {
                    ReviewerId = userId,
                    ReviewedUserId = recruiterId,
                    Rating = createDto.Rating,
                    Comment = createDto.Comment
                };

                _context.Reviews.Add(review);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Tạo đánh giá thành công", 
                    data = new {
                        reviewId = review.Id,
                        companyId = createDto.CompanyId,
                        rating = createDto.Rating,
                        reviewedBy = dbUser.Email,
                        createdAt = DateTime.Now,
                        isTestingMode = !isAuthenticated
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi tạo đánh giá", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpPost("recruiter-review")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateRecruiterReview([FromBody] CreateRecruiterReviewDto createDto)
        {
            try
            {
                // Step 1: Authentication Check (with testing mode)
                var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
                var customRole = User.FindFirst("role")?.Value;

                // Use fixed recruiter ID for testing if no authentication
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    userId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a"; // Fixed recruiter ID for testing
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
                var hasRecruiterRole = dbUser.Role == "recruiter" || userRole == "recruiter" || customRole == "recruiter";
                if (!hasRecruiterRole)
                {
                    return BadRequest(new { 
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể đánh giá ứng viên.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
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

                // Check if candidate exists
                var candidate = await _context.Users
                    .FirstOrDefaultAsync(u => u.Id == createDto.CandidateId && u.Role == "candidate");

                if (candidate == null)
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy ứng viên",
                        errorCode = "CANDIDATE_NOT_FOUND"
                    });
                }

                // Check if recruiter is trying to review themselves
                if (createDto.CandidateId == userId)
                {
                    return BadRequest(new { 
                        message = "Bạn không thể đánh giá chính mình",
                        errorCode = "SELF_REVIEW_NOT_ALLOWED"
                    });
                }

                // Check if recruiter has accepted application from this candidate
                var hasAcceptedApplication = await _context.Applications
                    .AnyAsync(a => a.ApplicantId == createDto.CandidateId && 
                                  a.Job.RecruiterId == userId && 
                                  a.Status == ApplicationStatus.Accepted);

                if (!hasAcceptedApplication && isAuthenticated) // Skip this check in testing mode
                {
                    return BadRequest(new { 
                        message = "Bạn chỉ có thể đánh giá ứng viên cho các công việc mà bạn đã chấp nhận họ",
                        errorCode = "NO_ACCEPTED_APPLICATION"
                    });
                }

                // Check if review already exists
                var existingReview = await _context.Reviews
                    .FirstOrDefaultAsync(r => r.ReviewerId == userId && r.ReviewedUserId == createDto.CandidateId);

                if (existingReview != null)
                {
                    return BadRequest(new { 
                        message = "Bạn đã đánh giá ứng viên này rồi",
                        errorCode = "REVIEW_ALREADY_EXISTS"
                    });
                }

                var review = new Review
                {
                    ReviewerId = userId,
                    ReviewedUserId = createDto.CandidateId,
                    Rating = createDto.Rating,
                    Comment = createDto.Comment
                };

                _context.Reviews.Add(review);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Tạo đánh giá thành công", 
                    data = new {
                        reviewId = review.Id,
                        candidateId = createDto.CandidateId,
                        rating = createDto.Rating,
                        reviewedBy = dbUser.Email,
                        createdAt = DateTime.Now,
                        isTestingMode = !isAuthenticated
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi tạo đánh giá", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("user/{userId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUserReviews(string userId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _context.Reviews
                .Include(r => r.Reviewer)
                .Include(r => r.ReviewedUser)
                .Where(r => r.ReviewedUserId == userId && r.IsActive);

            var totalCount = await query.CountAsync();
            var reviews = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var reviewDtos = reviews.Select(r => new ReviewDto
            {
                Id = r.Id,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                Reviewer = new UserDto
                {
                    Id = r.Reviewer.Id,
                    Email = r.Reviewer.Email!,
                    FirstName = r.Reviewer.FirstName,
                    LastName = r.Reviewer.LastName,
                    Role = r.Reviewer.Role,
                    Avatar = r.Reviewer.Avatar,
                    CreatedAt = r.Reviewer.CreatedAt
                },
                ReviewedUser = new UserDto
                {
                    Id = r.ReviewedUser.Id,
                    Email = r.ReviewedUser.Email!,
                    FirstName = r.ReviewedUser.FirstName,
                    LastName = r.ReviewedUser.LastName,
                    Role = r.ReviewedUser.Role,
                    Avatar = r.ReviewedUser.Avatar,
                    CreatedAt = r.ReviewedUser.CreatedAt
                }
            }).ToList();

            // Calculate average rating
            var averageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0;

            return Ok(new
            {
                data = reviewDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                averageRating = Math.Round(averageRating, 2)
            });
        }

        [HttpGet("company/{companyId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCompanyReviews(int companyId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == companyId && c.IsActive);

            if (company == null)
            {
                return NotFound("Company not found");
            }

            var query = _context.Reviews
                .Include(r => r.Reviewer)
                .Include(r => r.ReviewedUser)
                .Where(r => r.ReviewedUserId == company.UserId && r.IsActive);

            var totalCount = await query.CountAsync();
            var reviews = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var reviewDtos = reviews.Select(r => new ReviewDto
            {
                Id = r.Id,
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                Reviewer = new UserDto
                {
                    Id = r.Reviewer.Id,
                    Email = r.Reviewer.Email!,
                    FirstName = r.Reviewer.FirstName,
                    LastName = r.Reviewer.LastName,
                    Role = r.Reviewer.Role,
                    Avatar = r.Reviewer.Avatar,
                    CreatedAt = r.Reviewer.CreatedAt
                }
            }).ToList();

            // Calculate average rating
            var averageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0;

            return Ok(new
            {
                data = reviewDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                averageRating = Math.Round(averageRating, 2)
            });
        }

        [HttpGet("my-reviews")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyReviews(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                // Step 1: Authentication Check (with testing mode)
                var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

                // Use fixed user ID for testing if no authentication
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    userId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a"; // Fixed user ID for testing
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

                var query = _context.Reviews
                    .Include(r => r.Reviewer)
                    .Include(r => r.ReviewedUser)
                    .Where(r => r.ReviewedUserId == userId && r.IsActive);

                var totalCount = await query.CountAsync();
                var reviews = await query
                    .OrderByDescending(r => r.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var reviewDtos = reviews.Select(r => new ReviewDto
                {
                    Id = r.Id,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    CreatedAt = r.CreatedAt,
                    Reviewer = new UserDto
                    {
                        Id = r.Reviewer.Id,
                        Email = r.Reviewer.Email!,
                        FirstName = r.Reviewer.FirstName,
                        LastName = r.Reviewer.LastName,
                        Role = r.Reviewer.Role,
                        Avatar = r.Reviewer.Avatar,
                        CreatedAt = r.Reviewer.CreatedAt
                    }
                }).ToList();

                // Calculate average rating
                var averageRating = reviews.Any() ? reviews.Average(r => r.Rating) : 0;

                return Ok(new
                {
                    message = "Lấy danh sách đánh giá thành công",
                    data = reviewDtos,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                    averageRating = Math.Round(averageRating, 2),
                    userInfo = new {
                        userId = dbUser.Id,
                        email = dbUser.Email,
                        isTestingMode = !isAuthenticated
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi lấy danh sách đánh giá", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteReview(int id)
        {
            try
            {
                // Step 1: Authentication Check (with testing mode)
                var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
                var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

                // Use fixed user ID for testing if no authentication
                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    userId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a"; // Fixed user ID for testing
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

                var review = await _context.Reviews
                    .FirstOrDefaultAsync(r => r.Id == id && r.ReviewerId == userId && r.IsActive);

                if (review == null)
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy đánh giá hoặc bạn không có quyền xóa đánh giá này",
                        errorCode = "REVIEW_NOT_FOUND"
                    });
                }

                // Soft delete
                review.IsActive = false;
                review.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Xóa đánh giá thành công",
                    data = new {
                        reviewId = review.Id,
                        deletedBy = dbUser.Email,
                        deletedAt = DateTime.Now,
                        isTestingMode = !isAuthenticated
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi xóa đánh giá", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }
    }
}
