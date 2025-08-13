using Microsoft.EntityFrameworkCore;
using BEWorkNest.Data;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;

namespace BEWorkNest.Services
{
    public class JobPostService
    {
        private readonly ApplicationDbContext _context;

        public JobPostService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<(List<JobPostDto> jobPosts, int totalCount)> GetJobPostsAsync(
            int page = 1, 
            int pageSize = 10, 
            string? search = null, 
            string? specialized = null, 
            string? location = null,
            string? currentUserId = null)
        {
            var query = _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .ThenInclude(c => c!.Images)
                .Include(j => j.Applications)
                .Include(j => j.FavoriteJobs)
                .Where(j => j.IsActive);

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(j => j.Title.Contains(search) || j.Description.Contains(search));
            }

            if (!string.IsNullOrEmpty(specialized))
            {
                query = query.Where(j => j.Specialized.Contains(specialized));
            }

            if (!string.IsNullOrEmpty(location))
            {
                query = query.Where(j => j.Location.Contains(location));
            }

            var totalCount = await query.CountAsync();
            var jobPosts = await query
                .OrderByDescending(j => j.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var jobPostDtos = jobPosts.Select(j => new JobPostDto
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
                Recruiter = new UserDto
                {
                    Id = j.Recruiter.Id,
                    Email = j.Recruiter.Email!,
                    FirstName = j.Recruiter.FirstName,
                    LastName = j.Recruiter.LastName,
                    Role = j.Recruiter.Role,
                    Avatar = j.Recruiter.Avatar,
                    IsActive = j.Recruiter.IsActive,
                    CreatedAt = j.Recruiter.CreatedAt,
                    Company = j.Recruiter.Company != null ? new CompanyDto
                    {
                        Id = j.Recruiter.Company.Id,
                        Name = j.Recruiter.Company.Name,
                        TaxCode = j.Recruiter.Company.TaxCode,
                        Description = j.Recruiter.Company.Description,
                        Location = j.Recruiter.Company.Location,
                        IsVerified = j.Recruiter.Company.IsVerified,
                        Images = j.Recruiter.Company.Images.Select(i => i.ImageUrl).ToList()
                    } : null
                },
                ApplicationCount = j.Applications.Count(a => a.IsActive)
            }).ToList();

            return (jobPostDtos, totalCount);
        }

        public async Task<JobPostDto?> GetJobPostByIdAsync(int id, string? currentUserId = null)
        {
            var jobPost = await _context.JobPosts
                .Include(j => j.Recruiter)
                .ThenInclude(r => r.Company)
                .ThenInclude(c => c!.Images)
                .Include(j => j.Applications)
                .Include(j => j.FavoriteJobs)
                .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

            if (jobPost == null)
                return null;

            return new JobPostDto
            {
                Id = jobPost.Id,
                Title = jobPost.Title,
                Specialized = jobPost.Specialized,
                Description = jobPost.Description,
                Requirements = jobPost.Requirements,
                Benefits = jobPost.Benefits,
                Salary = jobPost.Salary,
                WorkingHours = jobPost.WorkingHours,
                Location = jobPost.Location,
                JobType = jobPost.JobType,
                ExperienceLevel = jobPost.ExperienceLevel,
                DeadLine = jobPost.DeadLine,
                CreatedAt = jobPost.CreatedAt,
                Recruiter = new UserDto
                {
                    Id = jobPost.Recruiter.Id,
                    Email = jobPost.Recruiter.Email!,
                    FirstName = jobPost.Recruiter.FirstName,
                    LastName = jobPost.Recruiter.LastName,
                    Role = jobPost.Recruiter.Role,
                    Avatar = jobPost.Recruiter.Avatar,
                    IsActive = jobPost.Recruiter.IsActive,
                    CreatedAt = jobPost.Recruiter.CreatedAt,
                    Company = jobPost.Recruiter.Company != null ? new CompanyDto
                    {
                        Id = jobPost.Recruiter.Company.Id,
                        Name = jobPost.Recruiter.Company.Name,
                        TaxCode = jobPost.Recruiter.Company.TaxCode,
                        Description = jobPost.Recruiter.Company.Description,
                        Location = jobPost.Recruiter.Company.Location,
                        IsVerified = jobPost.Recruiter.Company.IsVerified,
                        Images = jobPost.Recruiter.Company.Images.Select(i => i.ImageUrl).ToList()
                    } : null
                },
                ApplicationCount = jobPost.Applications.Count(a => a.IsActive)
            };
        }

        public async Task<(bool success, string message, int? jobId)> CreateJobPostAsync(CreateJobPostDto createDto, string recruiterId)
        {
            try
            {
                // Check for duplicate job within the last 5 minutes
                var duplicateCheckTime = DateTime.UtcNow.AddMinutes(-5);
                var existingJob = await _context.JobPosts
                    .FirstOrDefaultAsync(j => 
                        j.RecruiterId == recruiterId && 
                        j.Title == createDto.Title &&
                        j.CreatedAt > duplicateCheckTime &&
                        j.IsActive);

                if (existingJob != null)
                {
                    return (false, "Bạn vừa tạo một bài đăng với tiêu đề tương tự. Vui lòng đợi 5 phút hoặc sử dụng tiêu đề khác.", null);
                }

                var jobPost = new JobPost
                {
                    RecruiterId = recruiterId,
                    Title = createDto.Title,
                    Specialized = createDto.Specialized,
                    Description = createDto.Description,
                    Requirements = createDto.Requirements,
                    Benefits = createDto.Benefits,
                    Salary = createDto.Salary,
                    WorkingHours = createDto.WorkingHours,
                    Location = createDto.Location,
                    JobType = createDto.JobType,
                    ExperienceLevel = createDto.ExperienceLevel,
                    DeadLine = createDto.DeadLine,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _context.JobPosts.Add(jobPost);
                await _context.SaveChangesAsync();

                return (true, "Tạo bài đăng tuyển dụng thành công", jobPost.Id);
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi khi tạo bài đăng: {ex.Message}", null);
            }
        }

        public async Task<(bool success, string message)> UpdateJobPostAsync(int id, UpdateJobPostDto updateDto, string recruiterId)
        {
            try
            {
                var jobPost = await _context.JobPosts
                    .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

                if (jobPost == null)
                    return (false, "Job post not found");

                if (jobPost.RecruiterId != recruiterId)
                    return (false, "You are not authorized to update this job post");

                // Update fields
                if (!string.IsNullOrEmpty(updateDto.Title))
                    jobPost.Title = updateDto.Title;
                
                if (!string.IsNullOrEmpty(updateDto.Specialized))
                    jobPost.Specialized = updateDto.Specialized;
                
                if (!string.IsNullOrEmpty(updateDto.Description))
                    jobPost.Description = updateDto.Description;
                
                if (!string.IsNullOrEmpty(updateDto.Requirements))
                    jobPost.Requirements = updateDto.Requirements;
                
                if (!string.IsNullOrEmpty(updateDto.Benefits))
                    jobPost.Benefits = updateDto.Benefits;
                    
                if (updateDto.Salary.HasValue)
                    jobPost.Salary = updateDto.Salary.Value;

                
                if (!string.IsNullOrEmpty(updateDto.WorkingHours))
                    jobPost.WorkingHours = updateDto.WorkingHours;
                
                if (!string.IsNullOrEmpty(updateDto.Location))
                    jobPost.Location = updateDto.Location;

                if (!string.IsNullOrEmpty(updateDto.JobType))
                    jobPost.JobType = updateDto.JobType;

                if (!string.IsNullOrEmpty(updateDto.ExperienceLevel))
                    jobPost.ExperienceLevel = updateDto.ExperienceLevel;

                if (updateDto.DeadLine.HasValue)
                    jobPost.DeadLine = updateDto.DeadLine.Value;

                jobPost.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return (true, "Job post updated successfully");
            }
            catch (Exception ex)
            {
                return (false, $"Error updating job post: {ex.Message}");
            }
        }

        public async Task<(bool success, string message)> DeleteJobPostAsync(int id, string recruiterId)
        {
            try
            {
                var jobPost = await _context.JobPosts
                    .FirstOrDefaultAsync(j => j.Id == id && j.IsActive);

                if (jobPost == null)
                    return (false, "Job post not found");

                if (jobPost.RecruiterId != recruiterId)
                    return (false, "You are not authorized to delete this job post");

                // Soft delete
                jobPost.IsActive = false;
                jobPost.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return (true, "Job post deleted successfully");
            }
            catch (Exception ex)
            {
                return (false, $"Error deleting job post: {ex.Message}");
            }
        }

        public async Task<(List<JobPostDto> jobPosts, int totalCount)> GetMyJobPostsAsync(string recruiterId, int page = 1, int pageSize = 10)
        {
            var query = _context.JobPosts
                .Include(j => j.Applications)
                .Include(j => j.Recruiter)
                .Where(j => j.RecruiterId == recruiterId && j.IsActive);

            var totalCount = await query.CountAsync();
            var jobPosts = await query
                .OrderByDescending(j => j.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var jobPostDtos = jobPosts.Select(j => new JobPostDto
            {
                Id = j.Id,
                Title = j.Title ?? string.Empty,
                Specialized = j.Specialized ?? string.Empty,
                Description = j.Description ?? string.Empty,
                Requirements = j.Requirements ?? string.Empty,
                Benefits = j.Benefits ?? string.Empty,
                Salary = j.Salary,
                WorkingHours = j.WorkingHours ?? string.Empty,
                Location = j.Location ?? string.Empty,
                JobType = j.JobType ?? string.Empty,
                ExperienceLevel = j.ExperienceLevel ?? string.Empty,
                DeadLine = j.DeadLine,
                CreatedAt = j.CreatedAt,
                ApplicationCount = j.Applications?.Count(a => a.IsActive) ?? 0,
                Recruiter = j.Recruiter != null ? new UserDto
                {
                    Id = j.Recruiter.Id,
                    Email = j.Recruiter.Email ?? string.Empty,
                    UserName = j.Recruiter.UserName ?? string.Empty,
                    FirstName = j.Recruiter.FirstName ?? string.Empty,
                    LastName = j.Recruiter.LastName ?? string.Empty,
                    Role = j.Recruiter.Role ?? string.Empty,
                    Avatar = j.Recruiter.Avatar,
                    IsActive = j.Recruiter.IsActive,
                    CreatedAt = j.Recruiter.CreatedAt
                } : new UserDto
                {
                    Id = recruiterId,
                    Email = "Unknown",
                    UserName = "Unknown",
                    FirstName = "Unknown",
                    LastName = "Recruiter",
                    Role = "recruiter",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            }).ToList();

            return (jobPostDtos, totalCount);
        }
    }
}
