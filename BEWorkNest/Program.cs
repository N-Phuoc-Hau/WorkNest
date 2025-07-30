using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using BEWorkNest.Models;
using BEWorkNest.Services;
using BEWorkNest.Data;
using BEWorkNest.Authorization;
using Microsoft.AspNetCore.Authorization;

namespace BEWorkNest
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseMySql(builder.Configuration.GetConnectionString("DefaultConnection"),
                    new MySqlServerVersion(new Version(8, 0, 25))));

            builder.Services.AddIdentity<User, IdentityRole>(options =>
            {
                options.Password.RequiredLength = 6;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequireUppercase = false;
                options.Password.RequireLowercase = false;
                options.Password.RequireDigit = false;
                options.User.RequireUniqueEmail = true;
            })
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = builder.Configuration["Jwt:Issuer"],
                        ValidAudience = builder.Configuration["Jwt:Audience"],
                        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
                    };
                });

            // Authorization policies
            builder.Services.AddAuthorization(options =>
            {
                options.AddPolicy("IsOwner", policy => policy.Requirements.Add(new IsOwnerRequirement()));
                options.AddPolicy("IsRecruiter", policy => policy.Requirements.Add(new IsRecruiterRequirement()));
                options.AddPolicy("IsCandidate", policy => policy.Requirements.Add(new IsCandidateRequirement()));
                options.AddPolicy("CanCandidateReview", policy => policy.Requirements.Add(new CanCandidateReviewRequirement()));
                options.AddPolicy("CanRecruiterReview", policy => policy.Requirements.Add(new CanRecruiterReviewRequirement()));
            });

            // Register authorization handlers
            builder.Services.AddScoped<IAuthorizationHandler, IsOwnerHandler>();
            builder.Services.AddScoped<IAuthorizationHandler, IsRecruiterHandler>();
            builder.Services.AddScoped<IAuthorizationHandler, IsCandidateHandler>();
            builder.Services.AddScoped<IAuthorizationHandler, CanCandidateReviewHandler>();
            builder.Services.AddScoped<IAuthorizationHandler, CanRecruiterReviewHandler>();

            // Add services to DI container
            builder.Services.AddScoped<JwtService>();
            builder.Services.AddScoped<RefreshTokenService>();
            builder.Services.AddScoped<CloudinaryService>();
            builder.Services.AddScoped<EmailService>();
            builder.Services.AddScoped<FirebaseService>();
            builder.Services.AddScoped<FirebaseRealtimeService>();
            builder.Services.AddScoped<NotificationService>();
            builder.Services.AddScoped<AiService>();
            builder.Services.AddScoped<AnalyticsService>();
            builder.Services.AddHttpClient<AiService>();
            builder.Services.AddHttpContextAccessor();

            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Add CORS
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll",
                    builder =>
                    {
                        builder.AllowAnyOrigin()
                               .AllowAnyMethod()
                               .AllowAnyHeader();
                    });
            });

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();
            app.UseCors("AllowAll");
            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
