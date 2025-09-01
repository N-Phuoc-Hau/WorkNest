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
        private readonly JwtService _jwtService;
        private readonly CVProcessingService _cvProcessingService;
        private readonly AiService _aiService;
        private readonly UserBehaviorService _userBehaviorService;
        private readonly ILogger<ApplicationController> _logger;

        public ApplicationController(
            ApplicationDbContext context, 
            CloudinaryService cloudinaryService, 
            JwtService jwtService,
            CVProcessingService cvProcessingService,
            AiService aiService,
            UserBehaviorService userBehaviorService,
            ILogger<ApplicationController> logger)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
            _jwtService = jwtService;
            _cvProcessingService = cvProcessingService;
            _aiService = aiService;
            _userBehaviorService = userBehaviorService;
            _logger = logger;
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

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> CreateApplication([FromForm] CreateApplicationDto createDto)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has candidate role
            if (userRole != "candidate")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể nộp đơn ứng tuyển.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
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

            // Track application behavior
            await _userBehaviorService.TrackApplicationAsync(userId, createDto.JobId, jobPost.Title, "pending");

            // Analyze CV if provided and perform matching
            if (createDto.CvFile != null && !string.IsNullOrEmpty(cvUrl))
            {
                _ = Task.Run(async () => await AnalyzeCVForApplicationAsync(application.Id, createDto.CvFile, jobPost));
            }
            else if (!string.IsNullOrEmpty(cvUrl))
            {
                _ = Task.Run(async () => await AnalyzeCVFromUrlAsync(application.Id, cvUrl, jobPost));
            }

            // Return complete application data for Flutter
            var savedApplication = await _context.Applications
                .Include(a => a.Applicant)
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .FirstOrDefaultAsync(a => a.Id == application.Id);

            if (savedApplication == null)
            {
                return StatusCode(500, "Application was created but could not be retrieved");
            }

            return Ok(new
            {
                id = savedApplication.Id,
                applicantId = savedApplication.ApplicantId,
                jobId = savedApplication.JobId,
                cvUrl = savedApplication.CvUrl,
                coverLetter = savedApplication.CoverLetter,
                status = savedApplication.Status.ToString(),
                createdAt = savedApplication.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                isActive = savedApplication.IsActive,
                appliedAt = savedApplication.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                applicant = savedApplication.Applicant != null ? new
                {
                    id = savedApplication.Applicant.Id,
                    userName = savedApplication.Applicant.UserName,
                    email = savedApplication.Applicant.Email,
                    fullName = $"{savedApplication.Applicant.FirstName} {savedApplication.Applicant.LastName}".Trim(),
                    avatar = savedApplication.Applicant.Avatar,
                    role = savedApplication.Applicant.Role
                } : null,
                job = savedApplication.Job != null ? new
                {
                    id = savedApplication.Job.Id,
                    title = savedApplication.Job.Title,
                    description = savedApplication.Job.Description,
                    salary = savedApplication.Job.Salary,
                    location = savedApplication.Job.Location,
                    specialized = savedApplication.Job.Specialized,
                    jobType = savedApplication.Job.JobType,
                    workingHours = savedApplication.Job.WorkingHours,
                    isActive = savedApplication.Job.IsActive,
                    createdAt = savedApplication.Job.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                    applicationCount = _context.Applications.Count(a => a.JobId == savedApplication.Job.Id && a.IsActive),
                    recruiter = savedApplication.Job.Recruiter != null ? new
                    {
                        id = savedApplication.Job.Recruiter.Id,
                        userName = savedApplication.Job.Recruiter.UserName,
                        email = savedApplication.Job.Recruiter.Email,
                        fullName = $"{savedApplication.Job.Recruiter.FirstName} {savedApplication.Job.Recruiter.LastName}".Trim(),
                        avatar = savedApplication.Job.Recruiter.Avatar,
                        role = savedApplication.Job.Recruiter.Role,
                        company = savedApplication.Job.Recruiter.Company != null ? new
                        {
                            id = savedApplication.Job.Recruiter.Company.Id,
                            name = savedApplication.Job.Recruiter.Company.Name,
                            description = savedApplication.Job.Recruiter.Company.Description,
                            isVerified = savedApplication.Job.Recruiter.Company.IsVerified
                        } : null
                    } : null
                } : null
            });
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetApplication(int id)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

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

            // Return application data that matches Flutter model structure
            return Ok(new
            {
                id = application.Id,
                applicantId = application.ApplicantId,
                jobId = application.JobId,
                cvUrl = application.CvUrl,
                coverLetter = application.CoverLetter,
                status = application.Status.ToString(),
                createdAt = application.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                isActive = application.IsActive,
                appliedAt = application.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                
                // Applicant data in the format Flutter expects
                applicant = new
                {
                    id = application.Applicant.Id,
                    userName = application.Applicant.UserName,
                    email = application.Applicant.Email,
                    firstName = application.Applicant.FirstName,
                    lastName = application.Applicant.LastName,
                    fullName = $"{application.Applicant.FirstName} {application.Applicant.LastName}".Trim(),
                    avatar = application.Applicant.Avatar,
                    role = application.Applicant.Role,
                    createdAt = application.Applicant.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                },
                
                // Legacy fields for backward compatibility
                applicantName = $"{application.Applicant.FirstName} {application.Applicant.LastName}".Trim(),
                applicantEmail = application.Applicant.Email,
                avatarUrl = application.Applicant.Avatar,
                
                // Job data in the format Flutter expects
                job = new
                {
                    id = application.Job.Id,
                    title = application.Job.Title,
                    description = application.Job.Description,
                    requirements = application.Job.Requirements,
                    benefits = application.Job.Benefits,
                    salary = application.Job.Salary,
                    workingHours = application.Job.WorkingHours,
                    location = application.Job.Location,
                    specialized = application.Job.Specialized,
                    jobType = application.Job.JobType,
                    experienceLevel = application.Job.ExperienceLevel,
                    deadLine = application.Job.DeadLine.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                    isActive = application.Job.IsActive,
                    createdAt = application.Job.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                    recruiter = new
                    {
                        id = application.Job.Recruiter.Id,
                        userName = application.Job.Recruiter.UserName,
                        email = application.Job.Recruiter.Email,
                        firstName = application.Job.Recruiter.FirstName,
                        lastName = application.Job.Recruiter.LastName,
                        fullName = $"{application.Job.Recruiter.FirstName} {application.Job.Recruiter.LastName}".Trim(),
                        avatar = application.Job.Recruiter.Avatar,
                        role = application.Job.Recruiter.Role,
                        createdAt = application.Job.Recruiter.CreatedAt.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"),
                        company = application.Job.Recruiter.Company != null ? new
                        {
                            id = application.Job.Recruiter.Company.Id,
                            name = application.Job.Recruiter.Company.Name,
                            description = application.Job.Recruiter.Company.Description,
                            isVerified = application.Job.Recruiter.Company.IsVerified
                        } : null
                    }
                },
                
                // Legacy fields for backward compatibility
                jobTitle = application.Job.Title,
                jobId_Legacy = application.Job.Id
            });
        }

        [HttpGet("my-applications")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyApplications(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            // Use the new helper method to get user info from JWT
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has candidate role
            if (userRole != "candidate")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xem đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
                });
            }

            var query = _context.Applications
                .Include(a => a.Applicant)
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
                ApplicantId = a.ApplicantId,
                JobId = a.JobId,
                CvUrl = a.CvUrl,
                CoverLetter = a.CoverLetter,
                Status = a.Status.ToString(),
                CreatedAt = a.CreatedAt,
                IsActive = a.IsActive,
                RejectionReason = a.RejectionReason,
                AppliedAt = a.CreatedAt, // Use CreatedAt as AppliedAt for now
                Applicant = a.Applicant != null ? new UserDto
                {
                    Id = a.Applicant.Id,
                    Email = a.Applicant.Email!,
                    FirstName = a.Applicant.FirstName,
                    LastName = a.Applicant.LastName,
                    Role = a.Applicant.Role,
                    Avatar = a.Applicant.Avatar,
                    CreatedAt = a.Applicant.CreatedAt
                } : null,
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
                    ApplicationCount = _context.Applications.Count(app => app.JobId == a.Job.Id && app.IsActive),
                    Recruiter = new UserDto
                    {
                        Id = a.Job.Recruiter.Id,
                        Email = a.Job.Recruiter.Email!,
                        FirstName = a.Job.Recruiter.FirstName,
                        LastName = a.Job.Recruiter.LastName,
                        Role = a.Job.Recruiter.Role,
                        Avatar = a.Job.Recruiter.Avatar,
                        CreatedAt = a.Job.Recruiter.CreatedAt,
                        Company = a.Job.Recruiter.Company != null ? new CompanyDto
                        {
                            Id = a.Job.Recruiter.Company.Id,
                            Name = a.Job.Recruiter.Company.Name,
                            Description = a.Job.Recruiter.Company.Description,
                            IsVerified = a.Job.Recruiter.Company.IsVerified
                        } : null
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


        [HttpGet("my-job-applications")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMyJobApplications(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? status = null,
            [FromQuery] int? jobId = null)
        {
            // Use the new helper method to get user info from JWT
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has recruiter role
            if (userRole != "recruiter")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem đơn ứng tuyển cho công việc của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
                });
            }

            // Build query to get all applications for jobs created by this recruiter
            var query = _context.Applications
                .Include(a => a.Applicant)
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(a => a.Job.RecruiterId == userId && a.IsActive);

            // Filter by specific job if provided
            if (jobId.HasValue)
            {
                query = query.Where(a => a.JobId == jobId.Value);
            }

            // Filter by status if provided
            if (!string.IsNullOrEmpty(status))
            {
                if (Enum.TryParse<ApplicationStatus>(status, true, out var statusEnum))
                {
                    query = query.Where(a => a.Status == statusEnum);
                }
            }

            var totalCount = await query.CountAsync();

            var applications = await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var applicationDtos = applications.Select(a => new ApplicationDto
            {
                Id = a.Id,
                ApplicantId = a.ApplicantId,
                JobId = a.JobId,
                CvUrl = a.CvUrl,
                CoverLetter = a.CoverLetter,
                Status = a.Status.ToString(),
                CreatedAt = a.CreatedAt,
                IsActive = a.IsActive,
                RejectionReason = a.RejectionReason,
                AppliedAt = a.CreatedAt,
                Applicant = a.Applicant != null ? new UserDto
                {
                    Id = a.Applicant.Id,
                    Email = a.Applicant.Email!,
                    FirstName = a.Applicant.FirstName,
                    LastName = a.Applicant.LastName,
                    Role = a.Applicant.Role,
                    Avatar = a.Applicant.Avatar,
                    CreatedAt = a.Applicant.CreatedAt
                } : null,
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
                    ApplicationCount = _context.Applications.Count(app => app.JobId == a.Job.Id && app.IsActive),
                    Recruiter = new UserDto
                    {
                        Id = a.Job.Recruiter.Id,
                        Email = a.Job.Recruiter.Email!,
                        FirstName = a.Job.Recruiter.FirstName,
                        LastName = a.Job.Recruiter.LastName,
                        Role = a.Job.Recruiter.Role,
                        Avatar = a.Job.Recruiter.Avatar,
                        CreatedAt = a.Job.Recruiter.CreatedAt,
                        Company = a.Job.Recruiter.Company != null ? new CompanyDto
                        {
                            Id = a.Job.Recruiter.Company.Id,
                            Name = a.Job.Recruiter.Company.Name,
                            Description = a.Job.Recruiter.Company.Description,
                            IsVerified = a.Job.Recruiter.Company.IsVerified
                        } : null
                    }
                }
            }).ToList();

            // Get summary statistics
            var totalApplications = await _context.Applications
                .Where(a => a.Job.RecruiterId == userId && a.IsActive)
                .CountAsync();

            var pendingCount = await _context.Applications
                .Where(a => a.Job.RecruiterId == userId && a.IsActive && a.Status == ApplicationStatus.Pending)
                .CountAsync();

            var acceptedCount = await _context.Applications
                .Where(a => a.Job.RecruiterId == userId && a.IsActive && a.Status == ApplicationStatus.Accepted)
                .CountAsync();

            var rejectedCount = await _context.Applications
                .Where(a => a.Job.RecruiterId == userId && a.IsActive && a.Status == ApplicationStatus.Rejected)
                .CountAsync();

            var jobsWithApplications = await _context.JobPosts
                .Where(j => j.RecruiterId == userId && j.IsActive)
                .Select(j => new
                {
                    id = j.Id,
                    title = j.Title,
                    applicationCount = j.Applications.Count(a => a.IsActive)
                })
                .Where(j => j.applicationCount > 0)
                .OrderByDescending(j => j.applicationCount)
                .ToListAsync();

            return Ok(new
            {
                data = applicationDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                summary = new
                {
                    totalApplications,
                    pendingCount,
                    acceptedCount,
                    rejectedCount,
                    jobsWithApplications
                },
                filters = new
                {
                    status = status,
                    jobId = jobId
                }
            });
        }

        [HttpPut("{id}/status")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateApplicationStatus(int id, [FromBody] UpdateApplicationStatusDto updateDto)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has recruiter role
            if (userRole != "recruiter")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể cập nhật trạng thái đơn ứng tuyển.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
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
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Bạn chỉ có thể cập nhật đơn ứng tuyển cho công việc của mình.",
                    errorCode = "NOT_JOB_OWNER"
                });
            }

            if (Enum.TryParse<ApplicationStatus>(updateDto.Status, out var status))
            {
                application.Status = status;
                application.UpdatedAt = DateTime.UtcNow;
                
                // Set rejection reason if status is Rejected
                if (status == ApplicationStatus.Rejected)
                {
                    application.RejectionReason = !string.IsNullOrEmpty(updateDto.RejectionReason) 
                        ? updateDto.RejectionReason 
                        : "Không đáp ứng yêu cầu công việc";
                }
                else
                {
                    // Clear rejection reason if status is not Rejected
                    application.RejectionReason = null;
                }
                
                await _context.SaveChangesAsync();
                
                return Ok(new { 
                    message = "Cập nhật trạng thái đơn ứng tuyển thành công",
                    status = status.ToString(),
                    rejectionReason = application.RejectionReason
                });
            }

            return BadRequest("Invalid status");
        }



        [HttpGet("job/{jobId}/applications")]
        [AllowAnonymous]
        public async Task<IActionResult> GetJobApplications(int jobId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has recruiter role
            if (userRole != "recruiter")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể xem đơn ứng tuyển cho công việc của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
                });
            }

            var jobPost = await _context.JobPosts.FindAsync(jobId);
            if (jobPost == null || jobPost.RecruiterId != userId)
            {
                return BadRequest(new
                {
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
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "AUTHENTICATION_REQUIRED"
                });
            }

            // Check if user has candidate role
            if (userRole != "candidate")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể xóa đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
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
        public async Task<IActionResult> UpdateApplication(int id, [FromBody] UpdateApplicationDto updateDto)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new
                {
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            // Check if user has candidate role
            if (userRole != "candidate")
            {
                return BadRequest(new
                {
                    message = "Không có quyền truy cập. Chỉ ứng viên mới có thể cập nhật đơn ứng tuyển của mình.",
                    errorCode = "INSUFFICIENT_PERMISSIONS",
                    userRole = userRole ?? "unknown"
                });
            }

            var application = await _context.Applications
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Include(a => a.Applicant)
                .FirstOrDefaultAsync(a => a.Id == id && a.ApplicantId == userId && a.IsActive);

            if (application == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn ứng tuyển" });
            }

            // Only allow update if status is Pending
            if (application.Status != ApplicationStatus.Pending)
            {
                return BadRequest(new { message = "Chỉ có thể cập nhật đơn ứng tuyển đang chờ xem xét" });
            }

            // Update cover letter if provided
            if (!string.IsNullOrEmpty(updateDto.CoverLetter))
            {
                application.CoverLetter = updateDto.CoverLetter;
            }

            // Update CV URL if provided
            if (!string.IsNullOrEmpty(updateDto.CvUrl))
            {
                application.CvUrl = updateDto.CvUrl;
            }

            application.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            // Return updated application using same mapping as GetApplication
            var applicationDto = new ApplicationDto
            {
                Id = application.Id,
                ApplicantId = application.ApplicantId,
                JobId = application.JobId,
                CvUrl = application.CvUrl,
                CoverLetter = application.CoverLetter ?? string.Empty,
                Status = application.Status.ToString().ToLower(),
                CreatedAt = application.CreatedAt,
                IsActive = application.IsActive,
                RejectionReason = application.RejectionReason,
                AppliedAt = application.AppliedAt,
                Job = application.Job != null ? new JobPostDto
                {
                    Id = application.Job.Id,
                    Title = application.Job.Title,
                    Description = application.Job.Description,
                    Location = application.Job.Location,
                    Salary = application.Job.Salary,
                    JobType = application.Job.JobType,
                    ExperienceLevel = application.Job.ExperienceLevel,
                    CreatedAt = application.Job.CreatedAt,
                    DeadLine = application.Job.DeadLine,
                    Recruiter = application.Job.Recruiter != null ? new UserDto
                    {
                        Id = application.Job.Recruiter.Id,
                        FirstName = application.Job.Recruiter.FirstName,
                        LastName = application.Job.Recruiter.LastName,
                        Email = application.Job.Recruiter.Email ?? string.Empty,
                        Role = application.Job.Recruiter.Role,
                        Avatar = application.Job.Recruiter.Avatar,
                        Company = application.Job.Recruiter.Company != null ? new CompanyDto
                        {
                            Id = application.Job.Recruiter.Company.Id,
                            Name = application.Job.Recruiter.Company.Name,
                            Description = application.Job.Recruiter.Company.Description,
                            Location = application.Job.Recruiter.Company.Location
                        } : null
                    } : new UserDto()
                } : null,
                Applicant = application.Applicant != null ? new UserDto
                {
                    Id = application.Applicant.Id,
                    FirstName = application.Applicant.FirstName,
                    LastName = application.Applicant.LastName,
                    Email = application.Applicant.Email ?? string.Empty,
                    Role = application.Applicant.Role,
                    Avatar = application.Applicant.Avatar
                } : null
            };

            return Ok(applicationDto);
        }

        // CV Analysis Methods
        private async Task AnalyzeCVForApplicationAsync(int applicationId, IFormFile cvFile, JobPost jobPost)
        {
            try
            {
                // Extract text from CV
                var cvText = await _cvProcessingService.ExtractTextFromCVAsync(cvFile);
                var cleanedText = _cvProcessingService.CleanExtractedText(cvText);

                // Prepare job details for AI analysis
                var jobDetails = new Dictionary<string, object>
                {
                    ["id"] = jobPost.Id,
                    ["title"] = jobPost.Title,
                    ["description"] = jobPost.Description,
                    ["requirements"] = jobPost.Requirements,
                    ["location"] = jobPost.Location,
                    ["salary"] = jobPost.Salary,
                    ["jobType"] = jobPost.JobType,
                    ["experienceLevel"] = jobPost.ExperienceLevel
                };

                // Analyze CV with AI
                var analysisResult = await _aiService.AnalyzeCVForJobAsync(cleanedText, jobDetails);

                // Save analysis result to database
                await SaveCVAnalysisResultAsync(applicationId, jobPost.Id, analysisResult);
            }
            catch (Exception)
            {
                // Log error but don't fail the application process
                // Consider using proper logging framework like ILogger in production
            }
        }

        private async Task AnalyzeCVFromUrlAsync(int applicationId, string cvUrl, JobPost jobPost)
        {
            try
            {
                // Extract text from CV URL
                var cvText = await _cvProcessingService.ExtractTextFromUrlAsync(cvUrl);
                var cleanedText = _cvProcessingService.CleanExtractedText(cvText ?? "");

                // Prepare job details for AI analysis
                var jobDetails = new Dictionary<string, object>
                {
                    ["id"] = jobPost.Id,
                    ["title"] = jobPost.Title,
                    ["description"] = jobPost.Description,
                    ["requirements"] = jobPost.Requirements,
                    ["location"] = jobPost.Location,
                    ["salary"] = jobPost.Salary,
                    ["jobType"] = jobPost.JobType,
                    ["experienceLevel"] = jobPost.ExperienceLevel
                };

                // Analyze CV with AI
                var analysisResult = await _aiService.AnalyzeCVForJobAsync(cleanedText ?? "", jobDetails);

                // Save analysis result to database
                await SaveCVAnalysisResultAsync(applicationId, jobPost.Id, analysisResult);
            }
            catch (Exception)
            {
                // Log error but don't fail the application process
            }
        }

        private async Task SaveCVAnalysisResultAsync(int applicationId, int jobId, Services.CVAnalysisResult analysisResult)
        {
            try
            {
                var application = await _context.Applications.FindAsync(applicationId);
                if (application == null) 
                {
                    return;
                }

                var dbAnalysisResult = new Models.CVAnalysisResult
                {
                    ApplicationId = applicationId,
                    JobId = jobId,
                    CandidateId = application.ApplicantId,
                    MatchScore = analysisResult.MatchScore,
                    ExtractedSkills = System.Text.Json.JsonSerializer.Serialize(analysisResult.CandidateInfo.Skills),
                    Strengths = System.Text.Json.JsonSerializer.Serialize(analysisResult.Strengths),
                    Weaknesses = System.Text.Json.JsonSerializer.Serialize(analysisResult.Weaknesses),
                    ImprovementSuggestions = System.Text.Json.JsonSerializer.Serialize(analysisResult.ImprovementSuggestions),
                    DetailedAnalysis = analysisResult.DetailedAnalysis,
                    AnalyzedAt = DateTime.UtcNow
                };

                _context.CVAnalysisResults.Add(dbAnalysisResult);
                await _context.SaveChangesAsync();
            }
            catch (Exception)
            {
                // Log error but don't fail the process
            }
        }

        // Get CV Analysis Result for a specific application
        [HttpGet("{id}/cv-analysis")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCVAnalysis(int id)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            // if (!isAuthenticated || string.IsNullOrEmpty(userId))
            // {
            //     return Unauthorized(new
            //     {
            //         message = "Không tìm thấy thông tin người dùng trong token",
            //         errorCode = "AUTHENTICATION_REQUIRED"
            //     });
            // }

            var application = await _context.Applications
                .Include(a => a.Job)
                .FirstOrDefaultAsync(a => a.Id == id);

            if (application == null)
            {
                return NotFound("Application not found");
            }

            // Check permissions
            if (userRole == "candidate" && application.ApplicantId != userId)
            {
                return Forbid("You can only view your own application analysis");
            }
            
            if (userRole == "recruiter" && application.Job.RecruiterId != userId)
            {
                return Forbid("You can only view analysis for your job applications");
            }

            var analysisResult = await _context.CVAnalysisResults
                .FirstOrDefaultAsync(c => c.ApplicationId == id);

            if (analysisResult == null)
            {
                // If no analysis exists yet, try to perform it on-demand when we have a CV URL
                if (!string.IsNullOrEmpty(application.CvUrl))
                {
                    _logger.LogInformation("No CV analysis found for application {ApplicationId}. Attempting on-demand analysis using CvUrl.", id);
                    try
                    {
                        // Perform analysis synchronously so caller gets a result if possible
                        await AnalyzeCVFromUrlAsync(application.Id, application.CvUrl, application.Job);

                        // Re-fetch analysis result after attempting analysis
                        analysisResult = await _context.CVAnalysisResults
                            .FirstOrDefaultAsync(c => c.ApplicationId == id);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "On-demand CV analysis failed for application {ApplicationId}", id);
                    }

                    if (analysisResult == null)
                    {
                        return Ok(new { message = "CV analysis is in progress or failed. Please check back later." });
                    }
                }
                else
                {
                    // No CV URL to analyze
                    return Ok(new { message = "CV analysis not available and no CV URL to analyze. Please upload a CV." });
                }
            }

            return Ok(new
            {
                applicationId = analysisResult.ApplicationId,
                matchScore = analysisResult.MatchScore,
                extractedSkills = System.Text.Json.JsonSerializer.Deserialize<List<string>>(analysisResult.ExtractedSkills ?? "[]"),
                strengths = System.Text.Json.JsonSerializer.Deserialize<List<string>>(analysisResult.Strengths ?? "[]"),
                weaknesses = System.Text.Json.JsonSerializer.Deserialize<List<string>>(analysisResult.Weaknesses ?? "[]"),
                improvementSuggestions = System.Text.Json.JsonSerializer.Deserialize<List<string>>(analysisResult.ImprovementSuggestions ?? "[]"),
                detailedAnalysis = analysisResult.DetailedAnalysis,
                analyzedAt = analysisResult.AnalyzedAt
            });
        }

        // Test endpoint to manually trigger CV analysis
        [HttpPost("{id}/trigger-cv-analysis")]
        [AllowAnonymous]
        public async Task<IActionResult> TriggerCVAnalysis(int id)
        {
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized("Authentication required");
            }

            var application = await _context.Applications
                .Include(a => a.Job)
                .FirstOrDefaultAsync(a => a.Id == id);

            if (application == null)
            {
                return NotFound("Application not found");
            }

            // Check permissions
            if (userRole == "recruiter" && application.Job.RecruiterId != userId)
            {
                return Forbid("You can only trigger analysis for your job applications");
            }

            if (string.IsNullOrEmpty(application.CvUrl))
            {
                return BadRequest("No CV URL found for this application");
            }

            try
            {
                await AnalyzeCVFromUrlAsync(application.Id, application.CvUrl, application.Job);
                return Ok(new { message = "CV analysis triggered successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Failed to trigger CV analysis", error = ex.Message });
            }
        }
    }
}
