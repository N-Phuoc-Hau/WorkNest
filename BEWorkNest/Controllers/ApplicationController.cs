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
        private readonly JwtService _jwtService;

        public ApplicationController(ApplicationDbContext context, CloudinaryService cloudinaryService, JwtService jwtService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
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
                            Console.WriteLine($"DEBUG: Extracted from JWT token - userId: {userId}, userRole: {userRole}");
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"DEBUG: Failed to extract from JWT token: {ex.Message}");
                        }
                    }
                }
            }

            Console.WriteLine($"DEBUG: GetUserInfoFromToken result - userId: {userId}, userRole: {userRole}, isAuthenticated: {isAuthenticated}");
            return (userId, userRole, isAuthenticated);
        }

        // Test endpoint to verify routing
        [HttpGet("test")]
        [AllowAnonymous]
        public IActionResult Test()
        {
            return Ok(new { message = "ApplicationController is working!", timestamp = DateTime.UtcNow });
        }

        // Debug endpoint to check database data
        [HttpGet("debug/data")]
        [AllowAnonymous]
        public async Task<IActionResult> DebugData()
        {
            try
            {
                var totalUsers = await _context.Users.CountAsync();
                var recruiters = await _context.Users.Where(u => u.Role == "recruiter").CountAsync();
                var candidates = await _context.Users.Where(u => u.Role == "candidate").CountAsync();
                var totalJobs = await _context.JobPosts.CountAsync();
                var activeJobs = await _context.JobPosts.Where(j => j.IsActive).CountAsync();
                var totalApplications = await _context.Applications.CountAsync();
                var activeApplications = await _context.Applications.Where(a => a.IsActive).CountAsync();

                // Get first recruiter for testing
                var firstRecruiter = await _context.Users.FirstOrDefaultAsync(u => u.Role == "recruiter");
                var recruiterJobsCount = firstRecruiter != null 
                    ? await _context.JobPosts.Where(j => j.RecruiterId == firstRecruiter.Id).CountAsync()
                    : 0;
                var recruiterApplicationsCount = firstRecruiter != null
                    ? await _context.Applications.Include(a => a.Job).Where(a => a.Job.RecruiterId == firstRecruiter.Id && a.IsActive).CountAsync()
                    : 0;

                return Ok(new
                {
                    database = "worknest_db",
                    users = new { total = totalUsers, recruiters, candidates },
                    jobs = new { total = totalJobs, active = activeJobs },
                    applications = new { total = totalApplications, active = activeApplications },
                    testRecruiter = firstRecruiter != null ? new
                    {
                        id = firstRecruiter.Id,
                        email = firstRecruiter.Email,
                        jobsCount = recruiterJobsCount,
                        applicationsCount = recruiterApplicationsCount
                    } : null
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, stackTrace = ex.StackTrace });
            }
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> CreateApplication([FromForm] CreateApplicationDto createDto)
        {
            string? userId = null;
            string? userRole = null;

            try
            {
                // Debug logging
                Console.WriteLine($"DEBUG: CreateApplication called with JobId: {createDto.JobId}");
                Console.WriteLine($"DEBUG: User.Identity.IsAuthenticated: {User.Identity?.IsAuthenticated}");
                Console.WriteLine($"DEBUG: User claims count: {User.Claims.Count()}");

                foreach (var claim in User.Claims)
                {
                    Console.WriteLine($"DEBUG: Claim {claim.Type}: {claim.Value}");
                }

                // Get real user ID from token
                userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                userRole = User.FindFirst("role")?.Value;

                Console.WriteLine($"DEBUG: UserId from token: {userId}");
                Console.WriteLine($"DEBUG: UserRole from token: {userRole}");

                // FOR TESTING: If no token, try to find any candidate user
                if (userId == null)
                {
                    Console.WriteLine("DEBUG: No token found, looking for any candidate user...");
                    var candidateUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "candidate");
                    if (candidateUser != null)
                    {
                        userId = candidateUser.Id;
                        userRole = "candidate";
                        Console.WriteLine($"DEBUG: Using test candidate user: {userId}");
                    }
                    else
                    {
                        Console.WriteLine("DEBUG: No candidate user found in database");
                        return BadRequest(new
                        {
                            message = "Không tìm thấy thông tin người dùng trong token và không có user candidate nào trong DB",
                            errorCode = "USER_ID_NOT_FOUND"
                        });
                    }
                }

                // Check if user has candidate role
                if (userRole != "candidate")
                {
                    Console.WriteLine($"DEBUG: User role '{userRole}' is not candidate - returning error");
                    return BadRequest(new
                    {
                        message = "Không có quyền truy cập. Chỉ ứng viên mới có thể nộp đơn ứng tuyển.",
                        errorCode = "INSUFFICIENT_PERMISSIONS",
                        userRole = userRole ?? "unknown"
                    });
                }

                Console.WriteLine("DEBUG: Authentication and authorization passed");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"DEBUG: Exception in CreateApplication: {ex.Message}");
                Console.WriteLine($"DEBUG: Exception stack trace: {ex.StackTrace}");
                return BadRequest(new { message = "Internal error", error = ex.Message });
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
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // FOR TESTING: If no token, try to find any user
            if (userId == null)
            {
                Console.WriteLine("DEBUG: No token found for GetApplication, looking for any user...");
                var anyUser = await _context.Users.FirstOrDefaultAsync();
                if (anyUser != null)
                {
                    userId = anyUser.Id;
                    userRole = anyUser.Role;
                    Console.WriteLine($"DEBUG: Using test user for GetApplication: {userId} with role {userRole}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No user found in database for GetApplication");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
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
            // Use the new helper method to get user info from JWT
            var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

            Console.WriteLine($"DEBUG: GetMyApplications - userId: {userId}, userRole: {userRole}, isAuthenticated: {isAuthenticated}");

            // FOR TESTING: If still no user found, try to find any candidate user
            if (string.IsNullOrEmpty(userId))
            {
                Console.WriteLine("DEBUG: No token found for my-applications, looking for any candidate user...");
                var candidateUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "candidate");
                if (candidateUser != null)
                {
                    userId = candidateUser.Id;
                    userRole = "candidate";
                    Console.WriteLine($"DEBUG: Using test candidate user for my-applications: {userId}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No candidate user found in database for my-applications");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user candidate nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
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

            Console.WriteLine($"DEBUG: GetMyJobApplications - userId: {userId}, userRole: {userRole}, isAuthenticated: {isAuthenticated}");

            // FOR TESTING: If still no user found, try to find any recruiter user
            if (string.IsNullOrEmpty(userId))
            {
                Console.WriteLine("DEBUG: No token or invalid token for GetMyJobApplications, looking for any recruiter user...");
                var recruiterUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "recruiter");
                if (recruiterUser != null)
                {
                    userId = recruiterUser.Id;
                    userRole = "recruiter";
                    Console.WriteLine($"DEBUG: Using test recruiter user for GetMyJobApplications: {userId}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No recruiter user found in database for GetMyJobApplications");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user recruiter nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
            }

            Console.WriteLine($"DEBUG: Final userId being used: {userId}, userRole: {userRole}");

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

            // Debug: Check if the recruiter has any job posts
            var recruiterJobCount = await _context.JobPosts
                .Where(j => j.RecruiterId == userId && j.IsActive)
                .CountAsync();
            Console.WriteLine($"DEBUG: Recruiter {userId} has {recruiterJobCount} active job posts");

            // Debug: Check total applications in DB
            var totalApplicationsInDb = await _context.Applications
                .Where(a => a.IsActive)
                .CountAsync();
            Console.WriteLine($"DEBUG: Total active applications in DB: {totalApplicationsInDb}");

            // Debug: Check applications for recruiter's jobs
            var recruiterApplicationCount = await _context.Applications
                .Include(a => a.Job)
                .Where(a => a.Job.RecruiterId == userId && a.IsActive)
                .CountAsync();
            Console.WriteLine($"DEBUG: Applications for recruiter {userId}'s jobs: {recruiterApplicationCount}");

            // Debug: Check what JobIds exist for this recruiter
            var recruiterJobIds = await _context.JobPosts
                .Where(j => j.RecruiterId == userId && j.IsActive)
                .Select(j => j.Id)
                .ToListAsync();
            Console.WriteLine($"DEBUG: Recruiter's job IDs: [{string.Join(", ", recruiterJobIds)}]");

            // Debug: Check all applications and their JobIds
            var allApplications = await _context.Applications
                .Where(a => a.IsActive)
                .Select(a => new { a.Id, a.JobId, a.ApplicantId })
                .ToListAsync();
            Console.WriteLine($"DEBUG: All active applications: {string.Join(", ", allApplications.Select(a => $"App#{a.Id}->Job#{a.JobId}"))}");

            // Debug: Check if any applications match recruiter's jobs
            var matchingApps = allApplications.Where(a => recruiterJobIds.Contains(a.JobId)).ToList();
            Console.WriteLine($"DEBUG: Matching applications: {matchingApps.Count} ({string.Join(", ", matchingApps.Select(a => $"App#{a.Id}"))})");

            // Debug: Check job ownership
            var jobOwnership = await _context.JobPosts
                .Where(j => j.IsActive)
                .Select(j => new { j.Id, j.RecruiterId, j.Title })
                .ToListAsync();
            Console.WriteLine($"DEBUG: All job ownership: {string.Join(", ", jobOwnership.Select(j => $"Job#{j.Id}->Recruiter#{j.RecruiterId} ({j.Title})"))}");
                

            // Build query to get all applications for jobs created by this recruiter
            var query = _context.Applications
                .Include(a => a.Applicant)
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(a => a.Job.RecruiterId == userId && a.IsActive);

            Console.WriteLine($"DEBUG: Query created for GetMyJobApplications");

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
            Console.WriteLine($"DEBUG: Total count from query: {totalCount}");

            var applications = await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            Console.WriteLine($"DEBUG: Retrieved {applications.Count} applications after pagination");

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
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // FOR TESTING: If no token, try to find any recruiter user
            if (userId == null)
            {
                Console.WriteLine("DEBUG: No token found for UpdateApplicationStatus, looking for any recruiter user...");
                var recruiterUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "recruiter");
                if (recruiterUser != null)
                {
                    userId = recruiterUser.Id;
                    userRole = "recruiter";
                    Console.WriteLine($"DEBUG: Using test recruiter user for UpdateApplicationStatus: {userId}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No recruiter user found in database for UpdateApplicationStatus");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user recruiter nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
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
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // FOR TESTING: If no token, try to find any recruiter user
            if (userId == null)
            {
                Console.WriteLine("DEBUG: No token found for GetJobApplications, looking for any recruiter user...");
                var recruiterUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "recruiter");
                if (recruiterUser != null)
                {
                    userId = recruiterUser.Id;
                    userRole = "recruiter";
                    Console.WriteLine($"DEBUG: Using test recruiter user for GetJobApplications: {userId}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No recruiter user found in database for GetJobApplications");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user recruiter nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
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
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

            // FOR TESTING: If no token, try to find any candidate user
            if (userId == null)
            {
                Console.WriteLine("DEBUG: No token found for DeleteApplication, looking for any candidate user...");
                var candidateUser = await _context.Users.FirstOrDefaultAsync(u => u.Role == "candidate");
                if (candidateUser != null)
                {
                    userId = candidateUser.Id;
                    userRole = "candidate";
                    Console.WriteLine($"DEBUG: Using test candidate user for DeleteApplication: {userId}");
                }
                else
                {
                    Console.WriteLine("DEBUG: No candidate user found in database for DeleteApplication");
                    return BadRequest(new
                    {
                        message = "Không tìm thấy thông tin người dùng trong token và không có user candidate nào trong DB",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }
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
    }
}
