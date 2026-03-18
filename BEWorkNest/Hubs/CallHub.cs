using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using BEWorkNest.Services;
using System.Security.Claims;

namespace BEWorkNest.Hubs
{
    [Authorize]
    public class CallHub : Hub
    {
        private readonly ICallService _callService;
        private readonly ILogger<CallHub> _logger;

        public CallHub(ICallService callService, ILogger<CallHub> logger)
        {
            _callService = callService;
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId != null)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
                await _callService.SetUserConnectionId(userId, Context.ConnectionId);
                _logger.LogInformation($"User {userId} connected to CallHub with connection {Context.ConnectionId}");
            }
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId != null)
            {
                await _callService.RemoveUserConnectionId(userId);
                
                // Check if user has an active call and end it
                var activeCall = await _callService.GetActiveCall(userId);
                if (activeCall != null)
                {
                    await _callService.EndCall(activeCall.CallId, userId);
                    
                    // Notify the other participant
                    var otherUserId = activeCall.InitiatorId == userId ? activeCall.ReceiverId : activeCall.InitiatorId;
                    await Clients.Group($"user_{otherUserId}").SendAsync("CallEnded", new
                    {
                        callId = activeCall.CallId,
                        reason = "disconnected"
                    });
                }

                _logger.LogInformation($"User {userId} disconnected from CallHub");
            }
            await base.OnDisconnectedAsync(exception);
        }

        public async Task InitiateCall(string receiverId, string callType)
        {
            var initiatorId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (initiatorId == null) 
            {
                _logger.LogWarning("InitiateCall called without valid user identity");
                return;
            }

            try
            {
                var call = await _callService.InitiateCall(initiatorId, receiverId, callType);

                // Notify receiver
                await Clients.Group($"user_{receiverId}").SendAsync("IncomingCall", new
                {
                    callId = call.CallId,
                    initiatorId,
                    callType,
                    roomId = call.RoomId,
                    timestamp = DateTime.UtcNow
                });

                // Confirm to initiator
                await Clients.Caller.SendAsync("CallInitiated", new
                {
                    callId = call.CallId,
                    roomId = call.RoomId,
                    status = "initiated"
                });

                _logger.LogInformation($"Call {call.CallId} initiated from {initiatorId} to {receiverId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error initiating call from {initiatorId} to {receiverId}");
                await Clients.Caller.SendAsync("CallError", new { message = "Failed to initiate call" });
            }
        }

        public async Task AcceptCall(string callId)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null) return;

            try
            {
                var call = await _callService.AcceptCall(callId, userId);

                if (call != null)
                {
                    var roomId = call.RoomId ?? call.CallId;
                    
                    // Add both users to call room
                    await Groups.AddToGroupAsync(Context.ConnectionId, roomId);
                    
                    var initiatorConnectionId = await _callService.GetUserConnectionId(call.InitiatorId);
                    if (initiatorConnectionId != null)
                    {
                        await Groups.AddToGroupAsync(initiatorConnectionId, roomId);
                    }

                    // Notify initiator
                    await Clients.Group($"user_{call.InitiatorId}").SendAsync("CallAccepted", new
                    {
                        callId,
                        roomId,
                        receiverId = userId
                    });

                    // Confirm to receiver
                    await Clients.Caller.SendAsync("CallAcceptConfirmed", new
                    {
                        callId,
                        roomId,
                        initiatorId = call.InitiatorId
                    });

                    _logger.LogInformation($"Call {callId} accepted by {userId}");
                }
                else
                {
                    await Clients.Caller.SendAsync("CallError", new { message = "Failed to accept call" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error accepting call {callId}");
                await Clients.Caller.SendAsync("CallError", new { message = "Failed to accept call" });
            }
        }

        public async Task RejectCall(string callId)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null) return;

            try
            {
                var call = await _callService.RejectCall(callId, userId);

                if (call != null)
                {
                    await Clients.Group($"user_{call.InitiatorId}").SendAsync("CallRejected", new
                    {
                        callId,
                        receiverId = userId
                    });

                    _logger.LogInformation($"Call {callId} rejected by {userId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error rejecting call {callId}");
            }
        }

        public async Task SendSignal(string roomId, string signalType, object signal)
        {
            // Forward WebRTC signals (offer, answer, ICE candidates)
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            await Clients.OthersInGroup(roomId).SendAsync("ReceiveSignal", new
            {
                userId,
                signalType,
                signal
            });

            _logger.LogDebug($"Signal {signalType} sent by {userId} to room {roomId}");
        }

        public async Task EndCall(string callId)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null) return;

            try
            {
                var call = await _callService.EndCall(callId, userId);

                if (call != null)
                {
                    var roomId = call.RoomId ?? call.CallId;

                    await Clients.Group(roomId).SendAsync("CallEnded", new
                    {
                        callId,
                        endedBy = userId,
                        duration = call.Duration,
                        reason = call.EndReason
                    });

                    // Remove users from room
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomId);
                    
                    var otherUserId = call.InitiatorId == userId ? call.ReceiverId : call.InitiatorId;
                    var otherConnectionId = await _callService.GetUserConnectionId(otherUserId);
                    if (otherConnectionId != null)
                    {
                        await Groups.RemoveFromGroupAsync(otherConnectionId, roomId);
                    }

                    _logger.LogInformation($"Call {callId} ended by {userId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error ending call {callId}");
            }
        }

        public async Task ToggleMute(string roomId, bool isMuted)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            await Clients.OthersInGroup(roomId).SendAsync("ParticipantMuted", new
            {
                userId,
                isMuted
            });
        }

        public async Task ToggleVideo(string roomId, bool isVideoOff)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            await Clients.OthersInGroup(roomId).SendAsync("ParticipantVideoToggled", new
            {
                userId,
                isVideoOff
            });
        }
    }
}
