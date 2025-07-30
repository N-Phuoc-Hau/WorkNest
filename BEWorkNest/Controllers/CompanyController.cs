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
    public class CompanyController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly CloudinaryService _cloudinaryService;

        public CompanyController(ApplicationDbContext context, CloudinaryService cloudinaryService)
        {
            _context = context;
            _cloudinaryService = cloudinaryService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllCompanies(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null)
        {
            var query = _context.Companies
                .Include(c => c.Images)
                .Include(c => c.User)
                .Where(c => c.IsActive);

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(c => c.Name.Contains(search) || c.Description.Contains(search));
            }

            var totalCount = await query.CountAsync();
            var companies = await query
                .OrderByDescending(c => c.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var companyDtos = companies.Select(c => new CompanyDto
            {
                Id = c.Id,
                Name = c.Name,
                TaxCode = c.TaxCode,
                Description = c.Description,
                Location = c.Location,
                IsVerified = c.IsVerified,
                Images = c.Images.Select(i => i.ImageUrl).ToList()
            }).ToList();

            return Ok(new
            {
                data = companyDtos,
                totalCount,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetCompany(int id)
        {
            var company = await _context.Companies
                .Include(c => c.Images)
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound();
            }

            var companyDto = new CompanyDto
            {
                Id = company.Id,
                Name = company.Name,
                TaxCode = company.TaxCode,
                Description = company.Description,
                Location = company.Location,
                IsVerified = company.IsVerified,
                Images = company.Images.Select(i => i.ImageUrl).ToList()
            };

            return Ok(companyDto);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> UpdateCompany(int id, [FromBody] UpdateCompanyDto updateDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId && c.IsActive);

            if (company == null)
            {
                return NotFound();
            }

            // Update fields
            if (!string.IsNullOrEmpty(updateDto.Name))
                company.Name = updateDto.Name;
            
            if (!string.IsNullOrEmpty(updateDto.Description))
                company.Description = updateDto.Description;
            
            if (!string.IsNullOrEmpty(updateDto.Location))
                company.Location = updateDto.Location;

            company.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Company updated successfully" });
        }

        [HttpPost("{id}/images")]
        [Authorize(Policy = "IsRecruiter")]
        public async Task<IActionResult> UploadCompanyImages(int id, [FromForm] List<IFormFile> images)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var company = await _context.Companies
                .Include(c => c.Images)
                .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId && c.IsActive);

            if (company == null)
            {
                return NotFound();
            }

            if (images == null || images.Count == 0)
            {
                return BadRequest("No images provided");
            }

            try
            {
                // Validate all files are images
                foreach (var image in images)
                {
                    if (!_cloudinaryService.IsImageFile(image))
                    {
                        return BadRequest($"File {image.FileName} is not a valid image file");
                    }
                }

                // Upload images to Cloudinary
                var imageUrls = await _cloudinaryService.UploadMultipleImagesAsync(images, "companies");

                // Delete old images from Cloudinary
                foreach (var oldImage in company.Images)
                {
                    var publicId = _cloudinaryService.GetPublicIdFromUrl(oldImage.ImageUrl);
                    if (!string.IsNullOrEmpty(publicId))
                    {
                        await _cloudinaryService.DeleteImageAsync(publicId);
                    }
                }

                // Remove old images from database
                _context.CompanyImages.RemoveRange(company.Images);

                // Add new images
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

                return Ok(new { message = "Images uploaded successfully", images = imageUrls });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Failed to upload images", error = ex.Message });
            }
        }

        [HttpGet("{id}/jobs")]
        public async Task<IActionResult> GetCompanyJobs(int id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound();
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
        public async Task<IActionResult> GetCompanyFollowers(int id)
        {
            var company = await _context.Companies
                .Include(c => c.User)
                .ThenInclude(u => u.Followers)
                .ThenInclude(f => f.Follower)
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (company == null)
            {
                return NotFound();
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

            return Ok(followers);
        }
    }
}
