using System.Globalization;
using System.Net;
using System.Security.Cryptography;
using System.Text;

namespace BEWorkNest.Services
{
    public interface IVNPayService
    {
        string CreatePaymentUrl(int paymentId, decimal amount, string orderInfo, string returnUrl, string ipAddress);
        bool ValidateSignature(IQueryCollection queryParams, string secureHash);
        Dictionary<string, string> ParseVNPayResponse(IQueryCollection queryParams);
    }

    public class VNPayService : IVNPayService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<VNPayService> _logger;

        private string TmnCode => _configuration["VNPay:TmnCode"] ?? "";
        private string HashSecret => _configuration["VNPay:HashSecret"] ?? "";
        private string BaseUrl => _configuration["VNPay:BaseUrl"] ?? "";
        private string Version => _configuration["VNPay:Version"] ?? "2.1.0";
        private string Command => "pay";

        public VNPayService(IConfiguration configuration, ILogger<VNPayService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public string CreatePaymentUrl(int paymentId, decimal amount, string orderInfo, string returnUrl, string ipAddress)
        {
            try
            {
                var vnpay = new VNPayLibrary();
                var timeZoneById = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
                var timeNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZoneById);
                var tick = DateTime.Now.Ticks.ToString();

                vnpay.AddRequestData("vnp_Version", Version);
                vnpay.AddRequestData("vnp_Command", Command);
                vnpay.AddRequestData("vnp_TmnCode", TmnCode);
                vnpay.AddRequestData("vnp_Amount", ((long)(amount * 100)).ToString()); // VNPay yêu cầu amount * 100
                vnpay.AddRequestData("vnp_BankCode", "");
                vnpay.AddRequestData("vnp_CreateDate", timeNow.ToString("yyyyMMddHHmmss"));
                vnpay.AddRequestData("vnp_CurrCode", "VND");
                vnpay.AddRequestData("vnp_IpAddr", ipAddress);
                vnpay.AddRequestData("vnp_Locale", "vn");
                vnpay.AddRequestData("vnp_OrderInfo", orderInfo);
                vnpay.AddRequestData("vnp_OrderType", "other"); // Subscription payment
                vnpay.AddRequestData("vnp_ReturnUrl", returnUrl);
                vnpay.AddRequestData("vnp_TxnRef", paymentId.ToString()); // Payment ID as transaction reference
                vnpay.AddRequestData("vnp_ExpireDate", timeNow.AddMinutes(15).ToString("yyyyMMddHHmmss"));

                var paymentUrl = vnpay.CreateRequestUrl(BaseUrl, HashSecret);

                _logger.LogInformation($"Created VNPay payment URL for payment {paymentId}, amount {amount} VND");

                return paymentUrl;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating VNPay payment URL for payment {paymentId}");
                throw;
            }
        }

        public bool ValidateSignature(IQueryCollection queryParams, string secureHash)
        {
            try
            {
                var vnpay = new VNPayLibrary();
                foreach (var param in queryParams)
                {
                    if (!string.IsNullOrEmpty(param.Value) && param.Key != "vnp_SecureHash" && param.Key != "vnp_SecureHashType")
                    {
                        vnpay.AddResponseData(param.Key, param.Value!);
                    }
                }

                var isValid = vnpay.ValidateSignature(secureHash, HashSecret);

                if (!isValid)
                {
                    _logger.LogWarning("VNPay signature validation failed");
                }

                return isValid;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating VNPay signature");
                return false;
            }
        }

        public Dictionary<string, string> ParseVNPayResponse(IQueryCollection queryParams)
        {
            var result = new Dictionary<string, string>();

            foreach (var param in queryParams)
            {
                if (!string.IsNullOrEmpty(param.Value))
                {
                    result[param.Key] = param.Value.ToString();
                }
            }

            return result;
        }
    }

    // VNPay Library Helper Class
    public class VNPayLibrary
    {
        private readonly SortedList<string, string> _requestData = new SortedList<string, string>(new VnPayCompare());
        private readonly SortedList<string, string> _responseData = new SortedList<string, string>(new VnPayCompare());

        public void AddRequestData(string key, string value)
        {
            if (!string.IsNullOrEmpty(value))
            {
                _requestData.Add(key, value);
            }
        }

        public void AddResponseData(string key, string value)
        {
            if (!string.IsNullOrEmpty(value))
            {
                _responseData.Add(key, value);
            }
        }

        public string GetResponseData(string key)
        {
            return _responseData.TryGetValue(key, out var value) ? value : string.Empty;
        }

        public string CreateRequestUrl(string baseUrl, string hashSecret)
        {
            var data = new StringBuilder();

            foreach (var kv in _requestData)
            {
                if (!string.IsNullOrEmpty(kv.Value))
                {
                    data.Append(WebUtility.UrlEncode(kv.Key) + "=" + WebUtility.UrlEncode(kv.Value) + "&");
                }
            }

            var queryString = data.ToString();

            if (queryString.Length > 0)
            {
                queryString = queryString.Remove(queryString.Length - 1, 1); // Remove last '&'
            }

            var signData = queryString;
            var vnpSecureHash = HmacSHA512(hashSecret, signData);
            
            return $"{baseUrl}?{queryString}&vnp_SecureHash={vnpSecureHash}";
        }

        public bool ValidateSignature(string inputHash, string secretKey)
        {
            var data = new StringBuilder();
            
            foreach (var kv in _responseData)
            {
                if (!string.IsNullOrEmpty(kv.Value))
                {
                    data.Append(WebUtility.UrlEncode(kv.Key) + "=" + WebUtility.UrlEncode(kv.Value) + "&");
                }
            }

            var checkSum = data.ToString();
            
            if (checkSum.Length > 0)
            {
                checkSum = checkSum.Remove(checkSum.Length - 1, 1); // Remove last '&'
            }

            var vnpSecureHash = HmacSHA512(secretKey, checkSum);
            
            return vnpSecureHash.Equals(inputHash, StringComparison.InvariantCultureIgnoreCase);
        }

        private string HmacSHA512(string key, string inputData)
        {
            var hash = new StringBuilder();
            var keyBytes = Encoding.UTF8.GetBytes(key);
            var inputBytes = Encoding.UTF8.GetBytes(inputData);
            
            using (var hmac = new HMACSHA512(keyBytes))
            {
                var hashValue = hmac.ComputeHash(inputBytes);
                foreach (var theByte in hashValue)
                {
                    hash.Append(theByte.ToString("x2"));
                }
            }

            return hash.ToString();
        }
    }

    public class VnPayCompare : IComparer<string>
    {
        public int Compare(string? x, string? y)
        {
            if (x == y) return 0;
            if (x == null) return -1;
            if (y == null) return 1;
            
            var vnpCompare = CompareInfo.GetCompareInfo("en-US");
            return vnpCompare.Compare(x, y, CompareOptions.Ordinal);
        }
    }
}
