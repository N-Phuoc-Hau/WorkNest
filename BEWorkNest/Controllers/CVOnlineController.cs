using System.Text.Json;
using BEWorkNest.Models;
using BEWorkNest.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class CVOnlineController : ControllerBase
    {
        private readonly ICVOnlineService _cvOnlineService;
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<CVOnlineController> _logger;
        private readonly Services.JwtService _jwtService;

        public CVOnlineController(
            ICVOnlineService cvOnlineService,
            ISubscriptionService subscriptionService,
            ILogger<CVOnlineController> logger,
            Services.JwtService jwtService)
        {
            _cvOnlineService = cvOnlineService;
            _subscriptionService = subscriptionService;
            _logger = logger;
            _jwtService = jwtService;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

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

        // Helper method to check CV builder feature access
        private async Task<bool> HasCVBuilderAccess(string userId)
        {
            try
            {
                return await _subscriptionService.CheckFeatureAccess(userId, "cv_builder");
            }
            catch
            {
                return false;
            }
        }

        // ==================== CV PROFILE ENDPOINTS ====================

        /// <summary>
        /// Get all CV profiles for current user
        /// </summary>
        [HttpGet("my-cvs")]
        public async Task<ActionResult<List<CVOnlineProfile>>> GetMyCVs()
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var cvs = await _cvOnlineService.GetUserCVProfiles(userId);
            return Ok(cvs);
        }

        /// <summary>
        /// Get specific CV profile by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<CVOnlineProfile>> GetCV(int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var cv = await _cvOnlineService.GetCVProfile(id, userId);
            if (cv == null)
            {
                return NotFound(new { message = "CV not found" });
            }

            return Ok(cv);
        }

        /// <summary>
        /// Get default CV
        /// </summary>
        [HttpGet("default")]
        public async Task<ActionResult<CVOnlineProfile>> GetDefaultCV()
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var cv = await _cvOnlineService.GetDefaultCV(userId);
            if (cv == null)
            {
                return NotFound(new { message = "No default CV found" });
            }

            return Ok(cv);
        }

        /// <summary>
        /// Create new CV profile (requires cv_builder feature)
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<CVOnlineProfile>> CreateCV([FromBody] CVOnlineProfile profile)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            // Check feature access (cho phép tạo CV miễn phí, chỉ log warning)
            var hasCVAccess = await HasCVBuilderAccess(userId);
            if (!hasCVAccess)
            {
                _logger.LogWarning($"User {userId} creating CV without cv_builder subscription - allowing free access");
            }

            try
            {
                var cv = await _cvOnlineService.CreateCVProfile(userId, profile);
                return CreatedAtAction(nameof(GetCV), new { id = cv.Id }, cv);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating CV");
                return StatusCode(500, new { message = "Error creating CV" });
            }
        }

        /// <summary>
        /// Update CV profile
        /// </summary>
        [HttpPut("{id}")]
        public async Task<ActionResult<CVOnlineProfile>> UpdateCV(int id, [FromBody] JsonElement body)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var cv = await _cvOnlineService.UpdateCVProfile(id, userId, body);
                return Ok(cv);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating CV");
                return StatusCode(500, new { message = "Error updating CV" });
            }
        }

        /// <summary>
        /// Delete CV profile
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteCV(int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.DeleteCVProfile(id, userId);
            if (!result)
            {
                return NotFound(new { message = "CV not found" });
            }

            return Ok(new { message = "CV deleted successfully" });
        }

        /// <summary>
        /// Set CV as default
        /// </summary>
        [HttpPost("{id}/set-default")]
        public async Task<ActionResult> SetDefaultCV(int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.SetDefaultCV(id, userId);
            if (!result)
            {
                return NotFound(new { message = "CV not found" });
            }

            return Ok(new { message = "Default CV updated" });
        }

        /// <summary>
        /// Toggle public access for CV
        /// </summary>
        [HttpPost("{id}/toggle-public")]
        public async Task<ActionResult> TogglePublicAccess(int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.TogglePublicAccess(id, userId);
            if (!result)
            {
                return NotFound(new { message = "CV not found" });
            }

            return Ok(new { message = "Public access updated" });
        }

        /// <summary>
        /// Get public CV by slug (no auth required)
        /// </summary>
        [HttpGet("public/{slug}")]
        [AllowAnonymous]
        public async Task<ActionResult<CVOnlineProfile>> GetPublicCV(string slug)
        {
            var cv = await _cvOnlineService.GetPublicCV(slug);
            if (cv == null)
            {
                return NotFound(new { message = "Public CV not found" });
            }

            return Ok(cv);
        }

        // ==================== WORK EXPERIENCE ENDPOINTS ====================

        [HttpPost("{cvId}/work-experience")]
        public async Task<ActionResult<CVWorkExperience>> AddWorkExperience(int cvId, [FromBody] CVWorkExperience experience)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.AddWorkExperience(cvId, userId, experience);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding work experience");
                return StatusCode(500, new { message = "Error adding work experience" });
            }
        }

        [HttpPut("{cvId}/work-experience/{id}")]
        public async Task<ActionResult<CVWorkExperience>> UpdateWorkExperience(int cvId, int id, [FromBody] CVWorkExperience experience)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.UpdateWorkExperience(id, cvId, userId, experience);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating work experience");
                return StatusCode(500, new { message = "Error updating work experience" });
            }
        }

        [HttpDelete("{cvId}/work-experience/{id}")]
        public async Task<ActionResult> DeleteWorkExperience(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.DeleteWorkExperience(id, cvId, userId);
            if (!result)
            {
                return NotFound(new { message = "Work experience not found" });
            }

            return Ok(new { message = "Work experience deleted" });
        }

        // ==================== EDUCATION ENDPOINTS ====================

        [HttpPost("{cvId}/education")]
        public async Task<ActionResult<CVEducation>> AddEducation(int cvId, [FromBody] CVEducation education)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.AddEducation(cvId, userId, education);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding education");
                return StatusCode(500, new { message = "Error adding education" });
            }
        }

        [HttpPut("{cvId}/education/{id}")]
        public async Task<ActionResult<CVEducation>> UpdateEducation(int cvId, int id, [FromBody] CVEducation education)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.UpdateEducation(id, cvId, userId, education);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating education");
                return StatusCode(500, new { message = "Error updating education" });
            }
        }

        [HttpDelete("{cvId}/education/{id}")]
        public async Task<ActionResult> DeleteEducation(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.DeleteEducation(id, cvId, userId);
            if (!result)
            {
                return NotFound(new { message = "Education not found" });
            }

            return Ok(new { message = "Education deleted" });
        }

        // ==================== SKILLS ENDPOINTS ====================

        [HttpPost("{cvId}/skill")]
        public async Task<ActionResult<CVSkill>> AddSkill(int cvId, [FromBody] CVSkill skill)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.AddSkill(cvId, userId, skill);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding skill");
                return StatusCode(500, new { message = "Error adding skill" });
            }
        }

        [HttpPut("{cvId}/skill/{id}")]
        public async Task<ActionResult<CVSkill>> UpdateSkill(int cvId, int id, [FromBody] CVSkill skill)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var result = await _cvOnlineService.UpdateSkill(id, cvId, userId, skill);
                return Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating skill");
                return StatusCode(500, new { message = "Error updating skill" });
            }
        }

        [HttpDelete("{cvId}/skill/{id}")]
        public async Task<ActionResult> DeleteSkill(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            var result = await _cvOnlineService.DeleteSkill(id, cvId, userId);
            if (!result)
            {
                return NotFound(new { message = "Skill not found" });
            }

            return Ok(new { message = "Skill deleted" });
        }

        // ==================== PROJECT, CERTIFICATION, LANGUAGE, REFERENCE ENDPOINTS ====================
        // Following same pattern as above...

        [HttpPost("{cvId}/project")]
        public async Task<ActionResult<CVProject>> AddProject(int cvId, [FromBody] CVProject project)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.AddProject(cvId, userId, project);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            } catch (Exception ex) {
                _logger.LogError(ex, "Error adding project");
                return StatusCode(500, new { message = "Error adding project" });
            }
        }

        [HttpPut("{cvId}/project/{id}")]
        public async Task<ActionResult<CVProject>> UpdateProject(int cvId, int id, [FromBody] CVProject project)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.UpdateProject(id, cvId, userId, project);
                return Ok(result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error updating project" });
            }
        }

        [HttpDelete("{cvId}/project/{id}")]
        public async Task<ActionResult> DeleteProject(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            var result = await _cvOnlineService.DeleteProject(id, cvId, userId);
            return result ? Ok(new { message = "Project deleted" }) : NotFound();
        }

        // Certifications
        [HttpPost("{cvId}/certification")]
        public async Task<ActionResult<CVCertification>> AddCertification(int cvId, [FromBody] CVCertification cert)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.AddCertification(cvId, userId, cert);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error adding certification" });
            }
        }

        [HttpPut("{cvId}/certification/{id}")]
        public async Task<ActionResult<CVCertification>> UpdateCertification(int cvId, int id, [FromBody] CVCertification cert)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.UpdateCertification(id, cvId, userId, cert);
                return Ok(result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error updating certification" });
            }
        }

        [HttpDelete("{cvId}/certification/{id}")]
        public async Task<ActionResult> DeleteCertification(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            var result = await _cvOnlineService.DeleteCertification(id, cvId, userId);
            return result ? Ok(new { message = "Certification deleted" }) : NotFound();
        }

        // Languages
        [HttpPost("{cvId}/language")]
        public async Task<ActionResult<CVLanguage>> AddLanguage(int cvId, [FromBody] CVLanguage language)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.AddLanguage(cvId, userId, language);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error adding language" });
            }
        }

        [HttpPut("{cvId}/language/{id}")]
        public async Task<ActionResult<CVLanguage>> UpdateLanguage(int cvId, int id, [FromBody] CVLanguage language)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.UpdateLanguage(id, cvId, userId, language);
                return Ok(result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error updating language" });
            }
        }

        [HttpDelete("{cvId}/language/{id}")]
        public async Task<ActionResult> DeleteLanguage(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            var result = await _cvOnlineService.DeleteLanguage(id, cvId, userId);
            return result ? Ok(new { message = "Language deleted" }) : NotFound();
        }

        // References
        [HttpPost("{cvId}/reference")]
        public async Task<ActionResult<CVReference>> AddReference(int cvId, [FromBody] CVReference reference)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.AddReference(cvId, userId, reference);
                return CreatedAtAction(nameof(GetCV), new { id = cvId }, result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error adding reference" });
            }
        }

        [HttpPut("{cvId}/reference/{id}")]
        public async Task<ActionResult<CVReference>> UpdateReference(int cvId, int id, [FromBody] CVReference reference)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            try {
                var result = await _cvOnlineService.UpdateReference(id, cvId, userId, reference);
                return Ok(result);
            } catch (Exception ex) {
                return StatusCode(500, new { message = "Error updating reference" });
            }
        }

        [HttpDelete("{cvId}/reference/{id}")]
        public async Task<ActionResult> DeleteReference(int cvId, int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Unauthorized" });

            var result = await _cvOnlineService.DeleteReference(id, cvId, userId);
            return result ? Ok(new { message = "Reference deleted" }) : NotFound();
        }

        // ==================== TEMPLATE ENDPOINTS ====================

        [HttpGet("templates")]
        [AllowAnonymous]
        public async Task<ActionResult<List<CVTemplate>>> GetTemplates([FromQuery] bool includePremium = false)
        {
            var templates = await _cvOnlineService.GetAvailableTemplates(includePremium);
            return Ok(templates);
        }

        [HttpGet("templates/{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<CVTemplate>> GetTemplate(int id)
        {
            var template = await _cvOnlineService.GetTemplate(id);
            if (template == null)
            {
                return NotFound(new { message = "Template not found" });
            }

            return Ok(template);
        }

        // ==================== EXPORT ENDPOINTS ====================

        [HttpGet("{id}/download")]
        public async Task<ActionResult> DownloadCV(int id)
        {
            var (userId, _, isAuthenticated) = GetUserInfoFromToken();
            if (!isAuthenticated || string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Unauthorized" });
            }

            try
            {
                var pdfUrl = await _cvOnlineService.GeneratePDFUrl(id, userId);
                return Ok(new { downloadUrl = pdfUrl });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error downloading CV");
                return StatusCode(500, new { message = "Error generating PDF" });
            }
        }
    }
}
