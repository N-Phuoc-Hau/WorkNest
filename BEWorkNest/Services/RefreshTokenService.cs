using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Services
{
    public class RefreshTokenService
    {
        private readonly ApplicationDbContext _context;
        private readonly JwtService _jwtService;

        public RefreshTokenService(ApplicationDbContext context, JwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        public async Task<RefreshToken> CreateRefreshTokenAsync(string userId)
        {
            var refreshToken = new RefreshToken
            {
                Token = _jwtService.GenerateRefreshToken(),
                UserId = userId,
                ExpiresAt = _jwtService.GetRefreshTokenExpirationTime(),
                CreatedAt = DateTime.UtcNow
            };

            _context.RefreshTokens.Add(refreshToken);
            await _context.SaveChangesAsync();

            return refreshToken;
        }

        public async Task<RefreshToken?> GetRefreshTokenAsync(string token)
        {
            return await _context.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == token);
        }

        public async Task<bool> IsRefreshTokenValidAsync(string token)
        {
            var refreshToken = await GetRefreshTokenAsync(token);
            
            if (refreshToken == null)
                return false;

            if (refreshToken.IsRevoked)
                return false;

            if (refreshToken.ExpiresAt < DateTime.UtcNow)
                return false;

            return true;
        }

        public async Task RevokeRefreshTokenAsync(string token, string? revokedBy = null, string? reason = null)
        {
            var refreshToken = await GetRefreshTokenAsync(token);
            
            if (refreshToken != null)
            {
                refreshToken.IsRevoked = true;
                refreshToken.RevokedBy = revokedBy;
                refreshToken.RevokedAt = DateTime.UtcNow;
                refreshToken.ReasonRevoked = reason;

                await _context.SaveChangesAsync();
            }
        }

        public async Task RevokeAllRefreshTokensForUserAsync(string userId, string? revokedBy = null, string? reason = null)
        {
            var refreshTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == userId && !rt.IsRevoked)
                .ToListAsync();

            foreach (var refreshToken in refreshTokens)
            {
                refreshToken.IsRevoked = true;
                refreshToken.RevokedBy = revokedBy;
                refreshToken.RevokedAt = DateTime.UtcNow;
                refreshToken.ReasonRevoked = reason;
            }

            await _context.SaveChangesAsync();
        }

        public async Task RevokeRefreshTokenAndReplaceAsync(string oldToken, string newToken, string? revokedBy = null)
        {
            var oldRefreshToken = await GetRefreshTokenAsync(oldToken);
            
            if (oldRefreshToken != null)
            {
                oldRefreshToken.IsRevoked = true;
                oldRefreshToken.RevokedBy = revokedBy;
                oldRefreshToken.RevokedAt = DateTime.UtcNow;
                oldRefreshToken.ReplacedByToken = newToken;
                oldRefreshToken.ReasonRevoked = "Replaced by new token";

                await _context.SaveChangesAsync();
            }
        }

        public async Task CleanupExpiredRefreshTokensAsync()
        {
            var expiredTokens = await _context.RefreshTokens
                .Where(rt => rt.ExpiresAt < DateTime.UtcNow)
                .ToListAsync();

            _context.RefreshTokens.RemoveRange(expiredTokens);
            await _context.SaveChangesAsync();
        }

        public async Task<List<RefreshToken>> GetUserRefreshTokensAsync(string userId)
        {
            return await _context.RefreshTokens
                .Where(rt => rt.UserId == userId)
                .OrderByDescending(rt => rt.CreatedAt)
                .ToListAsync();
        }
    }
} 