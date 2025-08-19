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

                    // Configure JWT for SignalR
                    options.Events = new JwtBearerEvents
                    {
                        OnMessageReceived = context =>
                        {
                            var accessToken = context.Request.Query["access_token"];
                            var path = context.HttpContext.Request.Path;
                            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/notificationHub"))
                            {
                                context.Token = accessToken;
                            }
                            return Task.CompletedTask;
                        }
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
            builder.Services.AddScoped<JobPostService>();
            builder.Services.AddScoped<ApplicationService>();
            builder.Services.AddScoped<JwtService>();
            builder.Services.AddScoped<RefreshTokenService>();
            builder.Services.AddScoped<CloudinaryService>();
            builder.Services.AddScoped<EmailService>();
            builder.Services.AddScoped<FirebaseService>();
            builder.Services.AddScoped<FirebaseRealtimeService>();
            builder.Services.AddScoped<NotificationService>();
            builder.Services.AddScoped<AiService>();
            builder.Services.AddScoped<AnalyticsService>();
            // New AI-related services
            builder.Services.AddScoped<CVProcessingService>();
            builder.Services.AddScoped<UserBehaviorService>();
            builder.Services.AddHttpClient<AiService>();
            builder.Services.AddHttpContextAccessor();

            // Add SignalR
            builder.Services.AddSignalR();

            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
                {
                    Title = "WorkNest API",
                    Version = "v1"
                });

                // Add JWT Authentication to Swagger
                c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                {
                    Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below.",
                    Name = "Authorization",
                    In = Microsoft.OpenApi.Models.ParameterLocation.Header,
                    Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
                    Scheme = "Bearer"
                });

                c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
                {
                    {
                        new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                        {
                            Reference = new Microsoft.OpenApi.Models.OpenApiReference
                            {
                                Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            },
                            Scheme = "oauth2",
                            Name = "Bearer",
                            In = Microsoft.OpenApi.Models.ParameterLocation.Header,
                        },
                        new List<string>()
                    }
                });
            });

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

                options.AddPolicy("SignalRCors",
                    builder =>
                    {
                        builder.WithOrigins("http://localhost:3000", "https://localhost:3000")
                               .AllowAnyMethod()
                               .AllowAnyHeader()
                               .AllowCredentials();
                    });
            });

            var app = builder.Build();

            // Add request logging middleware
            app.Use(async (context, next) =>
            {
                Console.WriteLine($"Request: {context.Request.Method} {context.Request.Path}");
                await next();
                Console.WriteLine($"Response: {context.Response.StatusCode}");
            });

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }

            // Always enable Swagger for API documentation
            app.UseSwagger();
            app.UseSwaggerUI(c =>
            {
                c.SwaggerEndpoint("/swagger/v1/swagger.json", "WorkNest API v1");
                c.RoutePrefix = "swagger"; // Swagger will be available at /swagger
            });

            // Add static files support (optional, won't fail if wwwroot doesn't exist)
            if (Directory.Exists(Path.Combine(app.Environment.ContentRootPath, "wwwroot")))
            {
                app.UseStaticFiles();
            }
            
            // Add routing
            app.UseRouting();

            app.UseCors("AllowAll");
            app.UseAuthentication();
            app.UseAuthorization();

            // Add health check endpoint
            app.MapGet("/", () => "WorkNest API is running!");
            app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.Now });

            app.MapControllers();

            // Map SignalR hub
            app.MapHub<BEWorkNest.Hubs.NotificationHub>("/notificationHub");

            app.Run();
        }
    }
}
