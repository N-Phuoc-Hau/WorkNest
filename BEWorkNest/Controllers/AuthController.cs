using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BEWorkNest.Models;
using BEWorkNest.Models.DTOs;
using BEWorkNest.Services;
using BEWorkNest.Data;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly SignInManager<User> _signInManager;
        private readonly JwtService _jwtService;
        private readonly RefreshTokenService _refreshTokenService;
        private readonly ApplicationDbContext _context;
        private readonly CloudinaryService _cloudinaryService;

        public AuthController(
            UserManager<User> userManager,
            SignInManager<User> signInManager,
            JwtService jwtService,
            RefreshTokenService refreshTokenService,
            ApplicationDbContext context,
            CloudinaryService cloudinaryService)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _jwtService = jwtService;
            _refreshTokenService = refreshTokenService;
            _context = context;
            _cloudinaryService = cloudinaryService;
        }

        [HttpPost("register/candidate")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> RegisterCandidate([FromForm] RegisterFormDto registerDto)
        {
            try
            {
                // Handle avatar upload if provided
                string? avatarUrl = null;
                if (registerDto.Avatar != null)
                {
                    if (!_cloudinaryService.IsImageFile(registerDto.Avatar))
                    {
                        return BadRequest("Avatar must be an image file");
                    }
                    avatarUrl = await _cloudinaryService.UploadImageAsync(registerDto.Avatar, "avatars");
                }

                var user = new User
                {
                    UserName = registerDto.Email,
                    Email = registerDto.Email,
                    FirstName = registerDto.FirstName,
                    LastName = registerDto.LastName,
                    Role = "candidate",
                    Avatar = avatarUrl
                };

                var result = await _userManager.CreateAsync(user, registerDto.Password);

                if (result.Succeeded)
                {
                    return Ok(new { message = "Candidate registered successfully", userId = user.Id });
                }

                return BadRequest(result.Errors);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Registration failed", error = ex.Message });
            }
        }

        [HttpPost("register/recruiter")]
        [Consumes("multipart/form-data")]
        [AllowAnonymous]
        public async Task<IActionResult> RegisterRecruiter([FromForm] RegisterRecruiterFormDto registerDto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Handle avatar upload if provided
                string? avatarUrl = null;
                if (registerDto.Avatar != null)
                {
                    if (!_cloudinaryService.IsImageFile(registerDto.Avatar))
                    {
                        await transaction.RollbackAsync();
                        return BadRequest("Avatar must be an image file");
                    }
                    avatarUrl = await _cloudinaryService.UploadImageAsync(registerDto.Avatar, "avatars");
                }

                var user = new User
                {
                    UserName = registerDto.Email,
                    Email = registerDto.Email,
                    FirstName = registerDto.FirstName,
                    LastName = registerDto.LastName,
                    Role = "recruiter",
                    Avatar = avatarUrl
                };

                var result = await _userManager.CreateAsync(user, registerDto.Password);
                if (!result.Succeeded)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(result.Errors);
                }

                // Create company
                var company = new Company
                {
                    UserId = user.Id,
                    Name = registerDto.CompanyName,
                    TaxCode = registerDto.TaxCode,
                    Description = registerDto.Description,
                    Location = registerDto.Location
                };
                _context.Companies.Add(company);
                await _context.SaveChangesAsync();

                // Handle company images upload
                List<string> imageUrls = new List<string>();
                if (registerDto.Images != null && registerDto.Images.Count >= 3)
                {
                    // Validate all files are images
                    foreach (var image in registerDto.Images)
                    {
                        if (!_cloudinaryService.IsImageFile(image))
                        {
                            await transaction.RollbackAsync();
                            return BadRequest($"File {image.FileName} is not a valid image file");
                        }
                    }
                    // Upload images to Cloudinary
                    imageUrls = await _cloudinaryService.UploadMultipleImagesAsync(registerDto.Images, "companies");
                }
                else if (registerDto.ImageUrls != null && registerDto.ImageUrls.Count >= 3)
                {
                    // Use provided image URLs
                    imageUrls = registerDto.ImageUrls;
                }
                else
                {
                    await transaction.RollbackAsync();
                    return BadRequest("Company must have at least 3 images");
                }

                // Add company images to database
                foreach (var imageUrl in imageUrls)
                {
                    var companyImage = new CompanyImage
                    {
                        CompanyId = company.Id,
                        ImageUrl = imageUrl
                    };
                    _context.CompanyImages.Add(companyImage);
                }
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return Ok(new { message = "Recruiter registered successfully", userId = user.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { message = "Registration failed", error = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
        {
            var user = await _userManager.FindByEmailAsync(loginDto.Email);
            if (user == null)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            var result = await _signInManager.CheckPasswordSignInAsync(user, loginDto.Password, false);

            if (result.Succeeded)
            {
                // Generate access token and refresh token
                var accessToken = _jwtService.GenerateAccessToken(user);
                var refreshToken = await _refreshTokenService.CreateRefreshTokenAsync(user.Id);
                
                // Load company info if user is recruiter
                CompanyDto? company = null;
                if (user.Role == "recruiter")
                {
                    var userCompany = await _context.Companies
                        .Include(c => c.Images)
                        .FirstOrDefaultAsync(c => c.UserId == user.Id);
                    
                    if (userCompany != null)
                    {
                        company = new CompanyDto
                        {
                            Id = userCompany.Id,
                            Name = userCompany.Name,
                            TaxCode = userCompany.TaxCode,
                            Description = userCompany.Description,
                            Location = userCompany.Location,
                            IsVerified = userCompany.IsVerified,
                            Images = userCompany.Images.Select(i => i.ImageUrl).ToList()
                        };
                    }
                }

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email!,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role,
                    Avatar = user.Avatar,
                    CreatedAt = user.CreatedAt,
                    Company = company
                };

                return Ok(new LoginResponseDto 
                { 
                    AccessToken = accessToken, 
                    RefreshToken = refreshToken.Token,
                    AccessTokenExpiresAt = _jwtService.GetAccessTokenExpirationTime(),
                    RefreshTokenExpiresAt = refreshToken.ExpiresAt,
                    User = userDto 
                });
            }

            return Unauthorized(new { message = "Invalid credentials" });
        }

        [HttpGet("profile")]
        [AllowAnonymous]
        public async Task<IActionResult> GetProfile()
        {
            // Try to get token from Authorization header
            var authHeader = Request.Headers["Authorization"].FirstOrDefault();
            if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer "))
            {
                return BadRequest(new { 
                    message = "Không có token hoặc token không hợp lệ",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var token = authHeader!.Substring("Bearer ".Length).Trim();
            
            try
            {
                // Validate token first
                var isExpired = _jwtService.IsTokenExpired(token);
                if (isExpired)
                {
                    return BadRequest(new { 
                        message = "Token đã hết hạn",
                        errorCode = "TOKEN_EXPIRED"
                    });
                }

                // Extract user ID from token
                var userId = _jwtService.GetUserIdFromToken(token);
                if (string.IsNullOrEmpty(userId))
                {
                    return BadRequest(new { 
                        message = "Không tìm thấy thông tin người dùng trong token",
                        errorCode = "USER_ID_NOT_FOUND"
                    });
                }

                var user = await _userManager.FindByIdAsync(userId);
                if (user == null)
                {
                    return BadRequest(new { 
                        message = "Người dùng không tồn tại trong hệ thống",
                        errorCode = "USER_NOT_FOUND"
                    });
                }

                if (!user.IsActive)
                {
                    return BadRequest(new { 
                        message = "Tài khoản đã bị vô hiệu hóa",
                        errorCode = "ACCOUNT_DISABLED"
                    });
                }

                // Load company info if user is recruiter
                CompanyDto? company = null;
                if (user.Role == "recruiter")
                {
                    var userCompany = await _context.Companies
                        .Include(c => c.Images)
                        .FirstOrDefaultAsync(c => c.UserId == user.Id);
                    
                    if (userCompany != null)
                    {
                        company = new CompanyDto
                        {
                            Id = userCompany.Id,
                            Name = userCompany.Name,
                            TaxCode = userCompany.TaxCode,
                            Description = userCompany.Description,
                            Location = userCompany.Location,
                            IsVerified = userCompany.IsVerified,
                            Images = userCompany.Images.Select(i => i.ImageUrl).ToList()
                        };
                    }
                }

                var userDto = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email!,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role,
                    Avatar = user.Avatar,
                    CreatedAt = user.CreatedAt,
                    Company = company
                };

                return Ok(userDto);
            }
            catch (Exception ex)
            {
                return BadRequest(new { 
                    message = "Lỗi xử lý token", 
                    error = ex.Message,
                    errorCode = "TOKEN_PROCESSING_ERROR"
                });
            }
        }

        // Simple auth test endpoint
        [HttpGet("test-auth")]
        [AllowAnonymous]
        public IActionResult TestAuth()
        {
            var authHeader = Request.Headers["Authorization"].FirstOrDefault();
            var hasAuthHeader = !string.IsNullOrEmpty(authHeader);
            var isBearerToken = authHeader?.StartsWith("Bearer ") == true;
            
            var debugInfo = new
            {
                hasAuthHeader,
                isBearerToken,
                authHeader = hasAuthHeader ? authHeader : null,
                timestamp = DateTime.Now
            };

            if (!hasAuthHeader)
            {
                return Ok(new { message = "No Authorization header", debugInfo });
            }

            if (!isBearerToken)
            {
                return Ok(new { message = "Not a Bearer token", debugInfo });
            }

                            var token = authHeader!.Substring("Bearer ".Length).Trim();
            
            try
            {
                var expirationTime = _jwtService.GetTokenExpirationTime(token);
                var isExpired = _jwtService.IsTokenExpired(token);
                var userId = _jwtService.GetUserIdFromToken(token);
                var role = _jwtService.GetRoleFromToken(token);
                var principal = _jwtService.ValidateToken(token);

                // Extract all claims for detailed analysis
                var allClaims = new List<object>();
                if (principal != null)
                {
                    foreach (var claim in principal.Claims)
                    {
                        allClaims.Add(new { Type = claim.Type, Value = claim.Value });
                    }
                }

                // Check specific User ID claims
                var nameIdentifier = principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var customUserId = principal?.FindFirst("userId")?.Value;
                var email = principal?.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;

                return Ok(new
                {
                    message = "Token analysis",
                    token = token.Substring(0, Math.Min(50, token.Length)) + "...",
                    isValid = !isExpired,
                    expiresAt = expirationTime,
                    isExpired = isExpired,
                    userId = userId,
                    role = role,
                    principal = principal != null ? "Valid" : "Invalid",
                    timeToExpiry = isExpired ? TimeSpan.Zero : expirationTime - DateTime.UtcNow,
                    claims = new
                    {
                        nameIdentifier = nameIdentifier,
                        customUserId = customUserId,
                        email = email,
                        allClaims = allClaims
                    },
                    debugInfo
                });
            }
            catch (Exception ex)
            {
                return Ok(new
                {
                    message = "Token validation error",
                    error = ex.Message,
                    debugInfo
                });
            }
        }

        [HttpGet("token-status")]
        [AllowAnonymous]
        public IActionResult GetTokenStatus()
        {
            var authHeader = Request.Headers["Authorization"].FirstOrDefault();
            if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer "))
            {
                return BadRequest(new { 
                    message = "Không có token hoặc token không hợp lệ",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            try
            {
                var token = authHeader!.Substring("Bearer ".Length).Trim();
                var expirationTime = _jwtService.GetTokenExpirationTime(token);
                var isExpired = _jwtService.IsTokenExpired(token);
                var userId = _jwtService.GetUserIdFromToken(token);
                var role = _jwtService.GetRoleFromToken(token);

                return Ok(new
                {
                    isValid = !isExpired,
                    expiresAt = expirationTime,
                    isExpired = isExpired,
                    userId = userId,
                    role = role,
                    timeToExpiry = isExpired ? TimeSpan.Zero : expirationTime - DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { 
                    message = "Lỗi xử lý token", 
                    error = ex.Message,
                    errorCode = "TOKEN_PROCESSING_ERROR"
                });
            }
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenDto refreshTokenDto)
        {
            // Validate refresh token
            if (!await _refreshTokenService.IsRefreshTokenValidAsync(refreshTokenDto.RefreshToken))
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            // Get refresh token with user info
            var refreshToken = await _refreshTokenService.GetRefreshTokenAsync(refreshTokenDto.RefreshToken);
            if (refreshToken == null || refreshToken.User == null)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            var user = refreshToken.User;
            if (!user.IsActive)
            {
                return Unauthorized(new { message = "User is inactive" });
            }

            // Generate new access token and refresh token
            var newAccessToken = _jwtService.GenerateAccessToken(user);
            var newRefreshToken = await _refreshTokenService.CreateRefreshTokenAsync(user.Id);

            // Revoke old refresh token and replace with new one
            await _refreshTokenService.RevokeRefreshTokenAndReplaceAsync(
                refreshTokenDto.RefreshToken, 
                newRefreshToken.Token, 
                user.Id
            );

            return Ok(new RefreshTokenResponseDto
            {
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken.Token,
                AccessTokenExpiresAt = _jwtService.GetAccessTokenExpirationTime(),
                RefreshTokenExpiresAt = newRefreshToken.ExpiresAt
            });
        }

        [HttpPost("revoke-token")]
        [AllowAnonymous]
        public async Task<IActionResult> RevokeToken([FromBody] RevokeTokenDto revokeTokenDto)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            await _refreshTokenService.RevokeRefreshTokenAsync(
                revokeTokenDto.RefreshToken, 
                userId, 
                "User logout"
            );

            return Ok(new { message = "Token revoked successfully" });
        }

        [HttpPost("revoke-all-tokens")]
        [AllowAnonymous]
        public async Task<IActionResult> RevokeAllTokens()
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            await _refreshTokenService.RevokeAllRefreshTokensForUserAsync(
                userId, 
                userId, 
                "User logout all sessions"
            );

            return Ok(new { message = "All tokens revoked successfully" });
        }

        [HttpPut("profile")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserDto updateDto)
        {
            // Check if user is authenticated
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            if (!isAuthenticated)
            {
                return BadRequest(new { 
                    message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                    errorCode = "AUTH_REQUIRED"
                });
            }

            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return BadRequest(new { 
                    message = "Không tìm thấy thông tin người dùng trong token",
                    errorCode = "USER_ID_NOT_FOUND"
                });
            }

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound();
            }

            // Update user fields
            if (!string.IsNullOrEmpty(updateDto.FirstName))
                user.FirstName = updateDto.FirstName;
            
            if (!string.IsNullOrEmpty(updateDto.LastName))
                user.LastName = updateDto.LastName;
            
            if (!string.IsNullOrEmpty(updateDto.Avatar))
                user.Avatar = updateDto.Avatar;

            user.UpdatedAt = DateTime.UtcNow;

            var result = await _userManager.UpdateAsync(user);
            if (result.Succeeded)
            {
                return Ok(new { message = "Profile updated successfully" });
            }

            return BadRequest(result.Errors);
        }
    }

    public class RegisterRecruiterDto : RegisterDto
    {
        public string CompanyName { get; set; } = string.Empty;
        public string TaxCode { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public List<string> Images { get; set; } = new List<string>();
    }

    public class UpdateUserDto
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Avatar { get; set; }
    }
}
