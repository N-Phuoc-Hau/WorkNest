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
    [Authorize]
    public class ReviewController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ReviewController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("candidate-review")]
        [Authorize(Policy = "IsCandidate")]
        public async Task<IActionResult> CreateCandidateReview([FromBody] CreateCandidateReviewDto createDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            // Get company and recruiter
            var company = await _context.Companies
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == createDto.CompanyId && c.IsActive);

            if (company == null)
            {
                return NotFound("Company not found");
            }

            var recruiterId = company.UserId;

            // Check if candidate is trying to review themselves
            if (recruiterId == userId)
            {
                return BadRequest("You cannot review yourself");
            }

            // Check if candidate has accepted application with this recruiter
            var hasAcceptedApplication = await _context.Applications
                .AnyAsync(a => a.ApplicantId == userId && 
                              a.Job.RecruiterId == recruiterId && 
                              a.Status == ApplicationStatus.Accepted);

            if (!hasAcceptedApplication)
            {
                return BadRequest("You can only review recruiters for jobs you were accepted for");
            }

            // Check if review already exists
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.ReviewerId == userId && r.ReviewedUserId == recruiterId);

            if (existingReview != null)
            {
                return BadRequest("You have already reviewed this recruiter");
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

            return Ok(new { message = "Review created successfully", reviewId = review.Id });
        }

        [HttpPost("recruiter-review")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> CreateRecruiterReview([FromBody] CreateRecruiterReviewDto createDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            // Check if candidate exists
            var candidate = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == createDto.CandidateId && u.Role == "candidate");

            if (candidate == null)
            {
                return NotFound("Candidate not found");
            }

            // Check if recruiter is trying to review themselves
            if (createDto.CandidateId == userId)
            {
                return BadRequest("You cannot review yourself");
            }

            // Check if recruiter has accepted application from this candidate
            var hasAcceptedApplication = await _context.Applications
                .AnyAsync(a => a.ApplicantId == createDto.CandidateId && 
                              a.Job.RecruiterId == userId && 
                              a.Status == ApplicationStatus.Accepted);

            if (!hasAcceptedApplication)
            {
                return BadRequest("You can only review candidates for jobs you accepted them for");
            }

            // Check if review already exists
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.ReviewerId == userId && r.ReviewedUserId == createDto.CandidateId);

            if (existingReview != null)
            {
                return BadRequest("You have already reviewed this candidate");
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

            return Ok(new { message = "Review created successfully", reviewId = review.Id });
        }

        [HttpGet("user/{userId}")]
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
        public async Task<IActionResult> GetMyReviews(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
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
                data = reviewDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                averageRating = Math.Round(averageRating, 2)
            });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReview(int id)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var review = await _context.Reviews
                .FirstOrDefaultAsync(r => r.Id == id && r.ReviewerId == userId && r.IsActive);

            if (review == null)
            {
                return NotFound();
            }

            // Soft delete
            review.IsActive = false;
            review.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Review deleted successfully" });
        }
    }
}
