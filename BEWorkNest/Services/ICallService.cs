using BEWorkNest.Models;

namespace BEWorkNest.Services
{
    public interface ICallService
    {
        Task<Call> InitiateCall(string initiatorId, string receiverId, string callType);
        Task<Call?> AcceptCall(string callId, string userId);
        Task<Call?> RejectCall(string callId, string userId);
        Task<Call?> EndCall(string callId, string userId);
        Task<Call?> GetCall(string callId);
        Task<Call?> GetActiveCall(string userId);
        Task<List<Call>> GetCallHistory(string userId, int pageNumber = 1, int pageSize = 20);
        Task<string?> GetUserConnectionId(string userId);
        Task SetUserConnectionId(string userId, string connectionId);
        Task RemoveUserConnectionId(string userId);
        Task<bool> IsUserOnline(string userId);
    }
}
