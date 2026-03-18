using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using BEWorkNest.Models;
using BEWorkNest.Services;
using BEWorkNest.Data;
using BEWorkNest.Authorization;
using BEWorkNest.Middleware;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.ResponseCompression;
using OfficeOpenXml;
using System.IO.Compression;

namespace BEWorkNest
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // Note: EPPlus 8+ requires license setup through other means
            // For development, we'll handle license exceptions gracefully
            
            var builder = WebApplication.CreateBuilder(args);

            // ========== PERFORMANCE OPTIMIZATIONS ==========
            
            // Add Memory Cache
            builder.Services.AddMemoryCache(options =>
            {
                options.SizeLimit = 1024; // Max 1024 cache entries
                options.CompactionPercentage = 0.25; // Compact 25% when limit reached
            });

            // Add Response Caching
            builder.Services.AddResponseCaching(options =>
            {
                options.MaximumBodySize = 1024 * 1024; // 1 MB
                options.UseCaseSensitivePaths = false;
            });

            // Add Response Compression
            builder.Services.AddResponseCompression(options =>
            {
                options.EnableForHttps = true;
                options.Providers.Add<BrotliCompressionProvider>();
                options.Providers.Add<GzipCompressionProvider>();
                options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[]
                {
                    "application/json",
                    "text/plain",
                    "text/css",
                    "text/html",
                    "application/javascript",
                    "text/javascript"
                });
            });

            builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
            {
                options.Level = System.IO.Compression.CompressionLevel.Fastest;
            });

            builder.Services.Configure<GzipCompressionProviderOptions>(options =>
            {
                options.Level = System.IO.Compression.CompressionLevel.Optimal;
            });

            // ========== DATABASE CONFIGURATION ==========
            
            // Add DbContext with optimized connection pooling
            builder.Services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseMySql(
                    builder.Configuration.GetConnectionString("DefaultConnection"),
                    new MySqlServerVersion(new Version(8, 0, 25)),
                    mySqlOptions =>
                    {
                        mySqlOptions.EnableRetryOnFailure(
                            maxRetryCount: 3,
                            maxRetryDelay: TimeSpan.FromSeconds(5),
                            errorNumbersToAdd: null);
                        mySqlOptions.CommandTimeout(30);
                    }
                );
                
                // Performance optimizations
                options.EnableSensitiveDataLogging(false);
                options.EnableDetailedErrors(builder.Environment.IsDevelopment());
                options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking); // Default to no-tracking
            });

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
            builder.Services.AddScoped<ExcelExportService>();
            // New AI-related services
            builder.Services.AddScoped<CVProcessingService>();
            builder.Services.AddScoped<CVAnalysisService>();
            builder.Services.AddScoped<UserBehaviorService>();
            // Payment and subscription services
            builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
            builder.Services.AddScoped<IPaymentService, PaymentService>();
            builder.Services.AddScoped<IVNPayService, VNPayService>();
            builder.Services.AddScoped<IZaloPayService, ZaloPayService>();
            // CV Online Builder service
            builder.Services.AddScoped<ICVOnlineService, CVOnlineService>();
            // Call & Video Call service
            builder.Services.AddScoped<ICallService, CallService>();
            builder.Services.AddHttpClient<AiService>();
            builder.Services.AddHttpClient<ZaloPayService>();
            builder.Services.AddHttpContextAccessor();

            // Add SignalR
            builder.Services.AddSignalR();

            builder.Services.AddControllers(options =>
                {
                    // Tắt implicit [Required] cho non-nullable reference types
                    // Để tránh model validation fail khi frontend không gửi navigation properties (User, CVProfile...)
                    options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
                })
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
                    options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
                    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
                    options.JsonSerializerOptions.DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull;
                });
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
                        builder.WithOrigins("http://localhost:10013", "https://localhost:10013")
                               .AllowAnyMethod()
                               .AllowAnyHeader()
                               .AllowCredentials();
                    });
            });

            var app = builder.Build();

            // ========== PERFORMANCE MIDDLEWARE (Order matters!) ==========
            
            // 1. Response Compression (first to compress everything)
            app.UseResponseCompression();

            // 2. Response Caching
            app.UseResponseCaching();

            // 3. Request Metrics (track all requests)
            app.UseMiddleware<RequestMetricsMiddleware>();

            // 4. Performance Monitoring (detailed logging)
            if (app.Environment.IsDevelopment() || app.Configuration.GetValue<bool>("EnablePerformanceMonitoring"))
            {
                app.UseMiddleware<PerformanceMonitoringMiddleware>();
            }

            // 5. Rate Limiting (protect from abuse)
            app.UseMiddleware<RateLimitingMiddleware>();

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
            
            // Add Subscription Middleware
            app.UseSubscriptionMiddleware();

            // Add health check endpoint
            app.MapGet("/", () => "WorkNest API is running!");
            app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.Now });

            app.MapControllers();

            // Map SignalR hubs
            app.MapHub<BEWorkNest.Hubs.NotificationHub>("/notificationHub");
            app.MapHub<BEWorkNest.Hubs.CallHub>("/callHub");

            app.Run();
        }
    }
}
