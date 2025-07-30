using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Data;
using BEWorkNest.Services;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ApplicationController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly CloudinaryService _cloudinaryService;

        public ApplicationController(ApplicationDbContext context, CloudinaryService cloudinaryService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
        }

        [HttpPost]
        [Authorize(Policy = "IsCandidate")]
        public async Task<IActionResult> CreateApplication([FromForm] CreateApplicationDto createDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            // Check if job post exists
            var jobPost = await _context.JobPosts.FindAsync(createDto.JobId);
            if (jobPost == null || !jobPost.IsActive)
            {
                return BadRequest("Job post not found or inactive");
            }

            // Check if application already exists
            var existingApplication = await _context.Applications
                .FirstOrDefaultAsync(a => a.ApplicantId == userId && a.JobId == createDto.JobId);
            
            if (existingApplication != null)
            {
                return BadRequest("You have already applied for this job");
            }

            string? cvUrl = null;
            if (createDto.CvFile != null)
            {
                try
                {
                    // Check if file is PDF
                    if (_cloudinaryService.IsPdfFile(createDto.CvFile))
                    {
                        cvUrl = await _cloudinaryService.UploadPdfAsync(createDto.CvFile, "cvs");
                    }
                    else
                    {
                        return BadRequest("CV file must be in PDF format");
                    }
                }
                catch (Exception ex)
                {
                    return BadRequest(new { message = "Failed to upload CV", error = ex.Message });
                }
            }

            var application = new Application
            {
                ApplicantId = userId,
                JobId = createDto.JobId,
                CvUrl = cvUrl,
                CoverLetter = createDto.CoverLetter,
                Status = ApplicationStatus.Pending
            };

            _context.Applications.Add(application);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Application submitted successfully", applicationId = application.Id });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetApplication(int id)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;
            
            var application = await _context.Applications
                .Include(a => a.Applicant)
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .FirstOrDefaultAsync(a => a.Id == id && a.IsActive);

            if (application == null)
            {
                return NotFound();
            }

            // Check authorization: only applicant or job owner can view
            if (userRole == "candidate" && application.ApplicantId != userId)
            {
                return Forbid("You can only view your own applications");
            }
            
            if (userRole == "recruiter" && application.Job.RecruiterId != userId)
            {
                return Forbid("You can only view applications for your jobs");
            }

            var applicationDto = new ApplicationDto
            {
                Id = application.Id,
                CvUrl = application.CvUrl,
                CoverLetter = application.CoverLetter,
                Status = application.Status.ToString(),
                CreatedAt = application.CreatedAt,
                Applicant = new UserDto
                {
                    Id = application.Applicant.Id,
                    Email = application.Applicant.Email!,
                    FirstName = application.Applicant.FirstName,
                    LastName = application.Applicant.LastName,
                    Role = application.Applicant.Role,
                    Avatar = application.Applicant.Avatar,
                    CreatedAt = application.Applicant.CreatedAt
                },
                Job = new JobPostDto
                {
                    Id = application.Job.Id,
                    Title = application.Job.Title,
                    Specialized = application.Job.Specialized,
                    Description = application.Job.Description,
                    Requirements = application.Job.Requirements,
                    Benefits = application.Job.Benefits,
                    Salary = application.Job.Salary,
                    WorkingHours = application.Job.WorkingHours,
                    Location = application.Job.Location,
                    JobType = application.Job.JobType,
                    ExperienceLevel = application.Job.ExperienceLevel,
                    DeadLine = application.Job.DeadLine,
                    CreatedAt = application.Job.CreatedAt,
                    Recruiter = new UserDto
                    {
                        Id = application.Job.Recruiter.Id,
                        Email = application.Job.Recruiter.Email!,
                        FirstName = application.Job.Recruiter.FirstName,
                        LastName = application.Job.Recruiter.LastName,
                        Role = application.Job.Recruiter.Role,
                        Avatar = application.Job.Recruiter.Avatar,
                        CreatedAt = application.Job.Recruiter.CreatedAt
                    }
                }
            };

            return Ok(applicationDto);
        }

        [HttpGet("my-applications")]
        [Authorize(Policy = "IsCandidate")]
        public async Task<IActionResult> GetMyApplications(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var query = _context.Applications
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(a => a.ApplicantId == userId && a.IsActive);

            var totalCount = await query.CountAsync();
            var applications = await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var applicationDtos = applications.Select(a => new ApplicationDto
            {
                Id = a.Id,
                CvUrl = a.CvUrl,
                CoverLetter = a.CoverLetter,
                Status = a.Status.ToString(),
                CreatedAt = a.CreatedAt,
                Job = new JobPostDto
                {
                    Id = a.Job.Id,
                    Title = a.Job.Title,
                    Specialized = a.Job.Specialized,
                    Description = a.Job.Description,
                    Requirements = a.Job.Requirements,
                    Benefits = a.Job.Benefits,
                    Salary = a.Job.Salary,
                    WorkingHours = a.Job.WorkingHours,
                    Location = a.Job.Location,
                    JobType = a.Job.JobType,
                    ExperienceLevel = a.Job.ExperienceLevel,
                    DeadLine = a.Job.DeadLine,
                    CreatedAt = a.Job.CreatedAt,
                    Recruiter = new UserDto
                    {
                        Id = a.Job.Recruiter.Id,
                        Email = a.Job.Recruiter.Email!,
                        FirstName = a.Job.Recruiter.FirstName,
                        LastName = a.Job.Recruiter.LastName,
                        Role = a.Job.Recruiter.Role,
                        Avatar = a.Job.Recruiter.Avatar,
                        CreatedAt = a.Job.Recruiter.CreatedAt
                    }
                }
            }).ToList();

            return Ok(new
            {
                data = applicationDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpPut("{id}/status")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> UpdateApplicationStatus(int id, [FromBody] UpdateApplicationStatusDto updateDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var application = await _context.Applications
                .Include(a => a.Job)
                .FirstOrDefaultAsync(a => a.Id == id && a.IsActive);

            if (application == null)
            {
                return NotFound();
            }

            // Check if current user is the recruiter of the job
            if (application.Job.RecruiterId != userId)
            {
                return Forbid();
            }

            if (Enum.TryParse<ApplicationStatus>(updateDto.Status, out var status))
            {
                application.Status = status;
                application.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                return Ok(new { message = "Application status updated successfully" });
            }

            return BadRequest("Invalid status");
        }

        [HttpGet("job/{jobId}/applications")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> GetJobApplications(int jobId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var jobPost = await _context.JobPosts.FindAsync(jobId);
            if (jobPost == null || jobPost.RecruiterId != userId)
            {
                return Forbid();
            }

            var query = _context.Applications
                .Include(a => a.Applicant)
                .Include(a => a.Job)
                .Where(a => a.JobId == jobId && a.IsActive);

            var totalCount = await query.CountAsync();
            var applications = await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var applicationDtos = applications.Select(a => new ApplicationDto
            {
                Id = a.Id,
                CvUrl = a.CvUrl,
                CoverLetter = a.CoverLetter,
                Status = a.Status.ToString(),
                CreatedAt = a.CreatedAt,
                Applicant = new UserDto
                {
                    Id = a.Applicant.Id,
                    Email = a.Applicant.Email!,
                    FirstName = a.Applicant.FirstName,
                    LastName = a.Applicant.LastName,
                    Role = a.Applicant.Role,
                    Avatar = a.Applicant.Avatar,
                    CreatedAt = a.Applicant.CreatedAt
                },
                Job = new JobPostDto
                {
                    Id = a.Job.Id,
                    Title = a.Job.Title,
                    Specialized = a.Job.Specialized,
                    Location = a.Job.Location,
                    CreatedAt = a.Job.CreatedAt
                }
            }).ToList();

            return Ok(new
            {
                data = applicationDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "IsCandidate")]
        public async Task<IActionResult> DeleteApplication(int id)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var application = await _context.Applications
                .FirstOrDefaultAsync(a => a.Id == id && a.ApplicantId == userId && a.IsActive);

            if (application == null)
            {
                return NotFound();
            }

            // Only allow deletion if status is Pending
            if (application.Status != ApplicationStatus.Pending)
            {
                return BadRequest("Can only delete pending applications");
            }

            // Delete CV file from Cloudinary if exists
            if (!string.IsNullOrEmpty(application.CvUrl))
            {
                var publicId = _cloudinaryService.GetPublicIdFromUrl(application.CvUrl);
                await _cloudinaryService.DeleteFileAsync(publicId); // Use DeleteFileAsync for PDF
            }

            // Soft delete
            application.IsActive = false;
            application.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Application deleted successfully" });
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "IsCandidate")]
        public async Task<IActionResult> UpdateApplication(int id, [FromForm] UpdateApplicationDto updateDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var application = await _context.Applications
                .FirstOrDefaultAsync(a => a.Id == id && a.ApplicantId == userId && a.IsActive);

            if (application == null)
            {
                return NotFound();
            }

            // Only allow update if status is Pending
            if (application.Status != ApplicationStatus.Pending)
            {
                return BadRequest("Can only update pending applications");
            }

            // Update CV if provided
            if (updateDto.CvFile != null)
            {
                try
                {
                    // Delete old CV if exists
                    if (!string.IsNullOrEmpty(application.CvUrl))
                    {
                        var oldPublicId = _cloudinaryService.GetPublicIdFromUrl(application.CvUrl);
                        await _cloudinaryService.DeleteFileAsync(oldPublicId);
                    }

                    // Upload new CV
                    if (_cloudinaryService.IsPdfFile(updateDto.CvFile))
                    {
                        application.CvUrl = await _cloudinaryService.UploadPdfAsync(updateDto.CvFile, "cvs");
                    }
                    else
                    {
                        return BadRequest("CV file must be in PDF format");
                    }
                }
                catch (Exception ex)
                {
                    return BadRequest(new { message = "Failed to upload CV", error = ex.Message });
                }
            }

            // Update cover letter if provided
            if (!string.IsNullOrEmpty(updateDto.CoverLetter))
            {
                application.CoverLetter = updateDto.CoverLetter;
            }

            application.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Application updated successfully" });
        }
    }
}
