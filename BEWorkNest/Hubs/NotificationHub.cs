using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using BEWorkNest.Services;

namespace BEWorkNest.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        private readonly NotificationService _notificationService;
        private readonly ILogger<NotificationHub> _logger;

        public NotificationHub(NotificationService notificationService, ILogger<NotificationHub> logger)
        {
            _notificationService = notificationService;
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (!string.IsNullOrEmpty(userId))
            {
                // Thêm user vào group riêng của họ để nhận notifications
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} connected to notification hub with connection {Context.ConnectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
                _logger.LogInformation($"User {userId} disconnected from notification hub");
            }

            await base.OnDisconnectedAsync(exception);
        }

        // Join chat room for real-time chat notifications
        public async Task JoinChatRoom(string roomId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"chat_{roomId}");
            _logger.LogInformation($"Connection {Context.ConnectionId} joined chat room {roomId}");
        }

        // Leave chat room
        public async Task LeaveChatRoom(string roomId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"chat_{roomId}");
            _logger.LogInformation($"Connection {Context.ConnectionId} left chat room {roomId}");
        }

        // Join company followers group
        public async Task JoinCompanyFollowers(int companyId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"company_{companyId}_followers");
            _logger.LogInformation($"Connection {Context.ConnectionId} joined company {companyId} followers group");
        }

        // Leave company followers group
        public async Task LeaveCompanyFollowers(int companyId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"company_{companyId}_followers");
            _logger.LogInformation($"Connection {Context.ConnectionId} left company {companyId} followers group");
        }
    }
}
