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
    public class CompanyController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly CloudinaryService _cloudinaryService;
        private readonly JwtService _jwtService;

        public CompanyController(ApplicationDbContext context, CloudinaryService cloudinaryService, JwtService jwtService)
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
                        }
                        catch (Exception)
                        {
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCompanyById(int id)
        {
            var company = await _context.Companies
                .Include(c => c.Images)
                .Include(c => c.User)
                .Include(c => c.User.Followers)
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound(new { 
                    message = "Không tìm thấy công ty",
                    errorCode = "COMPANY_NOT_FOUND"
                });
            }

            var companyDto = new CompanyDto
            {
                Id = company.Id,
                UserId = company.UserId,
                Name = company.Name,
                TaxCode = company.TaxCode,
                Description = company.Description,
                Location = company.Location,
                IsVerified = company.IsVerified,
                Images = company.Images?.Select(img => img.ImageUrl).ToList() ?? new List<string>(),
                IsActive = company.IsActive,
                CreatedAt = company.CreatedAt,
                UpdatedAt = company.UpdatedAt
            };

            return Ok(companyDto);
        }

        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateCompany(int id, [FromBody] UpdateCompanyDto updateDto)
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
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể cập nhật thông tin công ty.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                var company = await _context.Companies
                    .Include(c => c.Images)
                    .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId && c.IsActive);

                if (company == null)
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy công ty hoặc bạn không có quyền cập nhật công ty này",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                // Update company
                if (updateDto.Name != null) company.Name = updateDto.Name;
                if (updateDto.TaxCode != null) company.TaxCode = updateDto.TaxCode;
                if (updateDto.Description != null) company.Description = updateDto.Description;
                if (updateDto.Location != null) company.Location = updateDto.Location;
                company.UpdatedAt = DateTime.Now;

                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Cập nhật thông tin công ty thành công",
                    data = new CompanyDto
                    {
                        Id = company.Id,
                        UserId = company.UserId,
                        Name = company.Name,
                        TaxCode = company.TaxCode,
                        Description = company.Description,
                        Location = company.Location,
                        IsVerified = company.IsVerified,
                        Images = company.Images?.Select(img => img.ImageUrl).ToList() ?? new List<string>(),
                        IsActive = company.IsActive,
                        CreatedAt = company.CreatedAt,
                        UpdatedAt = company.UpdatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi cập nhật thông tin công ty", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpPost("{id}/images")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadCompanyImages(int id, [FromForm] List<IFormFile> images)
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
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể upload ảnh công ty.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                // Step 4: Find Company
                var company = await _context.Companies
                    .Include(c => c.Images)
                    .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId && c.IsActive);

                if (company == null)
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy công ty hoặc bạn không có quyền upload ảnh cho công ty này",
                        errorCode = "COMPANY_NOT_FOUND"
                    });
                }

                // Step 5: Validate Images
                if (images == null || images.Count == 0)
                {
                    return BadRequest(new { 
                        message = "Không có hình ảnh nào được cung cấp",
                        errorCode = "NO_IMAGES_PROVIDED"
                    });
                }

                // Validate all files are images
                foreach (var image in images)
                {
                    if (!_cloudinaryService.IsImageFile(image))
                    {
                        return BadRequest(new { 
                            message = $"File {image.FileName} không phải là file hình ảnh hợp lệ",
                            errorCode = "INVALID_IMAGE_FILE"
                        });
                    }
                }

                // Step 6: Upload Images to Cloudinary
                var imageUrls = await _cloudinaryService.UploadMultipleImagesAsync(images, "companies");

                // Step 7: Delete old images from Cloudinary
                foreach (var oldImage in company.Images)
                {
                    var publicId = _cloudinaryService.GetPublicIdFromUrl(oldImage.ImageUrl);
                    if (!string.IsNullOrEmpty(publicId))
                    {
                        await _cloudinaryService.DeleteImageAsync(publicId);
                    }
                }

                // Step 8: Remove old images from database
                _context.CompanyImages.RemoveRange(company.Images);

                // Step 9: Add new images
                foreach (var imageUrl in imageUrls)
                {
                    var companyImage = new CompanyImage
                    {
                        CompanyId = company.Id,
                        ImageUrl = imageUrl
                    };
                    _context.CompanyImages.Add(companyImage);
                }

                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Upload ảnh công ty thành công", 
                    data = new {
                        companyId = company.Id,
                        companyName = company.Name,
                        uploadedBy = dbUser.Email,
                        uploadedAt = DateTime.Now,
                        images = imageUrls,
                        imageCount = imageUrls.Count
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi upload ảnh công ty", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> CreateCompany([FromBody] CreateCompanyDto createDto)
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
                        message = "Không có quyền truy cập. Chỉ nhà tuyển dụng mới có thể tạo công ty.",
                        errorCode = "INSUFFICIENT_PERMISSIONS"
                    });
                }

                // Check if user already has a company
                var existingCompany = await _context.Companies
                    .FirstOrDefaultAsync(c => c.UserId == userId && c.IsActive);

                if (existingCompany != null)
                {
                    return BadRequest(new { 
                        message = "Bạn đã có công ty trong hệ thống",
                        errorCode = "COMPANY_ALREADY_EXISTS"
                    });
                }

                // Create new company
                var company = new Company
                {
                    UserId = userId,
                    Name = createDto.Name,
                    TaxCode = createDto.TaxCode,
                    Description = createDto.Description,
                    Location = createDto.Location,
                    IsActive = true,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now
                };

                _context.Companies.Add(company);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    message = "Tạo công ty thành công",
                    data = new CompanyDto
                    {
                        Id = company.Id,
                        UserId = company.UserId,
                        Name = company.Name,
                        TaxCode = company.TaxCode,
                        Description = company.Description,
                        Location = company.Location,
                        IsVerified = company.IsVerified,
                        Images = new List<string>(),
                        IsActive = company.IsActive,
                        CreatedAt = company.CreatedAt,
                        UpdatedAt = company.UpdatedAt
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    message = "Lỗi hệ thống khi tạo công ty", 
                    error = ex.Message,
                    errorCode = "INTERNAL_SERVER_ERROR"
                });
            }
        }

        [HttpGet("{id}/jobs")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCompanyJobs(int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound(new { 
                    message = "Không tìm thấy công ty",
                    errorCode = "COMPANY_NOT_FOUND"
                });
            }

            var query = _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Where(j => j.Recruiter.Company!.Id == id && j.IsActive);

            var totalCount = await query.CountAsync();
            var jobs = await query
                .OrderByDescending(j => j.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var jobDtos = jobs.Select(j => new JobPostDto
            {
                Id = j.Id,
                Title = j.Title,
                Specialized = j.Specialized,
                Description = j.Description,
                Requirements = j.Requirements,
                Benefits = j.Benefits,
                Salary = j.Salary,
                WorkingHours = j.WorkingHours,
                Location = j.Location,
                JobType = j.JobType,
                ExperienceLevel = j.ExperienceLevel,
                DeadLine = j.DeadLine,
                CreatedAt = j.CreatedAt,
                ApplicationCount = j.Applications.Count(a => a.IsActive)
            }).ToList();

            return Ok(new
            {
                data = jobDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpGet("{id}/followers")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCompanyFollowers(int id)
        {
            var company = await _context.Companies
                .Include(c => c.User)
                .ThenInclude(u => u.Followers)
                .ThenInclude(f => f.Follower)
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound(new { 
                    message = "Không tìm thấy công ty",
                    errorCode = "COMPANY_NOT_FOUND"
                });
            }

            var followers = company.User.Followers
                .Where(f => f.IsActive)
                .Select(f => new UserDto
                {
                    Id = f.Follower.Id,
                    Email = f.Follower.Email!,
                    FirstName = f.Follower.FirstName,
                    LastName = f.Follower.LastName,
                    Role = f.Follower.Role,
                    Avatar = f.Follower.Avatar,
                    CreatedAt = f.Follower.CreatedAt
                })
                .ToList();

            return Ok(new { 
                data = followers,
                totalCount = followers.Count
            });
        }
    }
}
