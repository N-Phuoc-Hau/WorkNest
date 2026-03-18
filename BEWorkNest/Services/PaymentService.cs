using BEWorkNest.Data;
using BEWorkNest.Models;
using Microsoft.EntityFrameworkCore;

namespace BEWorkNest.Services
{
    public interface IPaymentService
    {
        Task<Payment> CreatePayment(string userId, int planId, string gateway, string ipAddress);
        Task<Payment?> GetPaymentById(int id);
        Task<Payment?> GetPaymentByTransactionId(string transactionId);
        Task<bool> UpdatePaymentStatus(int paymentId, string status, string? transactionId = null, string? responseCode = null);
        Task<List<Payment>> GetUserPayments(string userId);
        Task<bool> ProcessPaymentSuccess(Payment payment);
    }

    public class PaymentService : IPaymentService
    {
        private readonly ApplicationDbContext _context;
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(
            ApplicationDbContext context,
            ISubscriptionService subscriptionService,
            ILogger<PaymentService> logger)
        {
            _context = context;
            _subscriptionService = subscriptionService;
            _logger = logger;
        }

        public async Task<Payment> CreatePayment(string userId, int planId, string gateway, string ipAddress)
        {
            try
            {
                var plan = await _context.SubscriptionPlans.FindAsync(planId);
                if (plan == null)
                {
                    throw new InvalidOperationException($"Subscription plan {planId} not found");
                }

                var payment = new Payment
                {
                    UserId = userId,
                    Amount = plan.Price,
                    Currency = "VND",
                    PaymentMethod = gateway,
                    Status = "Pending",
                    IpAddress = ipAddress,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Created payment {payment.Id} for user {userId}, plan {planId}, amount {plan.Price} VND");

                return payment;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating payment for user {userId}, plan {planId}");
                throw;
            }
        }

        public async Task<Payment?> GetPaymentById(int id)
        {
            try
            {
                return await _context.Payments.FindAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting payment {id}");
                return null;
            }
        }

        public async Task<Payment?> GetPaymentByTransactionId(string transactionId)
        {
            try
            {
                return await _context.Payments
                    .FirstOrDefaultAsync(p => p.TransactionId == transactionId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting payment by transaction ID {transactionId}");
                return null;
            }
        }

        public async Task<bool> UpdatePaymentStatus(int paymentId, string status, string? transactionId = null, string? responseCode = null)
        {
            try
            {
                var payment = await _context.Payments.FindAsync(paymentId);
                if (payment == null)
                {
                    _logger.LogWarning($"Payment {paymentId} not found");
                    return false;
                }

                payment.Status = status;
                payment.UpdatedAt = DateTime.UtcNow;

                if (!string.IsNullOrEmpty(transactionId))
                {
                    payment.TransactionId = transactionId;
                }

                if (!string.IsNullOrEmpty(responseCode))
                {
                    payment.ResponseCode = responseCode;
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Updated payment {paymentId} status to {status}");

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating payment {paymentId} status");
                return false;
            }
        }

        public async Task<List<Payment>> GetUserPayments(string userId)
        {
            try
            {
                return await _context.Payments
                    .Where(p => p.UserId == userId)
                    .OrderByDescending(p => p.CreatedAt)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting payments for user {userId}");
                return new List<Payment>();
            }
        }

        public async Task<bool> ProcessPaymentSuccess(Payment payment)
        {
            try
            {
                // Update payment status
                await UpdatePaymentStatus(payment.Id, "Success");

                // Find the subscription plan based on payment amount
                var plan = await _context.SubscriptionPlans
                    .FirstOrDefaultAsync(p => p.Price == payment.Amount && p.IsActive);

                if (plan == null)
                {
                    _logger.LogError($"No matching subscription plan found for payment {payment.Id} with amount {payment.Amount}");
                    return false;
                }

                // Create subscription for user
                var subscription = await _subscriptionService.CreateSubscription(
                    payment.UserId, 
                    plan.Id, 
                    payment.Id
                );

                _logger.LogInformation($"Successfully processed payment {payment.Id} and created subscription {subscription.Id} for user {payment.UserId}");

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing payment success for payment {payment.Id}");
                return false;
            }
        }
    }
}
