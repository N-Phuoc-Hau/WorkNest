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
    public class JobPostController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public JobPostController(ApplicationDbContext context)
        {
            _context = context;
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
            var query = _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .ThenInclude(c => c!.Images)
                .Where(j => j.IsActive);

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(j => j.Title.Contains(search) || j.Description.Contains(search));
            }

            if (!string.IsNullOrEmpty(specialized))
            {
                query = query.Where(j => j.Specialized.Contains(specialized));
            }

            if (!string.IsNullOrEmpty(location))
            {
                query = query.Where(j => j.Location.Contains(location));
            }

            var totalCount = await query.CountAsync();
            var jobPosts = await query
                .OrderByDescending(j => j.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var jobPostDtos = jobPosts.Select(j => new JobPostDto
            {
                Id = j.Id,
                Title = j.Title,
                Specialized = j.Specialized,
                Description = j.Description,
                Salary = j.Salary,
                WorkingHours = j.WorkingHours,
                Location = j.Location,
                CreatedAt = j.CreatedAt,
                Recruiter = new UserDto
                {
                    Id = j.Recruiter.Id,
                    Email = j.Recruiter.Email!,
                    FirstName = j.Recruiter.FirstName,
                    LastName = j.Recruiter.LastName,
                    Role = j.Recruiter.Role,
                    Avatar = j.Recruiter.Avatar,
                    CreatedAt = j.Recruiter.CreatedAt,
                    Company = j.Recruiter.Company != null ? new CompanyDto
                    {
                        Id = j.Recruiter.Company.Id,
                        Name = j.Recruiter.Company.Name,
                        TaxCode = j.Recruiter.Company.TaxCode,
                        Description = j.Recruiter.Company.Description,
                        Location = j.Recruiter.Company.Location,
                        IsVerified = j.Recruiter.Company.IsVerified,
                        Images = j.Recruiter.Company.Images.Select(i => i.ImageUrl).ToList()
                    } : null
                },
                ApplicationCount = j.Applications.Count(a => a.IsActive)
            }).ToList();

            return Ok(new
            {
                data = jobPostDtos,
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
            var jobPost = await _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .ThenInclude(c => c!.Images)
                .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

            if (jobPost == null)
            {
                return NotFound();
            }

            var jobPostDto = new JobPostDto
            {
                Id = jobPost.Id,
                Title = jobPost.Title,
                Specialized = jobPost.Specialized,
                Description = jobPost.Description,
                Salary = jobPost.Salary,
                WorkingHours = jobPost.WorkingHours,
                Location = jobPost.Location,
                CreatedAt = jobPost.CreatedAt,
                Recruiter = new UserDto
                {
                    Id = jobPost.Recruiter.Id,
                    Email = jobPost.Recruiter.Email!,
                    FirstName = jobPost.Recruiter.FirstName,
                    LastName = jobPost.Recruiter.LastName,
                    Role = jobPost.Recruiter.Role,
                    Avatar = jobPost.Recruiter.Avatar,
                    CreatedAt = jobPost.Recruiter.CreatedAt,
                    Company = jobPost.Recruiter.Company != null ? new CompanyDto
                    {
                        Id = jobPost.Recruiter.Company.Id,
                        Name = jobPost.Recruiter.Company.Name,
                        TaxCode = jobPost.Recruiter.Company.TaxCode,
                        Description = jobPost.Recruiter.Company.Description,
                        Location = jobPost.Recruiter.Company.Location,
                        IsVerified = jobPost.Recruiter.Company.IsVerified,
                        Images = jobPost.Recruiter.Company.Images.Select(i => i.ImageUrl).ToList()
                    } : null
                },
                ApplicationCount = jobPost.Applications.Count(a => a.IsActive)
            };

            return Ok(jobPostDto);
        }

        [HttpPost]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> CreateJobPost([FromBody] CreateJobPostDto createDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var jobPost = new JobPost
            {
                RecruiterId = userId,
                Title = createDto.Title,
                Specialized = createDto.Specialized,
                Description = createDto.Description,
                Salary = createDto.Salary,
                WorkingHours = createDto.WorkingHours,
                Location = createDto.Location
            };

            _context.JobPosts.Add(jobPost);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Job post created successfully", jobId = jobPost.Id });
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> UpdateJobPost(int id, [FromBody] UpdateJobPostDto updateDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var jobPost = await _context.JobPosts
                .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

            if (jobPost == null)
            {
                return NotFound();
            }

            // Check if current user is the owner of the job post
            if (jobPost.RecruiterId != userId)
            {
                return Forbid();
            }

            // Update fields
            if (!string.IsNullOrEmpty(updateDto.Title))
                jobPost.Title = updateDto.Title;
            
            if (!string.IsNullOrEmpty(updateDto.Specialized))
                jobPost.Specialized = updateDto.Specialized;
            
            if (!string.IsNullOrEmpty(updateDto.Description))
                jobPost.Description = updateDto.Description;
            
            if (updateDto.Salary.HasValue)
                jobPost.Salary = updateDto.Salary.Value;
            
            if (!string.IsNullOrEmpty(updateDto.WorkingHours))
                jobPost.WorkingHours = updateDto.WorkingHours;
            
            if (!string.IsNullOrEmpty(updateDto.Location))
                jobPost.Location = updateDto.Location;

            jobPost.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Job post updated successfully" });
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> DeleteJobPost(int id)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var jobPost = await _context.JobPosts
                .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

            if (jobPost == null)
            {
                return NotFound();
            }

            // Check if current user is the owner of the job post
            if (jobPost.RecruiterId != userId)
            {
                return Forbid();
            }

            // Soft delete
            jobPost.IsActive = false;
            jobPost.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Job post deleted successfully" });
        }

        [HttpGet("my-jobs")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> GetMyJobPosts(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var query = _context.JobPosts
                .Include(j => j.Applications)
                .Where(j => j.RecruiterId == userId && j.IsActive);

            var totalCount = await query.CountAsync();
            var jobPosts = await query
                .OrderByDescending(j => j.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var jobPostDtos = jobPosts.Select(j => new JobPostDto
            {
                Id = j.Id,
                Title = j.Title,
                Specialized = j.Specialized,
                Description = j.Description,
                Salary = j.Salary,
                WorkingHours = j.WorkingHours,
                Location = j.Location,
                CreatedAt = j.CreatedAt,
                ApplicationCount = j.Applications.Count(a => a.IsActive)
            }).ToList();

            return Ok(new
            {
                data = jobPostDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }
    }
}
