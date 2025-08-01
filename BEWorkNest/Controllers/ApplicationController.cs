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
    [AllowAnonymous]
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
        [AllowAnonymous]
        public async Task<IActionResult> CreateApplication([FromForm] CreateApplicationDto createDto)
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
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể nộp đơn ứng tuyển.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
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
        [AllowAnonymous]
        public async Task<IActionResult> GetMyApplications(
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
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
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
        [AllowAnonymous]
        public async Task<IActionResult> UpdateApplicationStatus(int id, [FromBody] UpdateApplicationStatusDto updateDto)
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
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể cập nhật trạng thái đơn ứng tuyển.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
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
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Bạn chỉ có thể cập nhật đơn ứng tuyển cho công việc của mình.",
                    errorCode = "NOT_JOB_OWNER"
                });
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
        [AllowAnonymous]
        public async Task<IActionResult> GetJobApplications(int jobId,
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
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem đơn ứng tuyển cho công việc của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
            }

            var jobPost = await _context.JobPosts.FindAsync(jobId);
            if (jobPost == null || jobPost.RecruiterId != userId)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Bạn chỉ có thể xem đơn ứng tuyển cho công việc của mình.",
                    errorCode = "NOT_JOB_OWNER"
                });
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
        [AllowAnonymous]
        public async Task<IActionResult> DeleteApplication(int id)
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
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xóa đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
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
        [AllowAnonymous]
        public async Task<IActionResult> UpdateApplication(int id, [FromForm] UpdateApplicationDto updateDto)
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
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể cập nhật đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? customRole ?? "unknown"
                });
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
