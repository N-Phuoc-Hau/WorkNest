using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json;

namespace BEWorkNest.Services
{
    public interface IZaloPayService
    {
        Task<ZaloPayCreateOrderResponse> CreateOrder(int paymentId, decimal amount, string description, string userId);
        bool ValidateCallback(Dictionary<string, string> callbackData, string mac);
        Dictionary<string, string> ParseZaloPayCallback(IFormCollection formParams);
    }

    public class ZaloPayService : IZaloPayService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ZaloPayService> _logger;
        private readonly HttpClient _httpClient;

        private int AppId => int.Parse(_configuration["ZaloPay:AppId"] ?? "2553");
        private string Key1 => _configuration["ZaloPay:Key1"] ?? "";
        private string Key2 => _configuration["ZaloPay:Key2"] ?? "";
        private string CreateOrderUrl => _configuration["ZaloPay:CreateOrderUrl"] ?? "https://sb-openapi.zalopay.vn/v2/create";
        private string CallbackUrl => _configuration["ZaloPay:CallbackUrl"] ?? "";

        public ZaloPayService(
            IConfiguration configuration,
            ILogger<ZaloPayService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
        }

        public async Task<ZaloPayCreateOrderResponse> CreateOrder(int paymentId, decimal amount, string description, string userId)
        {
            try
            {
                var appTransId = DateTime.Now.ToString("yyMMdd") + "_" + paymentId;
                var appTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                var embedData = new { redirecturl = _configuration["Frontend:Url"] ?? "http://localhost:10013" };
                var items = new[] { new { itemid = "subscription", itemname = description, itemprice = (long)amount, itemquantity = 1 } };

                var orderData = new Dictionary<string, string>
                {
                    { "app_id", AppId.ToString() },
                    { "app_user", userId },
                    { "app_time", appTime.ToString() },
                    { "app_trans_id", appTransId },
                    { "amount", ((long)amount).ToString() },
                    { "item", JsonConvert.SerializeObject(items) },
                    { "embed_data", JsonConvert.SerializeObject(embedData) },
                    { "description", description },
                    { "bank_code", "" },
                    { "callback_url", CallbackUrl }
                };

                // Generate MAC
                var data = $"{AppId}|{orderData["app_trans_id"]}|{orderData["app_user"]}|{orderData["amount"]}|{orderData["app_time"]}|{orderData["embed_data"]}|{orderData["item"]}";
                var mac = HmacSHA256(data, Key1);
                orderData["mac"] = mac;

                _logger.LogInformation($"Creating ZaloPay order for payment {paymentId}, amount {amount} VND");
                _logger.LogDebug($"Order data: {JsonConvert.SerializeObject(orderData)}");

                // Send request to ZaloPay
                var content = new FormUrlEncodedContent(orderData);
                var response = await _httpClient.PostAsync(CreateOrderUrl, content);
                var responseString = await response.Content.ReadAsStringAsync();

                _logger.LogInformation($"ZaloPay create order response: {responseString}");

                var result = JsonConvert.DeserializeObject<ZaloPayCreateOrderResponse>(responseString);
                
                if (result == null)
                {
                    throw new Exception("Failed to deserialize ZaloPay response");
                }

                // Add app_trans_id to response for tracking
                result.AppTransId = appTransId;

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating ZaloPay order for payment {paymentId}");
                throw;
            }
        }

        public bool ValidateCallback(Dictionary<string, string> callbackData, string receivedMac)
        {
            try
            {
                if (!callbackData.ContainsKey("data"))
                {
                    _logger.LogWarning("ZaloPay callback missing 'data' field");
                    return false;
                }

                var data = callbackData["data"];
                var calculatedMac = HmacSHA256(data, Key2);

                var isValid = calculatedMac.Equals(receivedMac, StringComparison.OrdinalIgnoreCase);

                if (!isValid)
                {
                    _logger.LogWarning($"ZaloPay callback MAC validation failed. Received: {receivedMac}, Calculated: {calculatedMac}");
                }

                return isValid;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error validating ZaloPay callback signature");
                return false;
            }
        }

        public Dictionary<string, string> ParseZaloPayCallback(IFormCollection formParams)
        {
            var result = new Dictionary<string, string>();

            foreach (var param in formParams)
            {
                if (!string.IsNullOrEmpty(param.Value))
                {
                    result[param.Key] = param.Value.ToString();
                }
            }

            return result;
        }

        private string HmacSHA256(string data, string key)
        {
            using (var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key)))
            {
                var hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
                return BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
            }
        }
    }

    // Response models
    public class ZaloPayCreateOrderResponse
    {
        [JsonProperty("return_code")]
        public int ReturnCode { get; set; }

        [JsonProperty("return_message")]
        public string ReturnMessage { get; set; } = string.Empty;

        [JsonProperty("sub_return_code")]
        public int SubReturnCode { get; set; }

        [JsonProperty("sub_return_message")]
        public string SubReturnMessage { get; set; } = string.Empty;

        [JsonProperty("order_url")]
        public string OrderUrl { get; set; } = string.Empty;

        [JsonProperty("zp_trans_token")]
        public string ZpTransToken { get; set; } = string.Empty;

        [JsonProperty("order_token")]
        public string OrderToken { get; set; } = string.Empty;

        [JsonProperty("qr_code")]
        public string QrCode { get; set; } = string.Empty;

        // Additional field for tracking
        [JsonIgnore]
        public string AppTransId { get; set; } = string.Empty;
    }

    public class ZaloPayCallbackData
    {
        [JsonProperty("app_id")]
        public int AppId { get; set; }

        [JsonProperty("app_trans_id")]
        public string AppTransId { get; set; } = string.Empty;

        [JsonProperty("app_time")]
        public long AppTime { get; set; }

        [JsonProperty("app_user")]
        public string AppUser { get; set; } = string.Empty;

        [JsonProperty("amount")]
        public long Amount { get; set; }

        [JsonProperty("embed_data")]
        public string EmbedData { get; set; } = string.Empty;

        [JsonProperty("item")]
        public string Item { get; set; } = string.Empty;

        [JsonProperty("zp_trans_id")]
        public long ZpTransId { get; set; }

        [JsonProperty("server_time")]
        public long ServerTime { get; set; }

        [JsonProperty("channel")]
        public int Channel { get; set; }

        [JsonProperty("merchant_user_id")]
        public string MerchantUserId { get; set; } = string.Empty;

        [JsonProperty("user_fee_amount")]
        public long UserFeeAmount { get; set; }

        [JsonProperty("discount_amount")]
        public long DiscountAmount { get; set; }
    }
}
