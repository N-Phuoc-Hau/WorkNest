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

        public JobPostController(JobPostService jobPostService, ApplicationDbContext context, JwtService jwtService)
        {
            _jobPostService = jobPostService;
            _context = context;
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
                            Console.WriteLine($"DEBUG: Failed to extract from JWT token: {ex.Message}");
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

        // Simple test endpoint
        [HttpGet("test")]
        [AllowAnonymous]
        public IActionResult Test()
        {
            return Ok(new { message = "JobPostController is working", timestamp = DateTime.Now });
        }

        // Debug endpoint to test authentication
        [HttpGet("debug-auth")]
        [Authorize]
        public async Task<IActionResult> DebugAuth()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            var roleCustom = User.FindFirst("role")?.Value;

            var allClaims = User.Claims.Select(c => new { Type = c.Type, Value = c.Value }).ToArray();

            // Try to find user in database
            User? dbUser = null;
            if (!string.IsNullOrEmpty(userId))
            {
                dbUser = await _context.Users.FindAsync(userId);
            }

            return Ok(new
            {
                tokenInfo = new
                {
                    userId,
                    userRole,
                    userEmail,
                    roleCustom,
                    isAuthenticated = User.Identity?.IsAuthenticated ?? false
                },
                dbUser = dbUser != null ? new
                {
                    id = dbUser.Id,
                    email = dbUser.Email,
                    role = dbUser.Role,
                    firstName = dbUser.FirstName,
                    lastName = dbUser.LastName,
                    isActive = dbUser.IsActive
                } : null,
                allClaims
            });
        }

        // Simple POST test without auth
        [HttpPost("test")]
        [AllowAnonymous]
        public IActionResult TestPost([FromBody] object data)
        {
            return Ok(new
            {
                message = "POST is working",
                receivedData = data,
                timestamp = DateTime.Now
            });
        }

        // Test endpoint with auth but no data
        [HttpPost("test-auth-only")]
        [Authorize]
        public IActionResult TestAuthOnly()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            
            return Ok(new
            {
                message = "Auth-only test successful",
                userId,
                userRole,
                userEmail,
                isAuthenticated = User.Identity?.IsAuthenticated ?? false,
                timestamp = DateTime.Now
            });
        }

        // Test endpoint with auth and simple data
        [HttpPost("test-auth-simple")]
        [Authorize]
        public IActionResult TestAuthSimple([FromBody] object data)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            
            return Ok(new
            {
                message = "Auth + simple data test successful",
                userId,
                userRole,
                userEmail,
                isAuthenticated = User.Identity?.IsAuthenticated ?? false,
                receivedData = data,
                timestamp = DateTime.Now
            });
        }

        // Test endpoint with recruiter policy and simple data
        [HttpPost("test-recruiter-simple")]
        [AllowAnonymous]
        public IActionResult TestRecruiterSimple([FromBody] object data)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            
            return Ok(new
            {
                message = "Recruiter policy + simple data test successful",
                userId,
                userRole,
                userEmail,
                isAuthenticated = User.Identity?.IsAuthenticated ?? false,
                receivedData = data,
                timestamp = DateTime.Now
            });
        }

        // Quick job post creation for testing
        [HttpPost("quick")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateQuickJobPost([FromBody] object data)
        {
            try
            {
                // Create a simple job post with hardcoded data
                var createDto = new CreateJobPostDto
                {
                    Title = "Quick Test Job",
                    Specialized = "Test",
                    Description = "This is a quick test job post",
                    Requirements = "Basic requirements",
                    Benefits = "Good benefits",
                    Salary = 10000000,
                    WorkingHours = "9:00 - 18:00",
                    Location = "Test Location",
                    JobType = "Full-time",
                    ExperienceLevel = "Entry Level",
                    DeadLine = DateTime.UtcNow.AddDays(30)
                };

                // Use your user ID from JWT
                var recruiterId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a";

                var (success, message, jobId) = await _jobPostService.CreateJobPostAsync(createDto, recruiterId);

                return Ok(new
                {
                    message = "Quick job post creation test",
                    success,
                    messageFromService = message,
                    jobId,
                    receivedData = data,
                    createdJob = createDto,
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Error in quick job creation",
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        // Simple POST without auth for testing
        [HttpPost("simple")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateJobPostSimple([FromBody] CreateJobPostDto createDto)
        {
            try
            {
                // Debug info
                var debugInfo = new
                {
                    receivedData = createDto,
                    timestamp = DateTime.Now,
                    modelState = ModelState.IsValid,
                    modelStateErrors = ModelState
                        .Where(x => x.Value?.Errors.Count > 0)
                        .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) })
                        .ToArray()
                };

                // Validate model
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        message = "Validation failed",
                        debugInfo
                    });
                }

                // Use a dummy recruiter ID for testing
                var dummyRecruiterId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a"; // Your user ID from JWT

                var (success, message, jobId) = await _jobPostService.CreateJobPostAsync(createDto, dummyRecruiterId);

                if (success)
                {
                    return Ok(new
                    {
                        message,
                        jobId,
                        debugInfo
                    });
                }

                return BadRequest(new { message, debugInfo });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Internal server error",
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }

        // Complete integrated test endpoint with authentication and job creation
        [HttpPost("test-auth-create")]
        [AllowAnonymous]
        public async Task<IActionResult> TestAuthAndCreate([FromBody] CreateJobPostDto? createDto = null)
        {
            try
            {
                                 // Step 1: Authentication Check (Optional for testing)
                 var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
                 var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                 var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
                 var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
                 var customRole = User.FindFirst("role")?.Value;
                 var allClaims = User.Claims.Select(c => new { Type = c.Type, Value = c.Value }).ToArray();

                 var step1Result = new {
                     success = true, // Always pass for testing
                     message = isAuthenticated ? "✅ User is authenticated" : "⚠️ No authentication (testing mode)",
                     details = new {
                         isAuthenticated,
                         userId,
                         userRole,
                         userEmail,
                         customRole,
                         totalClaims = allClaims.Length,
                         allClaims
                     }
                 };

                 // Use fixed recruiter ID for testing if no authentication
                 if (string.IsNullOrEmpty(userId))
                 {
                     userId = "b902ce1d-2e36-4ac2-9332-216dbf7aeb2a"; // Your recruiter ID
                 }

                                 // Step 2: Authorization Check (Role) - Optional for testing
                 var hasRecruiterRole = userRole == "recruiter" || customRole == "recruiter";
                 var step2Result = new {
                     success = true, // Always pass for testing
                     message = hasRecruiterRole ? "✅ User has recruiter role" : "⚠️ Using fixed recruiter ID (testing mode)",
                     details = new {
                         expectedRole = "recruiter",
                         actualStandardRole = userRole,
                         actualCustomRole = customRole,
                         hasRecruiterRole,
                         usingFixedId = !hasRecruiterRole
                     }
                 };

                // Step 3: Database User Validation
                User? dbUser = null;
                if (!string.IsNullOrEmpty(userId))
                {
                    dbUser = await _context.Users
                        .Include(u => u.Company)
                        .FirstOrDefaultAsync(u => u.Id == userId);
                }

                var step3Result = new {
                    success = dbUser != null,
                    message = dbUser != null ? "✅ User found in database" : "❌ User not found in database",
                    details = new {
                        searchedUserId = userId,
                        userExists = dbUser != null,
                        dbUserInfo = dbUser != null ? new {
                            id = dbUser.Id,
                            email = dbUser.Email,
                            role = dbUser.Role,
                            firstName = dbUser.FirstName,
                            lastName = dbUser.LastName,
                            isActive = dbUser.IsActive,
                            hasCompany = dbUser.Company != null,
                            companyId = dbUser.Company?.Id,
                            companyName = dbUser.Company?.Name
                        } : null
                    }
                };

                if (dbUser == null)
                {
                    return BadRequest(new { 
                        timestamp = DateTime.Now,
                        step1_authentication = step1Result,
                        step2_authorization = step2Result,
                        step3_userValidation = step3Result
                    });
                }

                // Step 4: Data Validation
                if (createDto == null)
                {
                    createDto = new CreateJobPostDto
                    {
                        Title = $"Test Job - {DateTime.Now:yyyy-MM-dd HH:mm:ss}",
                        Specialized = "Software Development",
                        Description = "This is a test job post created through the integrated test endpoint.",
                        Requirements = "- Programming experience\n- Problem-solving skills",
                        Benefits = "- Competitive salary\n- Health insurance",
                        Salary = 15000000,
                        WorkingHours = "9:00 AM - 6:00 PM",
                        Location = "Ho Chi Minh City, Vietnam",
                        JobType = "Full-time",
                        ExperienceLevel = "Mid Level",
                        DeadLine = DateTime.UtcNow.AddDays(30)
                    };
                }

                var validationResults = new List<string>();
                if (string.IsNullOrWhiteSpace(createDto.Title))
                    validationResults.Add("Title is required");
                if (string.IsNullOrWhiteSpace(createDto.Description))
                    validationResults.Add("Description is required");
                if (createDto.Salary <= 0)
                    validationResults.Add("Salary must be greater than 0");
                if (createDto.DeadLine <= DateTime.UtcNow)
                    validationResults.Add("Deadline must be in the future");

                var isDataValid = validationResults.Count == 0 && ModelState.IsValid;
                var modelStateErrors = ModelState
                    .Where(x => x.Value?.Errors.Count > 0)
                    .Select(x => new { Field = x.Key, Errors = x.Value?.Errors.Select(e => e.ErrorMessage) })
                    .ToArray();

                var step4Result = new {
                    success = isDataValid,
                    message = isDataValid ? "✅ Data validation passed" : "❌ Data validation failed",
                    details = new {
                        modelStateValid = ModelState.IsValid,
                        customValidationPassed = validationResults.Count == 0,
                        modelStateErrors,
                        customValidationErrors = validationResults,
                        providedData = createDto
                    }
                };

                if (!isDataValid)
                {
                    return BadRequest(new { 
                        timestamp = DateTime.Now,
                        step1_authentication = step1Result,
                        step2_authorization = step2Result,
                        step3_userValidation = step3Result,
                        step4_dataValidation = step4Result
                    });
                }

                // Step 5: Job Creation
                var (success, message, jobId) = await _jobPostService.CreateJobPostAsync(createDto, userId!);

                var step5Result = new {
                    success,
                    message = success ? $"✅ Job created successfully: {message}" : $"❌ Job creation failed: {message}",
                    details = new {
                        serviceSuccess = success,
                        serviceMessage = message,
                        createdJobId = jobId,
                        recruiterId = userId
                    }
                };

                // Final Result
                var overallSuccess = step1Result.success && 
                                   step2Result.success && 
                                   step3Result.success && 
                                   step4Result.success && 
                                   step5Result.success;

                var finalResult = new {
                    overallSuccess,
                    message = overallSuccess ? 
                        "✅ Complete test passed! Job post created successfully with full authentication." :
                        "❌ Test failed at one or more steps. Check details above.",
                    createdJobId = success ? jobId : null,
                    nextSteps = overallSuccess ? 
                        new[] { 
                            "Test GET /api/JobPost to verify job appears",
                            "Test UPDATE endpoint with the created job ID",
                            "Try the same endpoint without authentication to verify security"
                        } :
                        new[] { 
                            "Fix the failed steps above",
                            "Ensure database migrations are applied",
                            "Verify JWT token is valid and not expired"
                        }
                };

                var testResult = new {
                    timestamp = DateTime.Now,
                    step1_authentication = step1Result,
                    step2_authorization = step2Result,
                    step3_userValidation = step3Result,
                    step4_dataValidation = step4Result,
                    step5_jobCreation = step5Result,
                    finalResult = finalResult
                };

                return success ? Ok(testResult) : BadRequest(testResult);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    timestamp = DateTime.Now,
                    message = "❌ Internal server error during integrated test", 
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
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
