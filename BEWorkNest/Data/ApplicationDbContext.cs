using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
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
        public DbSet<Interview> Interviews { get; set; }
        public DbSet<ForgotPasswordOtp> ForgotPasswordOtps { get; set; }

        // User behavior tracking
        public DbSet<SearchHistory> SearchHistories { get; set; }
        public DbSet<JobViewHistory> JobViewHistories { get; set; }
        public DbSet<ApplicationHistory> ApplicationHistories { get; set; }
        public DbSet<CVAnalysisResult> CVAnalysisResults { get; set; }
        public DbSet<JobRecommendationLog> JobRecommendationLogs { get; set; }

        // CV Analysis Tables
        public DbSet<CVAnalysisHistory> CVAnalysisHistories { get; set; }
        public DbSet<JobMatchAnalytics> JobMatchAnalytics { get; set; }
        public DbSet<CVAnalysisStats> CVAnalysisStats { get; set; }
        
        // Saved CV Tables
        public DbSet<SavedCV> SavedCVs { get; set; }

        // Payment & Subscription Tables
        public DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
        public DbSet<SubscriptionFeature> SubscriptionFeatures { get; set; }
        public DbSet<UserSubscription> UserSubscriptions { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<FeatureUsage> FeatureUsages { get; set; }
        public DbSet<PaymentGatewayConfig> PaymentGatewayConfigs { get; set; }

        // CV Online Builder Tables
        public DbSet<CVOnlineProfile> CVOnlineProfiles { get; set; }
        public DbSet<CVTemplate> CVTemplates { get; set; }
        public DbSet<CVWorkExperience> CVWorkExperiences { get; set; }
        public DbSet<CVEducation> CVEducations { get; set; }
        public DbSet<CVSkill> CVSkills { get; set; }
        public DbSet<CVProject> CVProjects { get; set; }
        public DbSet<CVCertification> CVCertifications { get; set; }
        public DbSet<CVLanguage> CVLanguages { get; set; }
        public DbSet<CVReference> CVReferences { get; set; }

        // Call & Video Call Tables
        public DbSet<Call> Calls { get; set; }

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

            // Configure CV Analysis History entity
            builder.Entity<CVAnalysisHistory>()
                .HasOne(ca => ca.User)
                .WithMany()
                .HasForeignKey(ca => ca.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVAnalysisHistory>()
                .HasIndex(ca => ca.UserId);

            builder.Entity<CVAnalysisHistory>()
                .HasIndex(ca => ca.AnalysisId)
                .IsUnique();

            builder.Entity<CVAnalysisHistory>()
                .HasIndex(ca => ca.CreatedAt);

            // Configure Job Match Analytics entity
            builder.Entity<JobMatchAnalytics>()
                .HasKey(jma => new { jma.JobId, jma.UserId });

            builder.Entity<JobMatchAnalytics>()
                .HasOne(jma => jma.JobPost)
                .WithMany()
                .HasForeignKey(jma => jma.JobId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<JobMatchAnalytics>()
                .HasOne(jma => jma.User)
                .WithMany()
                .HasForeignKey(jma => jma.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<JobMatchAnalytics>()
                .HasIndex(jma => jma.MatchScore);

            builder.Entity<JobMatchAnalytics>()
                .HasIndex(jma => jma.AnalyzedAt);

            // Configure CVAnalysisStats entity
            builder.Entity<CVAnalysisStats>()
                .HasOne(cas => cas.User)
                .WithMany()
                .HasForeignKey(cas => cas.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVAnalysisStats>()
                .HasIndex(cas => cas.UserId)
                .IsUnique();

            builder.Entity<CVAnalysisStats>()
                .HasIndex(cas => cas.UpdatedAt);

            // Configure SavedCV entity
            builder.Entity<SavedCV>()
                .HasOne(scv => scv.User)
                .WithMany()
                .HasForeignKey(scv => scv.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<SavedCV>()
                .HasIndex(scv => scv.UserId);

            builder.Entity<SavedCV>()
                .HasIndex(scv => scv.IsDefault);

            builder.Entity<SavedCV>()
                .HasIndex(scv => scv.IsActive);

            builder.Entity<SavedCV>()
                .HasIndex(scv => scv.CreatedAt);

            // ========== PAYMENT & SUBSCRIPTION CONFIGURATION ==========

            // Configure SubscriptionPlan entity
            builder.Entity<SubscriptionPlan>()
                .HasIndex(sp => sp.Name);

            builder.Entity<SubscriptionPlan>()
                .HasIndex(sp => sp.IsActive);

            builder.Entity<SubscriptionPlan>()
                .Property(sp => sp.Price)
                .HasPrecision(18, 2);

            // Configure SubscriptionFeature entity
            builder.Entity<SubscriptionFeature>()
                .HasOne(sf => sf.SubscriptionPlan)
                .WithMany(sp => sp.Features)
                .HasForeignKey(sf => sf.SubscriptionPlanId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<SubscriptionFeature>()
                .HasIndex(sf => new { sf.SubscriptionPlanId, sf.FeatureName });

            // Configure UserSubscription entity
            builder.Entity<UserSubscription>()
                .HasOne(us => us.User)
                .WithMany()
                .HasForeignKey(us => us.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<UserSubscription>()
                .HasOne(us => us.Plan)
                .WithMany(sp => sp.Subscriptions)
                .HasForeignKey(us => us.SubscriptionPlanId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<UserSubscription>()
                .HasIndex(us => us.UserId);

            builder.Entity<UserSubscription>()
                .HasIndex(us => new { us.UserId, us.IsActive });

            builder.Entity<UserSubscription>()
                .HasIndex(us => us.EndDate);

            // Configure Payment entity
            builder.Entity<Payment>()
                .HasOne(p => p.User)
                .WithMany()
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Payment>()
                .HasOne(p => p.UserSubscription)
                .WithMany(us => us.Payments)
                .HasForeignKey(p => p.UserSubscriptionId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Entity<Payment>()
                .Property(p => p.Amount)
                .HasPrecision(18, 2);

            builder.Entity<Payment>()
                .HasIndex(p => p.UserId);

            builder.Entity<Payment>()
                .HasIndex(p => p.TransactionId);

            builder.Entity<Payment>()
                .HasIndex(p => p.Status);

            builder.Entity<Payment>()
                .HasIndex(p => p.CreatedAt);

            builder.Entity<Payment>()
                .HasIndex(p => new { p.UserId, p.Status });

            // Configure FeatureUsage entity
            builder.Entity<FeatureUsage>()
                .HasOne(fu => fu.User)
                .WithMany()
                .HasForeignKey(fu => fu.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<FeatureUsage>()
                .HasIndex(fu => new { fu.UserId, fu.FeatureName })
                .IsUnique();

            builder.Entity<FeatureUsage>()
                .HasIndex(fu => fu.ResetDate);

            // Configure PaymentGatewayConfig entity
            builder.Entity<PaymentGatewayConfig>()
                .HasIndex(pgc => pgc.Gateway)
                .IsUnique();

            builder.Entity<PaymentGatewayConfig>()
                .HasIndex(pgc => pgc.IsActive);

            // ========== CV Online Configurations ==========

            // Configure CVOnlineProfile
            builder.Entity<CVOnlineProfile>()
                .HasOne(cv => cv.User)
                .WithMany()
                .HasForeignKey(cv => cv.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVOnlineProfile>()
                .HasIndex(cv => cv.UserId);

            builder.Entity<CVOnlineProfile>()
                .HasIndex(cv => cv.PublicSlug)
                .IsUnique();

            builder.Entity<CVOnlineProfile>()
                .HasIndex(cv => cv.IsPublic);

            builder.Entity<CVOnlineProfile>()
                .HasIndex(cv => new { cv.UserId, cv.IsDefault });

            // Configure CVTemplate
            builder.Entity<CVTemplate>()
                .HasIndex(t => t.Category);

            builder.Entity<CVTemplate>()
                .HasIndex(t => t.IsPremium);

            builder.Entity<CVTemplate>()
                .HasIndex(t => t.IsActive);

            builder.Entity<CVTemplate>()
                .HasIndex(t => new { t.Category, t.IsPremium, t.IsActive });

            // Configure CVWorkExperience
            builder.Entity<CVWorkExperience>()
                .HasOne(we => we.CVProfile)
                .WithMany(cv => cv.WorkExperiences)
                .HasForeignKey(we => we.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVWorkExperience>()
                .HasIndex(we => we.CVProfileId);

            builder.Entity<CVWorkExperience>()
                .HasIndex(we => new { we.CVProfileId, we.DisplayOrder });

            // Configure CVEducation
            builder.Entity<CVEducation>()
                .HasOne(e => e.CVProfile)
                .WithMany(cv => cv.Educations)
                .HasForeignKey(e => e.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVEducation>()
                .HasIndex(e => e.CVProfileId);

            builder.Entity<CVEducation>()
                .HasIndex(e => new { e.CVProfileId, e.DisplayOrder });

            // Configure CVSkill
            builder.Entity<CVSkill>()
                .HasOne(s => s.CVProfile)
                .WithMany(cv => cv.Skills)
                .HasForeignKey(s => s.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVSkill>()
                .HasIndex(s => s.CVProfileId);

            builder.Entity<CVSkill>()
                .HasIndex(s => s.Category);

            builder.Entity<CVSkill>()
                .HasIndex(s => new { s.CVProfileId, s.DisplayOrder });

            // Configure CVProject
            builder.Entity<CVProject>()
                .HasOne(p => p.CVProfile)
                .WithMany(cv => cv.Projects)
                .HasForeignKey(p => p.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVProject>()
                .HasIndex(p => p.CVProfileId);

            builder.Entity<CVProject>()
                .HasIndex(p => new { p.CVProfileId, p.DisplayOrder });

            // Configure CVCertification
            builder.Entity<CVCertification>()
                .HasOne(c => c.CVProfile)
                .WithMany(cv => cv.Certifications)
                .HasForeignKey(c => c.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVCertification>()
                .HasIndex(c => c.CVProfileId);

            builder.Entity<CVCertification>()
                .HasIndex(c => new { c.CVProfileId, c.DisplayOrder });

            // Configure CVLanguage
            builder.Entity<CVLanguage>()
                .HasOne(l => l.CVProfile)
                .WithMany(cv => cv.Languages)
                .HasForeignKey(l => l.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVLanguage>()
                .HasIndex(l => l.CVProfileId);

            builder.Entity<CVLanguage>()
                .HasIndex(l => new { l.CVProfileId, l.DisplayOrder });

            // Configure CVReference
            builder.Entity<CVReference>()
                .HasOne(r => r.CVProfile)
                .WithMany(cv => cv.References)
                .HasForeignKey(r => r.CVProfileId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.Entity<CVReference>()
                .HasIndex(r => r.CVProfileId);

            builder.Entity<CVReference>()
                .HasIndex(r => new { r.CVProfileId, r.DisplayOrder });

            // Ignore unused ASP.NET Identity tables to clean up database
            builder.Ignore<IdentityUserClaim<string>>();
            builder.Ignore<IdentityUserLogin<string>>();
            builder.Ignore<IdentityUserToken<string>>();
            builder.Ignore<IdentityRoleClaim<string>>();
        }
    }
}
