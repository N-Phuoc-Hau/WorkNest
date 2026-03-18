using BEWorkNest.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BEWorkNest.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IVNPayService _vnpayService;
        private readonly IZaloPayService _zalopayService;
        private readonly ISubscriptionService _subscriptionService;
        private readonly ILogger<PaymentController> _logger;
        private readonly IConfiguration _configuration;
        private readonly Services.JwtService _jwtService;

        public PaymentController(
            IPaymentService paymentService,
            IVNPayService vnpayService,
            IZaloPayService zalopayService,
            ISubscriptionService subscriptionService,
            ILogger<PaymentController> logger,
            IConfiguration configuration,
            Services.JwtService jwtService)
        {
            _paymentService = paymentService;
            _vnpayService = vnpayService;
            _zalopayService = zalopayService;
            _subscriptionService = subscriptionService;
            _logger = logger;
            _configuration = configuration;
            _jwtService = jwtService;
        }

        // Helper method to get user info from JWT token
        private (string? userId, string? userRole, bool isAuthenticated) GetUserInfoFromToken()
        {
            var isAuthenticated = User.Identity?.IsAuthenticated ?? false;
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRole = User.FindFirst("role")?.Value;

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
                            userRole = _jwtService.GetRoleFromToken(token);
                            isAuthenticated = !string.IsNullOrEmpty(userId);
                        }
                        catch (Exception)
                        {
                            isAuthenticated = false;
                        }
                    }
                }
            }

            return (userId, userRole, isAuthenticated);
        }

        /// <summary>
        /// Create payment for subscription plan
        /// </summary>
        [HttpPost("create")]
        [AllowAnonymous]
        public async Task<ActionResult<PaymentResponse>> CreatePayment([FromBody] CreatePaymentRequest request)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new PaymentResponse
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn"
                    });
                }

                var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";

                // Create payment record
                var payment = await _paymentService.CreatePayment(userId, request.PlanId, request.Gateway, ipAddress);

                // Get plan details for order info
                var plan = await _subscriptionService.GetPlanById(request.PlanId);
                if (plan == null)
                {
                    return BadRequest(new PaymentResponse
                    {
                        Success = false,
                        Message = "Subscription plan not found"
                    });
                }

                var orderInfo = $"Thanh toan goi {plan.Name} - WorkNest";

                // Generate payment URL based on gateway
                string paymentUrl;
                string? transactionId = null;

                if (request.Gateway.ToLower() == "vnpay")
                {
                    var returnUrl = _configuration["VNPay:ReturnUrl"] ?? $"{Request.Scheme}://{Request.Host}/api/payment/vnpay-callback";
                    paymentUrl = _vnpayService.CreatePaymentUrl(payment.Id, payment.Amount, orderInfo, returnUrl, ipAddress);
                }
                else if (request.Gateway.ToLower() == "zalopay")
                {
                    var zaloPayResponse = await _zalopayService.CreateOrder(payment.Id, payment.Amount, orderInfo, userId);
                    
                    if (zaloPayResponse.ReturnCode != 1)
                    {
                        _logger.LogError($"ZaloPay order creation failed: {zaloPayResponse.ReturnMessage}");
                        return BadRequest(new PaymentResponse
                        {
                            Success = false,
                            Message = $"ZaloPay error: {zaloPayResponse.SubReturnMessage}"
                        });
                    }

                    paymentUrl = zaloPayResponse.OrderUrl;
                    transactionId = zaloPayResponse.AppTransId;
                    
                    // Update payment with ZaloPay transaction ID
                    await _paymentService.UpdatePaymentStatus(payment.Id, "Pending", transactionId);
                }
                else
                {
                    return BadRequest(new PaymentResponse
                    {
                        Success = false,
                        Message = "Unsupported payment gateway. Use 'vnpay' or 'zalopay'"
                    });
                }

                return Ok(new PaymentResponse
                {
                    Success = true,
                    Message = "Payment created successfully",
                    PaymentId = payment.Id,
                    PaymentUrl = paymentUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating payment");
                return StatusCode(500, new PaymentResponse
                {
                    Success = false,
                    Message = "Error creating payment"
                });
            }
        }

        /// <summary>
        /// VNPay payment callback (IPN - Instant Payment Notification)
        /// </summary>
        [HttpGet("vnpay-callback")]
        [AllowAnonymous]
        public async Task<IActionResult> VNPayCallback()
        {
            try
            {
                _logger.LogInformation("VNPay callback received");

                var queryParams = Request.Query;
                var vnpayData = _vnpayService.ParseVNPayResponse(queryParams);

                // Get secure hash from query
                var secureHash = queryParams["vnp_SecureHash"].ToString();

                // Validate signature
                if (!_vnpayService.ValidateSignature(queryParams, secureHash))
                {
                    _logger.LogWarning("VNPay signature validation failed");
                    return Redirect($"{_configuration["Frontend:Url"]}/payment/failed?message=Invalid signature");
                }

                // Get payment info
                var txnRef = queryParams["vnp_TxnRef"].ToString(); // This is our payment ID
                var responseCode = queryParams["vnp_ResponseCode"].ToString();
                var transactionNo = queryParams["vnp_TransactionNo"].ToString();

                if (!int.TryParse(txnRef, out int paymentId))
                {
                    _logger.LogError($"Invalid payment ID: {txnRef}");
                    return Redirect($"{_configuration["Frontend:Url"]}/payment/failed?message=Invalid payment reference");
                }

                var payment = await _paymentService.GetPaymentById(paymentId);
                if (payment == null)
                {
                    _logger.LogError($"Payment {paymentId} not found");
                    return Redirect($"{_configuration["Frontend:Url"]}/payment/failed?message=Payment not found");
                }

                // Check response code
                if (responseCode == "00") // Success
                {
                    await _paymentService.UpdatePaymentStatus(paymentId, "Success", transactionNo, responseCode);
                    await _paymentService.ProcessPaymentSuccess(payment);

                    _logger.LogInformation($"Payment {paymentId} processed successfully");
                    return Redirect($"{_configuration["Frontend:Url"]}/payment/success?paymentId={paymentId}");
                }
                else
                {
                    await _paymentService.UpdatePaymentStatus(paymentId, "Failed", transactionNo, responseCode);

                    _logger.LogWarning($"Payment {paymentId} failed with response code {responseCode}");
                    return Redirect($"{_configuration["Frontend:Url"]}/payment/failed?paymentId={paymentId}&code={responseCode}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing VNPay callback");
                return Redirect($"{_configuration["Frontend:Url"]}/payment/failed?message=Processing error");
            }
        }

        /// <summary>
        /// ZaloPay payment callback (IPN - Instant Payment Notification)
        /// </summary>
        [HttpPost("zalopay-callback")]
        [AllowAnonymous]
        public async Task<IActionResult> ZaloPayCallback()
        {
            try
            {
                _logger.LogInformation("ZaloPay callback received");

                var formParams = Request.Form;
                var callbackData = _zalopayService.ParseZaloPayCallback(formParams);

                if (!callbackData.ContainsKey("data") || !callbackData.ContainsKey("mac"))
                {
                    _logger.LogError("ZaloPay callback missing required fields");
                    return Ok(new { return_code = -1, return_message = "Missing required fields" });
                }

                var mac = callbackData["mac"];

                // Validate MAC
                if (!_zalopayService.ValidateCallback(callbackData, mac))
                {
                    _logger.LogWarning("ZaloPay MAC validation failed");
                    return Ok(new { return_code = -1, return_message = "Invalid MAC" });
                }

                // Parse callback data
                var dataJson = callbackData["data"];
                var cbData = Newtonsoft.Json.JsonConvert.DeserializeObject<ZaloPayCallbackData>(dataJson);

                if (cbData == null)
                {
                    _logger.LogError("Failed to parse ZaloPay callback data");
                    return Ok(new { return_code = 0, return_message = "Failed to parse data" });
                }

                // Extract payment ID from app_trans_id (format: yyMMdd_paymentId)
                var appTransIdParts = cbData.AppTransId.Split('_');
                if (appTransIdParts.Length != 2 || !int.TryParse(appTransIdParts[1], out int paymentId))
                {
                    _logger.LogError($"Invalid app_trans_id format: {cbData.AppTransId}");
                    return Ok(new { return_code = 0, return_message = "Invalid transaction reference" });
                }

                var payment = await _paymentService.GetPaymentById(paymentId);
                if (payment == null)
                {
                    _logger.LogError($"Payment {paymentId} not found");
                    return Ok(new { return_code = 0, return_message = "Payment not found" });
                }

                // Process successful payment
                await _paymentService.UpdatePaymentStatus(paymentId, "Success", cbData.ZpTransId.ToString(), "1");
                await _paymentService.ProcessPaymentSuccess(payment);

                _logger.LogInformation($"ZaloPay payment {paymentId} processed successfully, ZpTransId: {cbData.ZpTransId}");

                // Return success to ZaloPay
                return Ok(new { return_code = 1, return_message = "success" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing ZaloPay callback");
                return Ok(new { return_code = 0, return_message = "Processing error" });
            }
        }

        /// <summary>
        /// Get payment details
        /// </summary>
        [HttpGet("{paymentId}")]
        [AllowAnonymous]
        public async Task<ActionResult<PaymentDetailsResponse>> GetPayment(int paymentId)
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new PaymentDetailsResponse
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn"
                    });
                }

                var payment = await _paymentService.GetPaymentById(paymentId);

                if (payment == null)
                {
                    return NotFound(new PaymentDetailsResponse
                    {
                        Success = false,
                        Message = "Payment not found"
                    });
                }

                if (payment.UserId != userId)
                {
                    return Forbid();
                }

                return Ok(new PaymentDetailsResponse
                {
                    Success = true,
                    Message = "Payment retrieved successfully",
                    PaymentId = payment.Id,
                    Amount = payment.Amount,
                    Currency = payment.Currency,
                    Status = payment.Status,
                    PaymentMethod = payment.PaymentMethod,
                    TransactionId = payment.TransactionId,
                    CreatedAt = payment.CreatedAt
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting payment {paymentId}");
                return StatusCode(500, new PaymentDetailsResponse
                {
                    Success = false,
                    Message = "Error retrieving payment"
                });
            }
        }

        /// <summary>
        /// Get user's payment history
        /// </summary>
        [HttpGet("history")]
        [AllowAnonymous]
        public async Task<ActionResult<PaymentHistoryResponse>> GetPaymentHistory()
        {
            try
            {
                // Get user info from JWT token
                var (userId, userRole, isAuthenticated) = GetUserInfoFromToken();

                if (!isAuthenticated || string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new PaymentHistoryResponse
                    {
                        Success = false,
                        Message = "Token không hợp lệ hoặc đã hết hạn"
                    });
                }

                var payments = await _paymentService.GetUserPayments(userId);

                var paymentDtos = payments.Select(p => new PaymentDto
                {
                    Id = p.Id,
                    Amount = p.Amount,
                    Currency = p.Currency,
                    Status = p.Status,
                    PaymentMethod = p.PaymentMethod,
                    TransactionId = p.TransactionId,
                    CreatedAt = p.CreatedAt
                }).ToList();

                return Ok(new PaymentHistoryResponse
                {
                    Success = true,
                    Message = "Payment history retrieved successfully",
                    Payments = paymentDtos
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting payment history");
                return StatusCode(500, new PaymentHistoryResponse
                {
                    Success = false,
                    Message = "Error retrieving payment history"
                });
            }
        }
    }

    // Request/Response DTOs
    public class CreatePaymentRequest
    {
        public int PlanId { get; set; }
        public string Gateway { get; set; } = "vnpay";
    }

    public class PaymentResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = "";
        public int? PaymentId { get; set; }
        public string? PaymentUrl { get; set; }
    }

    public class PaymentDetailsResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = "";
        public int? PaymentId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "";
        public string Status { get; set; } = "";
        public string PaymentMethod { get; set; } = "";
        public string? TransactionId { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class PaymentHistoryResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = "";
        public List<PaymentDto> Payments { get; set; } = new();
    }

    public class PaymentDto
    {
        public int Id { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "";
        public string Status { get; set; } = "";
        public string PaymentMethod { get; set; } = "";
        public string? TransactionId { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
