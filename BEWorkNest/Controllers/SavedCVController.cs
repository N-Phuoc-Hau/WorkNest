using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Services;
using BEWorkNest.Models;
using BEWorkNest.Data;
using System.Security.Claims;
using System.Text.Json;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Require authentication for all endpoints
    public class SavedCVController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly CVProcessingService _cvProcessingService;
        private readonly CVAnalysisService _cvAnalysisService;
        private readonly ILogger<SavedCVController> _logger;

        public SavedCVController(
            ApplicationDbContext context,
            CVProcessingService cvProcessingService,
            CVAnalysisService cvAnalysisService,
            ILogger<SavedCVController> logger)
        {
            _context = context;
            _cvProcessingService = cvProcessingService;
            _cvAnalysisService = cvAnalysisService;
            _logger = logger;
        }

        /// <summary>
        /// Get all saved CVs for the current user
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetSavedCVs()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCVs = await _context.SavedCVs
                    .Where(cv => cv.UserId == userId && cv.IsActive)
                    .OrderByDescending(cv => cv.IsDefault)
                    .ThenByDescending(cv => cv.LastUsedAt ?? cv.CreatedAt)
                    .ToListAsync();

                return Ok(new { success = true, data = savedCVs });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting saved CVs");
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi lấy danh sách CV đã lưu" 
                });
            }
        }

        /// <summary>
        /// Get a specific saved CV by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetSavedCV(int id)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCV = await _context.SavedCVs
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (savedCV == null)
                {
                    return NotFound(new { 
                        success = false, 
                        message = "Không tìm thấy CV" 
                    });
                }

                return Ok(new { success = true, data = savedCV });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting saved CV {Id}", id);
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi lấy thông tin CV" 
                });
            }
        }

        /// <summary>
        /// Save a CV file and extract information
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> SaveCV([FromForm] SaveCVRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                if (request.CVFile == null || request.CVFile.Length == 0)
                {
                    return BadRequest(new { 
                        success = false, 
                        message = "Vui lòng chọn file CV" 
                    });
                }

                // Validate file size (5MB limit)
                if (request.CVFile.Length > 5 * 1024 * 1024)
                {
                    return BadRequest(new { 
                        success = false, 
                        message = "File quá lớn. Kích thước tối đa 5MB" 
                    });
                }

                // Validate file type
                var allowedExtensions = new[] { ".pdf", ".doc", ".docx" };
                var fileExtension = Path.GetExtension(request.CVFile.FileName).ToLowerInvariant();
                
                if (!allowedExtensions.Contains(fileExtension))
                {
                    return BadRequest(new { 
                        success = false, 
                        message = "Chỉ chấp nhận file PDF, DOC, DOCX" 
                    });
                }

                // Check if setting as default when user already has a default CV
                if (request.IsDefault)
                {
                    var existingDefault = await _context.SavedCVs
                        .FirstOrDefaultAsync(cv => cv.UserId == userId && cv.IsDefault);
                    
                    if (existingDefault != null)
                    {
                        existingDefault.IsDefault = false;
                    }
                }

                // Generate unique filename
                var fileName = $"{userId}_{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine("uploads", "cvs", fileName);
                var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", filePath);

                // Ensure directory exists
                Directory.CreateDirectory(Path.GetDirectoryName(fullPath)!);

                // Save file
                using (var stream = new FileStream(fullPath, FileMode.Create))
                {
                    await request.CVFile.CopyToAsync(stream);
                }

                // Extract text from CV
                string extractedText = "";
                try
                {
                    extractedText = await _cvProcessingService.ExtractTextFromCVAsync(request.CVFile);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to extract text from CV file");
                }

                // Create saved CV record
                var savedCV = new SavedCV
                {
                    UserId = userId,
                    Name = request.Name,
                    Description = request.Description,
                    FilePath = filePath,
                    FileName = request.CVFile.FileName,
                    FileExtension = fileExtension,
                    FileSize = request.CVFile.Length,
                    ExtractedText = extractedText,
                    IsDefault = request.IsDefault,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Analyze CV if text was extracted
                if (!string.IsNullOrEmpty(extractedText))
                {
                    try
                    {
                        var analysisResult = await _cvAnalysisService.AnalyzeCVTextAsync(userId, extractedText);
                        
                        savedCV.Skills = JsonSerializer.Serialize(analysisResult.Profile.Skills);
                        savedCV.WorkExperience = JsonSerializer.Serialize(analysisResult.Profile.WorkHistory);
                        savedCV.Education = JsonSerializer.Serialize(new List<object>()); // Empty for now
                        savedCV.Projects = JsonSerializer.Serialize(analysisResult.Profile.Projects);
                        savedCV.Certifications = JsonSerializer.Serialize(analysisResult.Profile.Certifications);
                        savedCV.Languages = JsonSerializer.Serialize(analysisResult.Profile.Languages);
                        savedCV.ExperienceYears = analysisResult.Profile.ExperienceYears;
                        savedCV.OverallScore = analysisResult.Scores.OverallScore;
                        savedCV.AnalysisResult = JsonSerializer.Serialize(analysisResult);
                        savedCV.LastAnalyzedAt = DateTime.UtcNow;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to analyze CV during save");
                    }
                }

                _context.SavedCVs.Add(savedCV);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = "CV đã được lưu thành công",
                    data = savedCV
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving CV");
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi lưu CV" 
                });
            }
        }

        /// <summary>
        /// Update saved CV information
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateSavedCV(int id, [FromBody] UpdateSavedCVRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCV = await _context.SavedCVs
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (savedCV == null)
                {
                    return NotFound(new { 
                        success = false, 
                        message = "Không tìm thấy CV" 
                    });
                }

                // Update fields if provided
                if (!string.IsNullOrEmpty(request.Name))
                {
                    savedCV.Name = request.Name;
                }

                if (request.Description != null)
                {
                    savedCV.Description = request.Description;
                }

                if (request.IsDefault.HasValue)
                {
                    if (request.IsDefault.Value)
                    {
                        // Remove default from other CVs
                        var otherDefaults = await _context.SavedCVs
                            .Where(cv => cv.UserId == userId && cv.Id != id && cv.IsDefault)
                            .ToListAsync();

                        foreach (var cv in otherDefaults)
                        {
                            cv.IsDefault = false;
                        }
                    }
                    savedCV.IsDefault = request.IsDefault.Value;
                }

                if (request.IsActive.HasValue)
                {
                    savedCV.IsActive = request.IsActive.Value;
                }

                savedCV.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = "CV đã được cập nhật",
                    data = savedCV
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating saved CV {Id}", id);
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi cập nhật CV" 
                });
            }
        }

        /// <summary>
        /// Delete a saved CV
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSavedCV(int id)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCV = await _context.SavedCVs
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (savedCV == null)
                {
                    return NotFound(new { 
                        success = false, 
                        message = "Không tìm thấy CV" 
                    });
                }

                // Check if CV is being used in applications
                var applicationsCount = await _context.Applications
                    .CountAsync(app => app.CvUrl != null && app.CvUrl.Contains(savedCV.FileName));

                if (applicationsCount > 0)
                {
                    return BadRequest(new { 
                        success = false, 
                        message = $"CV này đang được sử dụng trong {applicationsCount} đơn ứng tuyển. Không thể xóa." 
                    });
                }

                // Delete physical file
                try
                {
                    var fullPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", savedCV.FilePath);
                    if (System.IO.File.Exists(fullPath))
                    {
                        System.IO.File.Delete(fullPath);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete CV file {FilePath}", savedCV.FilePath);
                }

                _context.SavedCVs.Remove(savedCV);
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = "CV đã được xóa" 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting saved CV {Id}", id);
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi xóa CV" 
                });
            }
        }

        /// <summary>
        /// Re-analyze a saved CV
        /// </summary>
        [HttpPost("{id}/analyze")]
        public async Task<IActionResult> ReanalyzeSavedCV(int id)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCV = await _context.SavedCVs
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (savedCV == null)
                {
                    return NotFound(new { 
                        success = false, 
                        message = "Không tìm thấy CV" 
                    });
                }

                if (string.IsNullOrEmpty(savedCV.ExtractedText))
                {
                    return BadRequest(new { 
                        success = false, 
                        message = "CV không có nội dung text để phân tích" 
                    });
                }

                // Re-analyze CV
                var analysisResult = await _cvAnalysisService.AnalyzeCVTextAsync(userId, savedCV.ExtractedText);

                // Update saved CV with new analysis
                savedCV.Skills = JsonSerializer.Serialize(analysisResult.Profile.Skills);
                savedCV.WorkExperience = JsonSerializer.Serialize(analysisResult.Profile.WorkHistory);
                savedCV.Projects = JsonSerializer.Serialize(analysisResult.Profile.Projects);
                savedCV.Certifications = JsonSerializer.Serialize(analysisResult.Profile.Certifications);
                savedCV.Languages = JsonSerializer.Serialize(analysisResult.Profile.Languages);
                savedCV.ExperienceYears = analysisResult.Profile.ExperienceYears;
                savedCV.OverallScore = analysisResult.Scores.OverallScore;
                savedCV.AnalysisResult = JsonSerializer.Serialize(analysisResult);
                savedCV.LastAnalyzedAt = DateTime.UtcNow;
                savedCV.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = "CV đã được phân tích lại",
                    data = new {
                        savedCV = savedCV,
                        analysisResult = analysisResult
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error re-analyzing saved CV {Id}", id);
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi phân tích lại CV" 
                });
            }
        }

        /// <summary>
        /// Mark a CV as used (for tracking usage)
        /// </summary>
        [HttpPost("{id}/use")]
        public async Task<IActionResult> MarkCVAsUsed(int id)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var savedCV = await _context.SavedCVs
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (savedCV == null)
                {
                    return NotFound(new { 
                        success = false, 
                        message = "Không tìm thấy CV" 
                    });
                }

                savedCV.UsageCount++;
                savedCV.LastUsedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(new { 
                    success = true, 
                    message = "Đã cập nhật thống kê sử dụng CV" 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking CV as used {Id}", id);
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi cập nhật thống kê" 
                });
            }
        }

        /// <summary>
        /// Get user's CV statistics
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetCVStats()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var stats = await _context.SavedCVs
                    .Where(cv => cv.UserId == userId && cv.IsActive)
                    .GroupBy(cv => cv.UserId)
                    .Select(g => new
                    {
                        TotalCVs = g.Count(),
                        TotalUsage = g.Sum(cv => cv.UsageCount),
                        AverageScore = g.Any(cv => cv.OverallScore.HasValue) ? (double)g.Where(cv => cv.OverallScore.HasValue).Average(cv => cv.OverallScore!.Value) : 0.0,
                        HighestScore = g.Any(cv => cv.OverallScore.HasValue) ? (int)g.Where(cv => cv.OverallScore.HasValue).Max(cv => cv.OverallScore!.Value) : 0,
                        LastUploadDate = g.Max(cv => cv.CreatedAt),
                        DefaultCVId = g.Where(cv => cv.IsDefault).Select(cv => cv.Id).FirstOrDefault()
                    })
                    .FirstOrDefaultAsync();

                if (stats == null)
                {
                    stats = new
                    {
                        TotalCVs = 0,
                        TotalUsage = 0,
                        AverageScore = 0.0,
                        HighestScore = 0,
                        LastUploadDate = DateTime.MinValue,
                        DefaultCVId = 0
                    };
                }

                return Ok(new { success = true, data = stats });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting CV stats");
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi khi lấy thống kê CV" 
                });
            }
        }
    }

    // Request DTOs
    public class SaveCVRequest
    {
        public IFormFile CVFile { get; set; } = null!;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsDefault { get; set; } = false;
    }

    public class UpdateSavedCVRequest
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public bool? IsDefault { get; set; }
        public bool? IsActive { get; set; }
    }
}