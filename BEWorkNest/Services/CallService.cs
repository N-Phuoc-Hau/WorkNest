using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Concurrent;

namespace BEWorkNest.Services
{
    public class CallService : ICallService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CallService> _logger;
        
        // Store active connections (userId -> connectionId)
        private static readonly ConcurrentDictionary<string, string> _userConnections = new();

        public CallService(ApplicationDbContext context, ILogger<CallService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<Call> InitiateCall(string initiatorId, string receiverId, string callType)
        {
            var call = new Call
            {
                InitiatorId = initiatorId,
                ReceiverId = receiverId,
                CallType = callType,
                Status = "initiated",
                InitiatedAt = DateTime.UtcNow,
                RoomId = Guid.NewGuid().ToString()
            };

            _context.Calls.Add(call);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Call {call.CallId} initiated by {initiatorId} to {receiverId}");

            return call;
        }

        public async Task<Call?> AcceptCall(string callId, string userId)
        {
            var call = await _context.Calls.FindAsync(callId);

            if (call == null || call.ReceiverId != userId)
            {
                _logger.LogWarning($"Call {callId} not found or user {userId} is not the receiver");
                return null;
            }

            if (call.Status != "initiated")
            {
                _logger.LogWarning($"Call {callId} cannot be accepted, current status: {call.Status}");
                return null;
            }

            call.Status = "active";
            call.StartedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Call {callId} accepted by {userId}");

            return call;
        }

        public async Task<Call?> RejectCall(string callId, string userId)
        {
            var call = await _context.Calls.FindAsync(callId);

            if (call == null || call.ReceiverId != userId)
            {
                _logger.LogWarning($"Call {callId} not found or user {userId} is not the receiver");
                return null;
            }

            if (call.Status != "initiated")
            {
                _logger.LogWarning($"Call {callId} cannot be rejected, current status: {call.Status}");
                return null;
            }

            call.Status = "rejected";
            call.EndedAt = DateTime.UtcNow;
            call.EndReason = "rejected";

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Call {callId} rejected by {userId}");

            return call;
        }

        public async Task<Call?> EndCall(string callId, string userId)
        {
            var call = await _context.Calls.FindAsync(callId);

            if (call == null)
            {
                _logger.LogWarning($"Call {callId} not found");
                return null;
            }

            if (call.InitiatorId != userId && call.ReceiverId != userId)
            {
                _logger.LogWarning($"User {userId} is not part of call {callId}");
                return null;
            }

            if (call.Status == "ended" || call.Status == "rejected")
            {
                _logger.LogWarning($"Call {callId} already ended");
                return call;
            }

            call.Status = "ended";
            call.EndedAt = DateTime.UtcNow;

            if (call.StartedAt.HasValue)
            {
                call.Duration = (int)(call.EndedAt.Value - call.StartedAt.Value).TotalSeconds;
            }

            call.EndReason = call.InitiatorId == userId ? "ended_by_initiator" : "ended_by_receiver";

            await _context.SaveChangesAsync();

            _logger.LogInformation($"Call {callId} ended by {userId}");

            return call;
        }

        public async Task<Call?> GetCall(string callId)
        {
            return await _context.Calls
                .Include(c => c.Initiator)
                .Include(c => c.Receiver)
                .FirstOrDefaultAsync(c => c.CallId == callId);
        }

        public async Task<Call?> GetActiveCall(string userId)
        {
            return await _context.Calls
                .Include(c => c.Initiator)
                .Include(c => c.Receiver)
                .Where(c => (c.InitiatorId == userId || c.ReceiverId == userId) 
                         && (c.Status == "active" || c.Status == "initiated"))
                .OrderByDescending(c => c.InitiatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<List<Call>> GetCallHistory(string userId, int pageNumber = 1, int pageSize = 20)
        {
            return await _context.Calls
                .Include(c => c.Initiator)
                .Include(c => c.Receiver)
                .Where(c => c.InitiatorId == userId || c.ReceiverId == userId)
                .OrderByDescending(c => c.InitiatedAt)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public Task<string?> GetUserConnectionId(string userId)
        {
            _userConnections.TryGetValue(userId, out var connectionId);
            return Task.FromResult(connectionId);
        }

        public Task SetUserConnectionId(string userId, string connectionId)
        {
            _userConnections[userId] = connectionId;
            _logger.LogInformation($"User {userId} connection set to {connectionId}");
            return Task.CompletedTask;
        }

        public Task RemoveUserConnectionId(string userId)
        {
            _userConnections.TryRemove(userId, out _);
            _logger.LogInformation($"User {userId} connection removed");
            return Task.CompletedTask;
        }

        public Task<bool> IsUserOnline(string userId)
        {
            var isOnline = _userConnections.ContainsKey(userId);
            _logger.LogInformation($"User {userId} online status: {isOnline}");
            return Task.FromResult(isOnline);
        }
    }
}
