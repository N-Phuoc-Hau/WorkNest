using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;

namespace BEWorkNest.Services
{
    public class ApplicationService
    {
        private readonly ApplicationDbContext _context;
        private readonly NotificationService _notificationService;

        public ApplicationService(ApplicationDbContext context, NotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
        }

        public async Task<(List<ApplicationDto> applications, int totalCount)> GetApplicationsAsync(
            string? userId = null, 
            string? recruiterId = null, 
            int page = 1, 
            int pageSize = 10)
        {
            var query = _context.Applications
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Include(a => a.Applicant)
                .Where(a => a.IsActive);

            if (!string.IsNullOrEmpty(userId))
            {
                query = query.Where(a => a.ApplicantId == userId);
            }

            if (!string.IsNullOrEmpty(recruiterId))
            {
                query = query.Where(a => a.Job.RecruiterId == recruiterId);
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
                    ApplicationCount = 0,
                    Recruiter = new UserDto
                    {
                        Id = a.Job.Recruiter.Id,
                        Email = a.Job.Recruiter.Email!,
                        FirstName = a.Job.Recruiter.FirstName,
                        LastName = a.Job.Recruiter.LastName,
                        Role = a.Job.Recruiter.Role,
                        IsActive = a.Job.Recruiter.IsActive,
                        CreatedAt = a.Job.Recruiter.CreatedAt,
                        Company = a.Job.Recruiter.Company != null ? new CompanyDto
                        {
                            Id = a.Job.Recruiter.Company.Id,
                            Name = a.Job.Recruiter.Company.Name,
                            Location = a.Job.Recruiter.Company.Location
                        } : null
                    }
                },
                Applicant = new UserDto
                {
                    Id = a.Applicant.Id,
                    Email = a.Applicant.Email!,
                    FirstName = a.Applicant.FirstName,
                    LastName = a.Applicant.LastName,
                    Avatar = a.Applicant.Avatar,
                    CreatedAt = a.Applicant.CreatedAt
                }
            }).ToList();

            return (applicationDtos, totalCount);
        }

        public async Task<ApplicationDto?> GetApplicationByIdAsync(int id)
        {
            var application = await _context.Applications
                .Include(a => a.Job)
                .ThenInclude(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .Include(a => a.Applicant)
                .FirstOrDefaultAsync(a => a.Id == id && a.IsActive);

            if (application == null)
                return null;

            return new ApplicationDto
            {
                Id = application.Id,
                CvUrl = application.CvUrl,
                CoverLetter = application.CoverLetter,
                Status = application.Status.ToString(),
                CreatedAt = application.CreatedAt,
                Job = new JobPostDto
                {
                    Id = application.Job.Id,
                    Title = application.Job.Title,
                    Specialized = application.Job.Specialized,
                    Description = application.Job.Description,
                    Salary = application.Job.Salary,
                    Location = application.Job.Location,
                    JobType = application.Job.JobType,
                    ExperienceLevel = application.Job.ExperienceLevel,
                    CreatedAt = application.Job.CreatedAt,
                    Recruiter = new UserDto
                    {
                        Id = application.Job.Recruiter.Id,
                        Email = application.Job.Recruiter.Email!,
                        FirstName = application.Job.Recruiter.FirstName,
                        LastName = application.Job.Recruiter.LastName,
                        Role = application.Job.Recruiter.Role,
                        Company = application.Job.Recruiter.Company != null ? new CompanyDto
                        {
                            Id = application.Job.Recruiter.Company.Id,
                            Name = application.Job.Recruiter.Company.Name,
                            Location = application.Job.Recruiter.Company.Location
                        } : null
                    }
                },
                Applicant = new UserDto
                {
                    Id = application.Applicant.Id,
                    Email = application.Applicant.Email!,
                    FirstName = application.Applicant.FirstName,
                    LastName = application.Applicant.LastName,
                    Avatar = application.Applicant.Avatar,
                    CreatedAt = application.Applicant.CreatedAt
                }
            };
        }

        public async Task<(bool success, string message, int? applicationId)> CreateApplicationAsync(CreateApplicationDto createDto, string userId)
        {
            try
            {
                // Check if job exists and is active
                var jobPost = await _context.JobPosts
                    .Include(j => j.Recruiter)
                    .FirstOrDefaultAsync(j => j.Id == createDto.JobId && j.IsActive);

                if (jobPost == null)
                    return (false, "Job post not found", null);

                // Check if user already applied for this job
                var existingApplication = await _context.Applications
                    .FirstOrDefaultAsync(a => a.JobId == createDto.JobId && a.ApplicantId == userId && a.IsActive);

                if (existingApplication != null)
                    return (false, "You have already applied for this job", null);

                var application = new Application
                {
                    JobId = createDto.JobId,
                    ApplicantId = userId,
                    CoverLetter = createDto.CoverLetter,
                    CvUrl = null, // Will be set after file upload
                    Status = ApplicationStatus.Pending,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _context.Applications.Add(application);
                await _context.SaveChangesAsync();

                // Send notification to recruiter
                await _notificationService.CreateNotificationAsync(
                    jobPost.RecruiterId,
                    "New Job Application",
                    $"You have received a new application for {jobPost.Title}",
                    "application",
                    application.Id.ToString()
                );

                return (true, "Application submitted successfully", application.Id);
            }
            catch (Exception ex)
            {
                return (false, $"Error creating application: {ex.Message}", null);
            }
        }

        public async Task<(bool success, string message)> UpdateApplicationStatusAsync(int id, UpdateApplicationStatusDto updateDto, string recruiterId)
        {
            try
            {
                var application = await _context.Applications
                    .Include(a => a.Job)
                    .Include(a => a.Applicant)
                    .FirstOrDefaultAsync(a => a.Id == id && a.IsActive);

                if (application == null)
                    return (false, "Application not found");

                if (application.Job.RecruiterId != recruiterId)
                    return (false, "You are not authorized to update this application");

                // Parse status string to enum
                if (!Enum.TryParse<ApplicationStatus>(updateDto.Status, true, out var status))
                    return (false, "Invalid status value");

                application.Status = status;
                application.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                // Send notification to candidate
                var statusMessage = updateDto.Status.ToLower() switch
                {
                    "accepted" => "Your application has been accepted!",
                    "rejected" => "Your application was not successful this time.",
                    "interviewed" => "You have been selected for an interview!",
                    _ => $"Your application status has been updated to {updateDto.Status}"
                };

                await _notificationService.CreateNotificationAsync(
                    application.ApplicantId,
                    "Application Status Update",
                    statusMessage,
                    "application_status",
                    application.Id.ToString()
                );

                return (true, "Application status updated successfully");
            }
            catch (Exception ex)
            {
                return (false, $"Error updating application status: {ex.Message}");
            }
        }

        public async Task<(bool success, string message)> DeleteApplicationAsync(int id, string userId)
        {
            try
            {
                var application = await _context.Applications
                    .FirstOrDefaultAsync(a => a.Id == id && a.IsActive);

                if (application == null)
                    return (false, "Application not found");

                if (application.ApplicantId != userId)
                    return (false, "You are not authorized to delete this application");

                // Soft delete
                application.IsActive = false;
                application.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return (true, "Application deleted successfully");
            }
            catch (Exception ex)
            {
                return (false, $"Error deleting application: {ex.Message}");
            }
        }
    }
}
