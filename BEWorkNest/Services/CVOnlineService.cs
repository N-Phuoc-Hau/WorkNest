using System.Text.Json;
using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Services
{
    public interface ICVOnlineService
    {
        // CV Profile CRUD
        Task<CVOnlineProfile> CreateCVProfile(string userId, CVOnlineProfile profile);
        Task<CVOnlineProfile?> GetCVProfile(int id, string userId);
        Task<List<CVOnlineProfile>> GetUserCVProfiles(string userId);
        Task<CVOnlineProfile?> GetDefaultCV(string userId);
        Task<CVOnlineProfile?> GetPublicCV(string slug);
        Task<CVOnlineProfile> UpdateCVProfile(int id, string userId, JsonElement data);
        Task<bool> DeleteCVProfile(int id, string userId);
        Task<bool> SetDefaultCV(int id, string userId);
        Task<bool> TogglePublicAccess(int id, string userId);
        
        // Work Experience
        Task<CVWorkExperience> AddWorkExperience(int cvId, string userId, CVWorkExperience experience);
        Task<CVWorkExperience> UpdateWorkExperience(int id, int cvId, string userId, CVWorkExperience experience);
        Task<bool> DeleteWorkExperience(int id, int cvId, string userId);
        
        // Education
        Task<CVEducation> AddEducation(int cvId, string userId, CVEducation education);
        Task<CVEducation> UpdateEducation(int id, int cvId, string userId, CVEducation education);
        Task<bool> DeleteEducation(int id, int cvId, string userId);
        
        // Skills
        Task<CVSkill> AddSkill(int cvId, string userId, CVSkill skill);
        Task<CVSkill> UpdateSkill(int id, int cvId, string userId, CVSkill skill);
        Task<bool> DeleteSkill(int id, int cvId, string userId);
        
        // Projects
        Task<CVProject> AddProject(int cvId, string userId, CVProject project);
        Task<CVProject> UpdateProject(int id, int cvId, string userId, CVProject project);
        Task<bool> DeleteProject(int id, int cvId, string userId);
        
        // Certifications
        Task<CVCertification> AddCertification(int cvId, string userId, CVCertification certification);
        Task<CVCertification> UpdateCertification(int id, int cvId, string userId, CVCertification certification);
        Task<bool> DeleteCertification(int id, int cvId, string userId);
        
        // Languages
        Task<CVLanguage> AddLanguage(int cvId, string userId, CVLanguage language);
        Task<CVLanguage> UpdateLanguage(int id, int cvId, string userId, CVLanguage language);
        Task<bool> DeleteLanguage(int id, int cvId, string userId);
        
        // References
        Task<CVReference> AddReference(int cvId, string userId, CVReference reference);
        Task<CVReference> UpdateReference(int id, int cvId, string userId, CVReference reference);
        Task<bool> DeleteReference(int id, int cvId, string userId);
        
        // Templates
        Task<List<CVTemplate>> GetAvailableTemplates(bool includePremium = false);
        Task<CVTemplate?> GetTemplate(int id);
        
        // Export/Download
        Task<string> GeneratePDFUrl(int cvId, string userId);
        Task<bool> IncrementViewCount(int cvId);
        Task<bool> IncrementDownloadCount(int cvId);
    }

    public class CVOnlineService : ICVOnlineService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CVOnlineService> _logger;

        public CVOnlineService(ApplicationDbContext context, ILogger<CVOnlineService> logger)
        {
            _context = context;
            _logger = logger;
        }

        // ==================== CV PROFILE CRUD ====================

        public async Task<CVOnlineProfile> CreateCVProfile(string userId, CVOnlineProfile profile)
        {
            try
            {
                profile.UserId = userId;
                profile.CreatedAt = DateTime.UtcNow;
                profile.UpdatedAt = DateTime.UtcNow;
                
                // Generate unique slug for public access
                if (profile.IsPublic && string.IsNullOrEmpty(profile.PublicSlug))
                {
                    profile.PublicSlug = await GenerateUniqueSlug(profile.Title);
                }

                _context.CVOnlineProfiles.Add(profile);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Created CV profile {profile.Id} for user {userId}");
                return profile;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating CV profile for user {userId}");
                throw;
            }
        }

        public async Task<CVOnlineProfile?> GetCVProfile(int id, string userId)
        {
            try
            {
                return await _context.CVOnlineProfiles
                    .Include(cv => cv.WorkExperiences.OrderBy(w => w.DisplayOrder))
                    .Include(cv => cv.Educations.OrderBy(e => e.DisplayOrder))
                    .Include(cv => cv.Skills.OrderBy(s => s.DisplayOrder))
                    .Include(cv => cv.Projects.OrderBy(p => p.DisplayOrder))
                    .Include(cv => cv.Certifications.OrderBy(c => c.DisplayOrder))
                    .Include(cv => cv.Languages.OrderBy(l => l.DisplayOrder))
                    .Include(cv => cv.References.OrderBy(r => r.DisplayOrder))
                    .Include(cv => cv.Template)
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting CV profile {id} for user {userId}");
                return null;
            }
        }

        public async Task<List<CVOnlineProfile>> GetUserCVProfiles(string userId)
        {
            try
            {
                return await _context.CVOnlineProfiles
                    .Include(cv => cv.Template)
                    .Where(cv => cv.UserId == userId)
                    .OrderByDescending(cv => cv.IsDefault)
                    .ThenByDescending(cv => cv.UpdatedAt)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting CV profiles for user {userId}");
                return new List<CVOnlineProfile>();
            }
        }

        public async Task<CVOnlineProfile?> GetDefaultCV(string userId)
        {
            try
            {
                return await _context.CVOnlineProfiles
                    .Include(cv => cv.WorkExperiences.OrderBy(w => w.DisplayOrder))
                    .Include(cv => cv.Educations.OrderBy(e => e.DisplayOrder))
                    .Include(cv => cv.Skills.OrderBy(s => s.DisplayOrder))
                    .Include(cv => cv.Projects.OrderBy(p => p.DisplayOrder))
                    .Include(cv => cv.Certifications.OrderBy(c => c.DisplayOrder))
                    .Include(cv => cv.Languages.OrderBy(l => l.DisplayOrder))
                    .FirstOrDefaultAsync(cv => cv.UserId == userId && cv.IsDefault);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting default CV for user {userId}");
                return null;
            }
        }

        public async Task<CVOnlineProfile?> GetPublicCV(string slug)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .Include(cv => cv.WorkExperiences.OrderBy(w => w.DisplayOrder))
                    .Include(cv => cv.Educations.OrderBy(e => e.DisplayOrder))
                    .Include(cv => cv.Skills.OrderBy(s => s.DisplayOrder))
                    .Include(cv => cv.Projects.OrderBy(p => p.DisplayOrder))
                    .Include(cv => cv.Certifications.OrderBy(c => c.DisplayOrder))
                    .Include(cv => cv.Languages.OrderBy(l => l.DisplayOrder))
                    .Include(cv => cv.References.OrderBy(r => r.DisplayOrder))
                    .Include(cv => cv.Template)
                    .FirstOrDefaultAsync(cv => cv.PublicSlug == slug && cv.IsPublic);

                if (cv != null)
                {
                    await IncrementViewCount(cv.Id);
                }

                return cv;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting public CV with slug {slug}");
                return null;
            }
        }

        public async Task<CVOnlineProfile> UpdateCVProfile(int id, string userId, JsonElement data)
        {
            try
            {
                var existingCV = await _context.CVOnlineProfiles
                    .Include(cv => cv.WorkExperiences.OrderBy(w => w.DisplayOrder))
                    .Include(cv => cv.Educations.OrderBy(e => e.DisplayOrder))
                    .Include(cv => cv.Skills.OrderBy(s => s.DisplayOrder))
                    .Include(cv => cv.Projects.OrderBy(p => p.DisplayOrder))
                    .Include(cv => cv.Certifications.OrderBy(c => c.DisplayOrder))
                    .Include(cv => cv.Languages.OrderBy(l => l.DisplayOrder))
                    .Include(cv => cv.References.OrderBy(r => r.DisplayOrder))
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (existingCV == null)
                {
                    throw new InvalidOperationException($"CV profile {id} not found");
                }

                // Partial update: only update fields present in the JSON
                if (data.TryGetProperty("title", out var title)) existingCV.Title = title.GetString() ?? existingCV.Title;
                if (data.TryGetProperty("fullName", out var fullName)) existingCV.FullName = fullName.GetString() ?? existingCV.FullName;
                if (data.TryGetProperty("email", out var email)) existingCV.Email = email.ValueKind == JsonValueKind.Null ? null : email.GetString();
                if (data.TryGetProperty("phone", out var phone)) existingCV.Phone = phone.ValueKind == JsonValueKind.Null ? null : phone.GetString();
                if (data.TryGetProperty("address", out var address)) existingCV.Address = address.ValueKind == JsonValueKind.Null ? null : address.GetString();
                if (data.TryGetProperty("city", out var city)) existingCV.City = city.ValueKind == JsonValueKind.Null ? null : city.GetString();
                if (data.TryGetProperty("country", out var country)) existingCV.Country = country.ValueKind == JsonValueKind.Null ? null : country.GetString();
                if (data.TryGetProperty("website", out var website)) existingCV.Website = website.ValueKind == JsonValueKind.Null ? null : website.GetString();
                if (data.TryGetProperty("linkedIn", out var linkedIn)) existingCV.LinkedIn = linkedIn.ValueKind == JsonValueKind.Null ? null : linkedIn.GetString();
                if (data.TryGetProperty("gitHub", out var gitHub)) existingCV.GitHub = gitHub.ValueKind == JsonValueKind.Null ? null : gitHub.GetString();
                if (data.TryGetProperty("portfolio", out var portfolio)) existingCV.Portfolio = portfolio.ValueKind == JsonValueKind.Null ? null : portfolio.GetString();
                if (data.TryGetProperty("profilePhotoUrl", out var photoUrl))
                {
                    var newPhotoValue = photoUrl.ValueKind == JsonValueKind.Null ? null : photoUrl.GetString();
                    _logger.LogInformation($"ProfilePhotoUrl: old='{existingCV.ProfilePhotoUrl}' -> new='{newPhotoValue}'");
                    existingCV.ProfilePhotoUrl = newPhotoValue;
                }
                if (data.TryGetProperty("summary", out var summary)) existingCV.Summary = summary.ValueKind == JsonValueKind.Null ? null : summary.GetString();
                if (data.TryGetProperty("currentPosition", out var currentPos)) existingCV.CurrentPosition = currentPos.ValueKind == JsonValueKind.Null ? null : currentPos.GetString();
                if (data.TryGetProperty("yearsOfExperience", out var yoe)) existingCV.YearsOfExperience = yoe.ValueKind == JsonValueKind.Null ? null : yoe.GetInt32();
                if (data.TryGetProperty("templateId", out var templateId)) existingCV.TemplateId = templateId.ValueKind == JsonValueKind.Null ? null : templateId.GetInt32();
                if (data.TryGetProperty("theme", out var theme)) existingCV.Theme = theme.ValueKind == JsonValueKind.Null ? null : theme.GetString();
                if (data.TryGetProperty("primaryColor", out var primaryColor)) existingCV.PrimaryColor = primaryColor.ValueKind == JsonValueKind.Null ? null : primaryColor.GetString();
                if (data.TryGetProperty("secondaryColor", out var secondaryColor)) existingCV.SecondaryColor = secondaryColor.ValueKind == JsonValueKind.Null ? null : secondaryColor.GetString();
                if (data.TryGetProperty("showPhoto", out var showPhoto)) existingCV.ShowPhoto = showPhoto.GetBoolean();
                if (data.TryGetProperty("showContactInfo", out var showContact)) existingCV.ShowContactInfo = showContact.GetBoolean();
                if (data.TryGetProperty("isPublic", out var isPublic))
                {
                    existingCV.IsPublic = isPublic.GetBoolean();
                    if (existingCV.IsPublic && string.IsNullOrEmpty(existingCV.PublicSlug))
                    {
                        existingCV.PublicSlug = await GenerateUniqueSlug(existingCV.Title);
                    }
                }

                existingCV.UpdatedAt = DateTime.UtcNow;
                _logger.LogInformation($"Before SaveChanges: ProfilePhotoUrl='{existingCV.ProfilePhotoUrl}'");
                var rowsAffected = await _context.SaveChangesAsync();
                _logger.LogInformation($"SaveChangesAsync returned {rowsAffected} rows affected");
                _logger.LogInformation($"After SaveChanges: ProfilePhotoUrl='{existingCV.ProfilePhotoUrl}'");

                _logger.LogInformation($"Updated CV profile {id} for user {userId}");
                return existingCV;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating CV profile {id} for user {userId}");
                throw;
            }
        }

        public async Task<bool> DeleteCVProfile(int id, string userId)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (cv == null)
                {
                    return false;
                }

                _context.CVOnlineProfiles.Remove(cv);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Deleted CV profile {id} for user {userId}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting CV profile {id} for user {userId}");
                return false;
            }
        }

        public async Task<bool> SetDefaultCV(int id, string userId)
        {
            try
            {
                // Remove default flag from all user's CVs
                var userCVs = await _context.CVOnlineProfiles
                    .Where(cv => cv.UserId == userId)
                    .ToListAsync();

                foreach (var cv in userCVs)
                {
                    cv.IsDefault = cv.Id == id;
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Set CV profile {id} as default for user {userId}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error setting default CV {id} for user {userId}");
                return false;
            }
        }

        public async Task<bool> TogglePublicAccess(int id, string userId)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(cv => cv.Id == id && cv.UserId == userId);

                if (cv == null)
                {
                    return false;
                }

                cv.IsPublic = !cv.IsPublic;

                if (cv.IsPublic && string.IsNullOrEmpty(cv.PublicSlug))
                {
                    cv.PublicSlug = await GenerateUniqueSlug(cv.Title);
                }

                if (cv.IsPublic)
                {
                    cv.LastPublishedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Toggled public access for CV {id}, now public: {cv.IsPublic}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error toggling public access for CV {id}");
                return false;
            }
        }

        // ==================== WORK EXPERIENCE ====================

        public async Task<CVWorkExperience> AddWorkExperience(int cvId, string userId, CVWorkExperience experience)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                experience.CVProfileId = cvId;
                _context.CVWorkExperiences.Add(experience);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return experience;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding work experience to CV {cvId}");
                throw;
            }
        }

        public async Task<CVWorkExperience> UpdateWorkExperience(int id, int cvId, string userId, CVWorkExperience experience)
        {
            try
            {
                var existing = await _context.CVWorkExperiences
                    .Include(w => w.CVProfile)
                    .FirstOrDefaultAsync(w => w.Id == id && w.CVProfileId == cvId && w.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Work experience {id} not found");
                }

                existing.JobTitle = experience.JobTitle;
                existing.Company = experience.Company;
                existing.Location = experience.Location;
                existing.StartDate = experience.StartDate;
                existing.EndDate = experience.EndDate;
                existing.IsCurrentJob = experience.IsCurrentJob;
                existing.Description = experience.Description;
                existing.Achievements = experience.Achievements;
                existing.Technologies = experience.Technologies;
                existing.DisplayOrder = experience.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating work experience {id}");
                throw;
            }
        }

        public async Task<bool> DeleteWorkExperience(int id, int cvId, string userId)
        {
            try
            {
                var experience = await _context.CVWorkExperiences
                    .Include(w => w.CVProfile)
                    .FirstOrDefaultAsync(w => w.Id == id && w.CVProfileId == cvId && w.CVProfile.UserId == userId);

                if (experience == null)
                {
                    return false;
                }

                _context.CVWorkExperiences.Remove(experience);
                experience.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting work experience {id}");
                return false;
            }
        }

        // ==================== EDUCATION ====================

        public async Task<CVEducation> AddEducation(int cvId, string userId, CVEducation education)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                education.CVProfileId = cvId;
                _context.CVEducations.Add(education);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return education;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding education to CV {cvId}");
                throw;
            }
        }

        public async Task<CVEducation> UpdateEducation(int id, int cvId, string userId, CVEducation education)
        {
            try
            {
                var existing = await _context.CVEducations
                    .Include(e => e.CVProfile)
                    .FirstOrDefaultAsync(e => e.Id == id && e.CVProfileId == cvId && e.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Education {id} not found");
                }

                existing.Degree = education.Degree;
                existing.Institution = education.Institution;
                existing.Location = education.Location;
                existing.GPA = education.GPA;
                existing.StartDate = education.StartDate;
                existing.EndDate = education.EndDate;
                existing.IsCurrentlyStudying = education.IsCurrentlyStudying;
                existing.Description = education.Description;
                existing.Courses = education.Courses;
                existing.DisplayOrder = education.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating education {id}");
                throw;
            }
        }

        public async Task<bool> DeleteEducation(int id, int cvId, string userId)
        {
            try
            {
                var education = await _context.CVEducations
                    .Include(e => e.CVProfile)
                    .FirstOrDefaultAsync(e => e.Id == id && e.CVProfileId == cvId && e.CVProfile.UserId == userId);

                if (education == null)
                {
                    return false;
                }

                _context.CVEducations.Remove(education);
                education.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting education {id}");
                return false;
            }
        }

        // ==================== SKILLS ====================

        public async Task<CVSkill> AddSkill(int cvId, string userId, CVSkill skill)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                skill.CVProfileId = cvId;
                _context.CVSkills.Add(skill);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return skill;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding skill to CV {cvId}");
                throw;
            }
        }

        public async Task<CVSkill> UpdateSkill(int id, int cvId, string userId, CVSkill skill)
        {
            try
            {
                var existing = await _context.CVSkills
                    .Include(s => s.CVProfile)
                    .FirstOrDefaultAsync(s => s.Id == id && s.CVProfileId == cvId && s.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Skill {id} not found");
                }

                existing.Name = skill.Name;
                existing.Category = skill.Category;
                existing.ProficiencyLevel = skill.ProficiencyLevel;
                existing.YearsOfExperience = skill.YearsOfExperience;
                existing.DisplayOrder = skill.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating skill {id}");
                throw;
            }
        }

        public async Task<bool> DeleteSkill(int id, int cvId, string userId)
        {
            try
            {
                var skill = await _context.CVSkills
                    .Include(s => s.CVProfile)
                    .FirstOrDefaultAsync(s => s.Id == id && s.CVProfileId == cvId && s.CVProfile.UserId == userId);

                if (skill == null)
                {
                    return false;
                }

                _context.CVSkills.Remove(skill);
                skill.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting skill {id}");
                return false;
            }
        }

        // ==================== PROJECTS ====================

        public async Task<CVProject> AddProject(int cvId, string userId, CVProject project)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                project.CVProfileId = cvId;
                _context.CVProjects.Add(project);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return project;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding project to CV {cvId}");
                throw;
            }
        }

        public async Task<CVProject> UpdateProject(int id, int cvId, string userId, CVProject project)
        {
            try
            {
                var existing = await _context.CVProjects
                    .Include(p => p.CVProfile)
                    .FirstOrDefaultAsync(p => p.Id == id && p.CVProfileId == cvId && p.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Project {id} not found");
                }

                existing.Name = project.Name;
                existing.Link = project.Link;
                existing.StartDate = project.StartDate;
                existing.EndDate = project.EndDate;
                existing.Description = project.Description;
                existing.Technologies = project.Technologies;
                existing.Achievements = project.Achievements;
                existing.DisplayOrder = project.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating project {id}");
                throw;
            }
        }

        public async Task<bool> DeleteProject(int id, int cvId, string userId)
        {
            try
            {
                var project = await _context.CVProjects
                    .Include(p => p.CVProfile)
                    .FirstOrDefaultAsync(p => p.Id == id && p.CVProfileId == cvId && p.CVProfile.UserId == userId);

                if (project == null)
                {
                    return false;
                }

                _context.CVProjects.Remove(project);
                project.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting project {id}");
                return false;
            }
        }

        // ==================== CERTIFICATIONS ====================

        public async Task<CVCertification> AddCertification(int cvId, string userId, CVCertification certification)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                certification.CVProfileId = cvId;
                _context.CVCertifications.Add(certification);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return certification;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding certification to CV {cvId}");
                throw;
            }
        }

        public async Task<CVCertification> UpdateCertification(int id, int cvId, string userId, CVCertification certification)
        {
            try
            {
                var existing = await _context.CVCertifications
                    .Include(c => c.CVProfile)
                    .FirstOrDefaultAsync(c => c.Id == id && c.CVProfileId == cvId && c.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Certification {id} not found");
                }

                existing.Name = certification.Name;
                existing.IssuingOrganization = certification.IssuingOrganization;
                existing.IssueDate = certification.IssueDate;
                existing.ExpiryDate = certification.ExpiryDate;
                existing.CredentialId = certification.CredentialId;
                existing.CredentialUrl = certification.CredentialUrl;
                existing.DisplayOrder = certification.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating certification {id}");
                throw;
            }
        }

        public async Task<bool> DeleteCertification(int id, int cvId, string userId)
        {
            try
            {
                var certification = await _context.CVCertifications
                    .Include(c => c.CVProfile)
                    .FirstOrDefaultAsync(c => c.Id == id && c.CVProfileId == cvId && c.CVProfile.UserId == userId);

                if (certification == null)
                {
                    return false;
                }

                _context.CVCertifications.Remove(certification);
                certification.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting certification {id}");
                return false;
            }
        }

        // ==================== LANGUAGES ====================

        public async Task<CVLanguage> AddLanguage(int cvId, string userId, CVLanguage language)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                language.CVProfileId = cvId;
                _context.CVLanguages.Add(language);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return language;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding language to CV {cvId}");
                throw;
            }
        }

        public async Task<CVLanguage> UpdateLanguage(int id, int cvId, string userId, CVLanguage language)
        {
            try
            {
                var existing = await _context.CVLanguages
                    .Include(l => l.CVProfile)
                    .FirstOrDefaultAsync(l => l.Id == id && l.CVProfileId == cvId && l.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Language {id} not found");
                }

                existing.Name = language.Name;
                existing.ProficiencyLevel = language.ProficiencyLevel;
                existing.DisplayOrder = language.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating language {id}");
                throw;
            }
        }

        public async Task<bool> DeleteLanguage(int id, int cvId, string userId)
        {
            try
            {
                var language = await _context.CVLanguages
                    .Include(l => l.CVProfile)
                    .FirstOrDefaultAsync(l => l.Id == id && l.CVProfileId == cvId && l.CVProfile.UserId == userId);

                if (language == null)
                {
                    return false;
                }

                _context.CVLanguages.Remove(language);
                language.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting language {id}");
                return false;
            }
        }

        // ==================== REFERENCES ====================

        public async Task<CVReference> AddReference(int cvId, string userId, CVReference reference)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles
                    .FirstOrDefaultAsync(c => c.Id == cvId && c.UserId == userId);

                if (cv == null)
                {
                    throw new InvalidOperationException($"CV profile {cvId} not found");
                }

                reference.CVProfileId = cvId;
                _context.CVReferences.Add(reference);
                
                cv.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return reference;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error adding reference to CV {cvId}");
                throw;
            }
        }

        public async Task<CVReference> UpdateReference(int id, int cvId, string userId, CVReference reference)
        {
            try
            {
                var existing = await _context.CVReferences
                    .Include(r => r.CVProfile)
                    .FirstOrDefaultAsync(r => r.Id == id && r.CVProfileId == cvId && r.CVProfile.UserId == userId);

                if (existing == null)
                {
                    throw new InvalidOperationException($"Reference {id} not found");
                }

                existing.Name = reference.Name;
                existing.Position = reference.Position;
                existing.Company = reference.Company;
                existing.Email = reference.Email;
                existing.Phone = reference.Phone;
                existing.DisplayOrder = reference.DisplayOrder;

                existing.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return existing;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating reference {id}");
                throw;
            }
        }

        public async Task<bool> DeleteReference(int id, int cvId, string userId)
        {
            try
            {
                var reference = await _context.CVReferences
                    .Include(r => r.CVProfile)
                    .FirstOrDefaultAsync(r => r.Id == id && r.CVProfileId == cvId && r.CVProfile.UserId == userId);

                if (reference == null)
                {
                    return false;
                }

                _context.CVReferences.Remove(reference);
                reference.CVProfile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting reference {id}");
                return false;
            }
        }

        // ==================== TEMPLATES ====================

        public async Task<List<CVTemplate>> GetAvailableTemplates(bool includePremium = false)
        {
            try
            {
                var query = _context.CVTemplates.Where(t => t.IsActive);

                if (!includePremium)
                {
                    query = query.Where(t => !t.IsPremium);
                }

                return await query
                    .OrderBy(t => t.IsPremium)
                    .ThenByDescending(t => t.UsageCount)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting CV templates");
                return new List<CVTemplate>();
            }
        }

        public async Task<CVTemplate?> GetTemplate(int id)
        {
            try
            {
                return await _context.CVTemplates
                    .FirstOrDefaultAsync(t => t.Id == id && t.IsActive);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting template {id}");
                return null;
            }
        }

        // ==================== EXPORT/DOWNLOAD ====================

        public async Task<string> GeneratePDFUrl(int cvId, string userId)
        {
            try
            {
                // TODO: Implement PDF generation using a library like QuestPDF or SelectPdf
                // For now, return a placeholder
                await IncrementDownloadCount(cvId);
                
                return $"/api/cv-online/{cvId}/download";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error generating PDF for CV {cvId}");
                throw;
            }
        }

        public async Task<bool> IncrementViewCount(int cvId)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles.FindAsync(cvId);
                if (cv == null) return false;

                cv.ViewCount++;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error incrementing view count for CV {cvId}");
                return false;
            }
        }

        public async Task<bool> IncrementDownloadCount(int cvId)
        {
            try
            {
                var cv = await _context.CVOnlineProfiles.FindAsync(cvId);
                if (cv == null) return false;

                cv.DownloadCount++;
                await _context.SaveChangesAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error incrementing download count for CV {cvId}");
                return false;
            }
        }

        // ==================== HELPER METHODS ====================

        private async Task<string> GenerateUniqueSlug(string title)
        {
            var baseSlug = title.ToLower()
                .Replace(" ", "-")
                .Replace("'", "")
                .Replace("\"", "");

            var slug = baseSlug;
            var counter = 1;

            while (await _context.CVOnlineProfiles.AnyAsync(cv => cv.PublicSlug == slug))
            {
                slug = $"{baseSlug}-{counter}";
                counter++;
            }

            return slug;
        }
    }
}
