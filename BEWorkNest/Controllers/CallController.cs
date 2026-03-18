using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Services;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CallController : ControllerBase
    {
        private readonly ICallService _callService;
        private readonly JwtService _jwtService;
        private readonly ILogger<CallController> _logger;

        public CallController(
            ICallService callService,
            JwtService jwtService,
            ILogger<CallController> logger)
        {
            _callService = callService;
            _jwtService = jwtService;
            _logger = logger;
        }

        // Helper method to get user info from JWT token
        private (string? userId, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            // If not found from claims, try to extract from Authorization header
            if (string.IsNullOrEmpty(userId) && Request.Headers.ContainsKey("Authorization"))
            {
                var authHeader = Request.Headers["Authorization"].FirstOrDefault();
                if (authHeader != null && authHeader.StartsWith("Bearer "))
                {
                    var token = authHeader.Substring("Bearer ".Length).Trim();
                    if (!string.IsNullOrEmpty(token))
                    {
                        try
                        {
                            userId = _jwtService.GetUserIdFromToken(token);
                            isAuthenticated = !string.IsNullOrEmpty(userId);
                        }
                        catch (Exception)
                        {
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, isAuthenticated);
        }

        /// <summary>
        /// Kiểm tra trạng thái online của user
        /// </summary>
        [HttpGet("users/{userId}/online-status")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckUserOnlineStatus(string userId)
        {
            try
            {
                var (currentUserId, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(currentUserId))
                {
                    return Unauthorized(new
                    {
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Checking online status for user {userId}");

                var isOnline = await _callService.IsUserOnline(userId);

                return Ok(new
                {
                    success = true,
                    userId = userId,
                    isOnline = isOnline
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking online status for user {userId}");
                return StatusCode(500, new
                {
                    message = "Lỗi khi kiểm tra trạng thái online",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// Lấy lịch sử cuộc gọi
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> GetCallHistory([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
        {
            try
            {
                var (userId, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Getting call history for user {userId}, page {pageNumber}");

                var calls = await _callService.GetCallHistory(userId, pageNumber, pageSize);

                return Ok(new
                {
                    success = true,
                    data = calls,
                    pageNumber = pageNumber,
                    pageSize = pageSize
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting call history");
                return StatusCode(500, new
                {
                    message = "Lỗi khi lấy lịch sử cuộc gọi",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// Lấy thông tin cuộc gọi đang hoạt động
        /// </summary>
        [HttpGet("active")]
        public async Task<IActionResult> GetActiveCall()
        {
            try
            {
                var (userId, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Getting active call for user {userId}");

                var activeCall = await _callService.GetActiveCall(userId);

                return Ok(new
                {
                    success = true,
                    data = activeCall
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active call");
                return StatusCode(500, new
                {
                    message = "Lỗi khi lấy thông tin cuộc gọi",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// Lấy chi tiết cuộc gọi
        /// </summary>
        [HttpGet("{callId}")]
        public async Task<IActionResult> GetCall(string callId)
        {
            try
            {
                var (userId, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new
                    {
                        message = "Không có quyền truy cập. Vui lòng đăng nhập.",
                        errorCode = "AUTH_REQUIRED"
                    });
                }

                _logger.LogInformation($"Getting call {callId} for user {userId}");

                var call = await _callService.GetCall(callId);

                if (call == null)
                {
                    return NotFound(new
                    {
                        message = "Không tìm thấy cuộc gọi",
                        errorCode = "CALL_NOT_FOUND"
                    });
                }

                // Check if user is part of the call
                if (call.InitiatorId != userId && call.ReceiverId != userId)
                {
                    return Forbid();
                }

                return Ok(new
                {
                    success = true,
                    data = call
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting call {callId}");
                return StatusCode(500, new
                {
                    message = "Lỗi khi lấy thông tin cuộc gọi",
                    error = ex.Message
                });
            }
        }
    }
}
