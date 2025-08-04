using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;

namespace BEWorkNest.Data
{
    public class ApplicationDbContext : IdentityDbContext<User>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<Company> Companies { get; set; }
        public DbSet<CompanyImage> CompanyImages { get; set; }
        public DbSet<JobPost> JobPosts { get; set; }
        public DbSet<Application> Applications { get; set; }
        public DbSet<Follow> Follows { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<FavoriteJob> FavoriteJobs { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<UserDevice> UserDevices { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<Analytics> Analytics { get; set; }
        public DbSet<UserProfile> UserProfiles { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Configure User entity
            builder.Entity<User>()
                .HasOne(u => u.Company)
                .WithOne(c => c.User)
                .HasForeignKey<Company>(c => c.UserId);

            // Configure Company entity
            builder.Entity<Company>()
                .HasMany(c => c.Images)
                .WithOne(i => i.Company)
                .HasForeignKey(i => i.CompanyId);

            builder.Entity<Company>()
                .HasIndex(c => c.TaxCode)
                .IsUnique();

            // Configure JobPost entity
            builder.Entity<JobPost>()
                .HasOne(j => j.Recruiter)
                .WithMany(u => u.JobPosts)
                .HasForeignKey(j => j.RecruiterId)
                .OnDelete(DeleteBehavior.Restrict);

            // Configure Application entity
            builder.Entity<Application>()
                .HasOne(a => a.Applicant)
                .WithMany(u => u.Applications)
                .HasForeignKey(a => a.ApplicantId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Application>()
                .HasOne(a => a.Job)
                .WithMany(j => j.Applications)
                .HasForeignKey(a => a.JobId)
                .OnDelete(DeleteBehavior.Cascade);

            // Unique constraint for Application (one application per job per candidate)
            builder.Entity<Application>()
                .HasIndex(a => new { a.ApplicantId, a.JobId })
                .IsUnique();

            // Configure Follow entity
            builder.Entity<Follow>()
                .HasOne(f => f.Follower)
                .WithMany(u => u.Following)
                .HasForeignKey(f => f.FollowerId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Follow>()
                .HasOne(f => f.Recruiter)
                .WithMany(u => u.Followers)
                .HasForeignKey(f => f.RecruiterId)
                .OnDelete(DeleteBehavior.Restrict);

            // Unique constraint for Follow (one follow per recruiter per candidate)
            builder.Entity<Follow>()
                .HasIndex(f => new { f.FollowerId, f.RecruiterId })
                .IsUnique();

            // Configure Review entity
            builder.Entity<Review>()
                .HasOne(r => r.Reviewer)
                .WithMany(u => u.GivenReviews)
                .HasForeignKey(r => r.ReviewerId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Review>()
                .HasOne(r => r.ReviewedUser)
                .WithMany(u => u.ReceivedReviews)
                .HasForeignKey(r => r.ReviewedUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // Configure decimal precision for Salary
            builder.Entity<JobPost>()
                .Property(j => j.Salary)
                .HasPrecision(10, 2);

            // Configure RefreshToken entity
            builder.Entity<RefreshToken>()
                .HasOne(rt => rt.User)
                .WithMany()
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<RefreshToken>()
                .HasIndex(rt => rt.Token)
                .IsUnique();

            builder.Entity<RefreshToken>()
                .HasIndex(rt => rt.UserId);

            // Configure Analytics entity
            builder.Entity<Analytics>()
                .HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<Analytics>()
                .HasIndex(a => a.UserId);

            builder.Entity<Analytics>()
                .HasIndex(a => a.Type);

            builder.Entity<Analytics>()
                .HasIndex(a => a.CreatedAt);
        }
    }
}
