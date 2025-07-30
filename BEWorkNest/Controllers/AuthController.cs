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

        public AuthController(
            UserManager<User> userManager,
            SignInManager<User> signInManager,
            JwtService jwtService,
            RefreshTokenService refreshTokenService,
            ApplicationDbContext context)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _jwtService = jwtService;
            _refreshTokenService = refreshTokenService;
            _context = context;
        }

        [HttpPost("register/candidate")]
        public async Task<IActionResult> RegisterCandidate([FromBody] RegisterDto registerDto)
        {
            var user = new User
            {
                UserName = registerDto.Email,
                Email = registerDto.Email,
                FirstName = registerDto.FirstName,
                LastName = registerDto.LastName,
                Role = "candidate",
                Avatar = registerDto.Avatar
            };

            var result = await _userManager.CreateAsync(user, registerDto.Password);

            if (result.Succeeded)
            {
                return Ok(new { message = "Candidate registered successfully", userId = user.Id });
            }

            return BadRequest(result.Errors);
        }

        [HttpPost("register/recruiter")]
        public async Task<IActionResult> RegisterRecruiter([FromBody] RegisterRecruiterDto registerDto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            
            try
            {
                var user = new User
                {
                    UserName = registerDto.Email,
                    Email = registerDto.Email,
                    FirstName = registerDto.FirstName,
                    LastName = registerDto.LastName,
                    Role = "recruiter",
                    Avatar = registerDto.Avatar
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

                // Add company images
                if (registerDto.Images != null && registerDto.Images.Count >= 3)
                {
                    foreach (var imageUrl in registerDto.Images)
                    {
                        var companyImage = new CompanyImage
                        {
                            CompanyId = company.Id,
                            ImageUrl = imageUrl
                        };
                        _context.CompanyImages.Add(companyImage);
                    }
                    await _context.SaveChangesAsync();
                }
                else
                {
                    await transaction.RollbackAsync();
                    return BadRequest("Công ty phải có ít nhất 3 ảnh môi trường làm việc");
                }

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
        [Authorize]
        public async Task<IActionResult> GetProfile()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return NotFound();
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

        [HttpGet("token-status")]
        [Authorize]
        public IActionResult GetTokenStatus()
        {
            var authHeader = Request.Headers["Authorization"].FirstOrDefault();
            if (authHeader?.StartsWith("Bearer ") == true)
            {
                var token = authHeader.Substring("Bearer ".Length).Trim();
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

            return BadRequest("No valid token found");
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
        [Authorize]
        public async Task<IActionResult> RevokeToken([FromBody] RevokeTokenDto revokeTokenDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            await _refreshTokenService.RevokeRefreshTokenAsync(
                revokeTokenDto.RefreshToken, 
                userId, 
                "User logout"
            );

            return Ok(new { message = "Token revoked successfully" });
        }

        [HttpPost("revoke-all-tokens")]
        [Authorize]
        public async Task<IActionResult> RevokeAllTokens()
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
            }

            await _refreshTokenService.RevokeAllRefreshTokensForUserAsync(
                userId, 
                userId, 
                "User logout all sessions"
            );

            return Ok(new { message = "All tokens revoked successfully" });
        }

        [HttpPut("profile")]
        [Authorize]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserDto updateDto)
        {
            var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized();
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
