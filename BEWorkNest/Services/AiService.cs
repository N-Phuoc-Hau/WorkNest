using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace BEWorkNest.Services
{
    public class AiService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AiService> _logger;
        private readonly string _apiKey;
        private readonly string _baseUrl = "https://api.deepseek.com/v1/chat/completions";

        public AiService(HttpClient httpClient, IConfiguration configuration, ILogger<AiService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            _apiKey = "sk-b9713a7d83b546818bbd480aeb227285";
            
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
            _httpClient.DefaultRequestHeaders.Add("Content-Type", "application/json");
        }

        public async Task<List<string>> GetSearchSuggestionsAsync(string query, string userRole)
        {
            try
            {
                var prompt = $@"
                Là một AI assistant chuyên về tìm kiếm việc làm, hãy đưa ra 5 gợi ý tìm kiếm dựa trên từ khóa: '{query}'
                
                Người dùng là: {userRole}
                
                Yêu cầu:
                - Trả về chính xác 5 gợi ý
                - Mỗi gợi ý phải liên quan đến việc làm
                - Phù hợp với vai trò {userRole}
                - Trả về dạng JSON array: ['suggestion1', 'suggestion2', ...]
                
                Ví dụ cho candidate: ['Frontend Developer', 'React Native Developer', 'Flutter Developer', 'UI/UX Designer', 'Mobile App Developer']
                Ví dụ cho recruiter: ['Senior Developer', 'Full Stack Engineer', 'Project Manager', 'DevOps Engineer', 'Product Manager']
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseSuggestionsResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search suggestions");
                return GetDefaultSuggestions(userRole);
            }
        }

        public async Task<List<JobRecommendation>> GetJobRecommendationsAsync(string userId, string userRole, Dictionary<string, object> userProfile)
        {
            try
            {
                var profileJson = JsonSerializer.Serialize(userProfile);
                var prompt = $@"
                Là một AI assistant chuyên về gợi ý việc làm, hãy phân tích profile người dùng và đưa ra 5 công việc phù hợp nhất.
                
                Profile người dùng: {profileJson}
                Vai trò: {userRole}
                
                Yêu cầu:
                - Trả về chính xác 5 công việc phù hợp nhất
                - Mỗi công việc cần có: title, company, location, salary_range, skills_required
                - Trả về dạng JSON array với format:
                [
                    {{
                        ""title"": ""Job Title"",
                        ""company"": ""Company Name"",
                        ""location"": ""Location"",
                        ""salary_range"": ""$50k-$80k"",
                        ""skills_required"": [""skill1"", ""skill2""],
                        ""match_percentage"": 85
                    }}
                ]
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseJobRecommendationsResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting job recommendations");
                return GetDefaultJobRecommendations(userRole);
            }
        }

        public async Task<List<CandidateRecommendation>> GetCandidateRecommendationsAsync(string jobId, Dictionary<string, object> jobDetails)
        {
            try
            {
                var jobJson = JsonSerializer.Serialize(jobDetails);
                var prompt = $@"
                Là một AI assistant chuyên về gợi ý ứng viên, hãy phân tích yêu cầu công việc và đưa ra 5 ứng viên phù hợp nhất.
                
                Chi tiết công việc: {jobJson}
                
                Yêu cầu:
                - Trả về chính xác 5 ứng viên phù hợp nhất
                - Mỗi ứng viên cần có: name, experience_years, skills, match_percentage
                - Trả về dạng JSON array với format:
                [
                    {{
                        ""name"": ""Candidate Name"",
                        ""experience_years"": 3,
                        ""skills"": [""skill1"", ""skill2""],
                        ""match_percentage"": 90,
                        ""current_position"": ""Current Job Title""
                    }}
                ]
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseCandidateRecommendationsResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate recommendations");
                return GetDefaultCandidateRecommendations();
            }
        }

        public async Task<List<string>> GetSearchFiltersAsync(string query, string userRole)
        {
            try
            {
                var prompt = $@"
                Là một AI assistant chuyên về tìm kiếm việc làm, hãy đưa ra các filter phù hợp cho từ khóa: '{query}'
                
                Người dùng là: {userRole}
                
                Yêu cầu:
                - Trả về các filter phù hợp: location, experience_level, salary_range, job_type
                - Trả về dạng JSON object:
                {{
                    ""locations"": [""location1"", ""location2""],
                    ""experience_levels"": [""Junior"", ""Mid-level"", ""Senior""],
                    ""salary_ranges"": [""$30k-$50k"", ""$50k-$80k"", ""$80k+"", ""Remote""],
                    ""job_types"": [""Full-time"", ""Part-time"", ""Contract"", ""Internship""]
                }}
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseSearchFiltersResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting search filters");
                return GetDefaultSearchFilters();
            }
        }

        private async Task<string> CallDeepSeekApiAsync(string prompt)
        {
            var requestBody = new
            {
                model = "deepseek-chat",
                messages = new[]
                {
                    new { role = "user", content = prompt }
                },
                max_tokens = 1000,
                temperature = 0.7
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync(_baseUrl, content);
            response.EnsureSuccessStatusCode();

            var responseContent = await response.Content.ReadAsStringAsync();
            var responseObj = JsonSerializer.Deserialize<JsonElement>(responseContent);

            return responseObj.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "";
        }

        private List<string> ParseSuggestionsResponse(string response)
        {
            try
            {
                // Try to parse as JSON array
                if (response.Contains('[') && response.Contains(']'))
                {
                    var startIndex = response.IndexOf('[');
                    var endIndex = response.LastIndexOf(']') + 1;
                    var jsonArray = response.Substring(startIndex, endIndex - startIndex);
                    
                    return JsonSerializer.Deserialize<List<string>>(jsonArray) ?? new List<string>();
                }
                
                // Fallback: split by lines and clean up
                return response.Split('\n')
                    .Where(line => !string.IsNullOrWhiteSpace(line))
                    .Select(line => line.Trim().TrimStart('-', '•', '1', '2', '3', '4', '5', '.'))
                    .Where(line => !string.IsNullOrWhiteSpace(line))
                    .Take(5)
                    .ToList();
            }
            catch
            {
                return new List<string>();
            }
        }

        private List<JobRecommendation> ParseJobRecommendationsResponse(string response)
        {
            try
            {
                if (response.Contains('[') && response.Contains(']'))
                {
                    var startIndex = response.IndexOf('[');
                    var endIndex = response.LastIndexOf(']') + 1;
                    var jsonArray = response.Substring(startIndex, endIndex - startIndex);
                    
                    return JsonSerializer.Deserialize<List<JobRecommendation>>(jsonArray) ?? new List<JobRecommendation>();
                }
                
                return new List<JobRecommendation>();
            }
            catch
            {
                return new List<JobRecommendation>();
            }
        }

        private List<CandidateRecommendation> ParseCandidateRecommendationsResponse(string response)
        {
            try
            {
                if (response.Contains('[') && response.Contains(']'))
                {
                    var startIndex = response.IndexOf('[');
                    var endIndex = response.LastIndexOf(']') + 1;
                    var jsonArray = response.Substring(startIndex, endIndex - startIndex);
                    
                    return JsonSerializer.Deserialize<List<CandidateRecommendation>>(jsonArray) ?? new List<CandidateRecommendation>();
                }
                
                return new List<CandidateRecommendation>();
            }
            catch
            {
                return new List<CandidateRecommendation>();
            }
        }

        private List<string> ParseSearchFiltersResponse(string response)
        {
            try
            {
                if (response.Contains('{') && response.Contains('}'))
                {
                    var startIndex = response.IndexOf('{');
                    var endIndex = response.LastIndexOf('}') + 1;
                    var jsonObject = response.Substring(startIndex, endIndex - startIndex);
                    
                    var filters = JsonSerializer.Deserialize<Dictionary<string, List<string>>>(jsonObject);
                    var allFilters = new List<string>();
                    
                    if (filters != null)
                    {
                        foreach (var filter in filters.Values)
                        {
                            allFilters.AddRange(filter);
                        }
                    }
                    
                    return allFilters;
                }
                
                return new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        private List<string> GetDefaultSuggestions(string userRole)
        {
            return userRole == "candidate" 
                ? new List<string> { "Frontend Developer", "React Native Developer", "Flutter Developer", "UI/UX Designer", "Mobile App Developer" }
                : new List<string> { "Senior Developer", "Full Stack Engineer", "Project Manager", "DevOps Engineer", "Product Manager" };
        }

        private List<JobRecommendation> GetDefaultJobRecommendations(string userRole)
        {
            return new List<JobRecommendation>
            {
                new JobRecommendation
                {
                    Title = "Senior Frontend Developer",
                    Company = "Tech Company",
                    Location = "Ho Chi Minh City",
                    SalaryRange = "$50k-$80k",
                    SkillsRequired = new List<string> { "React", "TypeScript", "Next.js" },
                    MatchPercentage = 85
                },
                new JobRecommendation
                {
                    Title = "Mobile App Developer",
                    Company = "Startup",
                    Location = "Hanoi",
                    SalaryRange = "$40k-$70k",
                    SkillsRequired = new List<string> { "Flutter", "Dart", "Firebase" },
                    MatchPercentage = 80
                }
            };
        }

        private List<CandidateRecommendation> GetDefaultCandidateRecommendations()
        {
            return new List<CandidateRecommendation>
            {
                new CandidateRecommendation
                {
                    Name = "Nguyen Van A",
                    ExperienceYears = 3,
                    Skills = new List<string> { "React", "TypeScript", "Node.js" },
                    MatchPercentage = 90,
                    CurrentPosition = "Frontend Developer"
                },
                new CandidateRecommendation
                {
                    Name = "Tran Thi B",
                    ExperienceYears = 5,
                    Skills = new List<string> { "Flutter", "Dart", "Firebase" },
                    MatchPercentage = 85,
                    CurrentPosition = "Mobile Developer"
                }
            };
        }

        private List<string> GetDefaultSearchFilters()
        {
            return new List<string> { "Ho Chi Minh City", "Hanoi", "Da Nang", "Remote", "Full-time", "Part-time", "Junior", "Senior" };
        }
    }

    public class JobRecommendation
    {
        public string Title { get; set; } = string.Empty;
        public string Company { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string SalaryRange { get; set; } = string.Empty;
        public List<string> SkillsRequired { get; set; } = new List<string>();
        public int MatchPercentage { get; set; }
    }

    public class CandidateRecommendation
    {
        public string Name { get; set; } = string.Empty;
        public int ExperienceYears { get; set; }
        public List<string> Skills { get; set; } = new List<string>();
        public int MatchPercentage { get; set; }
        public string CurrentPosition { get; set; } = string.Empty;
    }
} 