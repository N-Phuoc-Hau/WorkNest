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
            // Content-Type should be set per request, not in default headers
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

        // Phân tích CV và tính độ phù hợp với Job Post
        public async Task<CVAnalysisResult> AnalyzeCVForJobAsync(string cvText, Dictionary<string, object> jobDetails)
        {
            try
            {
                var jobJson = JsonSerializer.Serialize(jobDetails);
                var prompt = $@"
                Là một AI chuyên gia phân tích CV và matching công việc, hãy phân tích CV sau và tính độ phù hợp với công việc được cung cấp.
                
                CV Content: {cvText}
                
                Job Details: {jobJson}
                
                Yêu cầu phân tích:
                1. Trích xuất thông tin ứng viên từ CV (skills, experience, education, projects)
                2. So sánh với yêu cầu công việc
                3. Tính điểm phù hợp từ 0-100
                4. Đưa ra lý do tại sao phù hợp/không phù hợp
                5. Gợi ý những điểm cần cải thiện
                
                Trả về JSON format:
                {{
                    ""candidate_info"": {{
                        ""skills"": [""skill1"", ""skill2""],
                        ""experience_years"": 3,
                        ""education"": ""Degree"",
                        ""previous_positions"": [""position1"", ""position2""],
                        ""projects"": [""project1"", ""project2""]
                    }},
                    ""match_score"": 85,
                    ""strengths"": [""strength1"", ""strength2""],
                    ""weaknesses"": [""weakness1"", ""weakness2""],
                    ""improvement_suggestions"": [""suggestion1"", ""suggestion2""],
                    ""detailed_analysis"": ""Chi tiết phân tích..""
                }}
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseCVAnalysisResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error analyzing CV for job");
                return GetDefaultCVAnalysisResult();
            }
        }

        // Gợi ý công việc dựa trên lịch sử search và profile ứng viên
        public async Task<List<JobRecommendation>> GetPersonalizedJobRecommendationsAsync(
            string userId, 
            Dictionary<string, object> userProfile, 
            List<Dictionary<string, object>> searchHistory,
            List<Dictionary<string, object>> applicationHistory)
        {
            try
            {
                var profileJson = JsonSerializer.Serialize(userProfile);
                var searchHistoryJson = JsonSerializer.Serialize(searchHistory);
                var applicationHistoryJson = JsonSerializer.Serialize(applicationHistory);
                
                var prompt = $@"
                Là một AI chuyên gia gợi ý việc làm cá nhân hóa, hãy phân tích profile, lịch sử tìm kiếm và nộp hồ sơ của ứng viên để đưa ra những gợi ý việc làm phù hợp nhất.
                
                User Profile: {profileJson}
                Search History: {searchHistoryJson}
                Application History: {applicationHistoryJson}
                
                Yêu cầu:
                - Phân tích xu hướng quan tâm của ứng viên
                - Đưa ra 10 công việc phù hợp nhất
                - Ưu tiên những công việc tương tự với lịch sử tìm kiếm/ứng tuyển
                - Tính toán match percentage dựa trên profile và history
                
                Trả về JSON format:
                [
                    {{
                        ""title"": ""Job Title"",
                        ""company"": ""Company Name"",
                        ""location"": ""Location"",
                        ""salary_range"": ""$50k-$80k"",
                        ""skills_required"": [""skill1"", ""skill2""],
                        ""match_percentage"": 92,
                        ""reason"": ""Lý do gợi ý công việc này"",
                        ""career_growth"": ""Cơ hội phát triển"",
                        ""job_type"": ""full-time"",
                        ""experience_level"": ""senior""
                    }}
                ]
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParsePersonalizedJobRecommendationsResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting personalized job recommendations");
                var userRole = userProfile.TryGetValue("role", out var role) ? role?.ToString() ?? "candidate" : "candidate";
                return GetDefaultJobRecommendations(userRole);
            }
        }

        // Phân tích profile ứng viên để tìm ứng viên phù hợp cho job
        public async Task<List<CandidateMatchResult>> GetCandidateMatchesForJobAsync(
            Dictionary<string, object> jobDetails,
            List<Dictionary<string, object>> candidateProfiles)
        {
            try
            {
                var jobJson = JsonSerializer.Serialize(jobDetails);
                var candidatesJson = JsonSerializer.Serialize(candidateProfiles);
                
                var prompt = $@"
                Là một AI chuyên gia matching ứng viên, hãy phân tích danh sách ứng viên và tính độ phù hợp với công việc.
                
                Job Details: {jobJson}
                Candidate Profiles: {candidatesJson}
                
                Yêu cầu:
                - Phân tích từng ứng viên
                - Tính điểm match từ 0-100
                - Sắp xếp theo độ phù hợp giảm dần
                - Đưa ra lý do tại sao phù hợp
                - Highlight những điểm mạnh của ứng viên
                
                Trả về JSON format:
                [
                    {{
                        ""candidate_id"": ""user_id"",
                        ""candidate_name"": ""Name"",
                        ""match_score"": 95,
                        ""key_strengths"": [""strength1"", ""strength2""],
                        ""relevant_experience"": ""Kinh nghiệm liên quan"",
                        ""match_reasons"": [""reason1"", ""reason2""],
                        ""potential_concerns"": [""concern1""],
                        ""recommendation_level"": ""highly_recommended""
                    }}
                ]
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseCandidateMatchResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting candidate matches for job");
                return GetDefaultCandidateMatches();
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

        private CVAnalysisResult ParseCVAnalysisResponse(string response)
        {
            try
            {
                if (response.Contains('{') && response.Contains('}'))
                {
                    var startIndex = response.IndexOf('{');
                    var endIndex = response.LastIndexOf('}') + 1;
                    var jsonObject = response.Substring(startIndex, endIndex - startIndex);
                    
                    var jsonDoc = JsonDocument.Parse(jsonObject);
                    var root = jsonDoc.RootElement;

                    var result = new CVAnalysisResult
                    {
                        MatchScore = root.TryGetProperty("match_score", out var scoreElement) ? scoreElement.GetInt32() : 0,
                        DetailedAnalysis = root.TryGetProperty("detailed_analysis", out var analysisElement) ? analysisElement.GetString() ?? "" : "",
                        Strengths = root.TryGetProperty("strengths", out var strengthsElement) ? 
                            strengthsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new List<string>(),
                        Weaknesses = root.TryGetProperty("weaknesses", out var weaknessesElement) ?
                            weaknessesElement.EnumerateArray().Select(w => w.GetString() ?? "").ToList() : new List<string>(),
                        ImprovementSuggestions = root.TryGetProperty("improvement_suggestions", out var suggestionsElement) ?
                            suggestionsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new List<string>()
                    };

                    // Parse candidate info
                    if (root.TryGetProperty("candidate_info", out var candidateElement))
                    {
                        result.CandidateInfo = new CandidateInfo
                        {
                            ExperienceYears = candidateElement.TryGetProperty("experience_years", out var expElement) ? expElement.GetInt32() : 0,
                            Education = candidateElement.TryGetProperty("education", out var eduElement) ? eduElement.GetString() ?? "" : "",
                            Skills = candidateElement.TryGetProperty("skills", out var skillsElement) ?
                                skillsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new List<string>(),
                            PreviousPositions = candidateElement.TryGetProperty("previous_positions", out var positionsElement) ?
                                positionsElement.EnumerateArray().Select(p => p.GetString() ?? "").ToList() : new List<string>(),
                            Projects = candidateElement.TryGetProperty("projects", out var projectsElement) ?
                                projectsElement.EnumerateArray().Select(p => p.GetString() ?? "").ToList() : new List<string>()
                        };
                    }

                    return result;
                }

                return GetDefaultCVAnalysisResult();
            }
            catch
            {
                return GetDefaultCVAnalysisResult();
            }
        }

        private CVAnalysisResult GetDefaultCVAnalysisResult()
        {
            return new CVAnalysisResult
            {
                MatchScore = 50,
                DetailedAnalysis = "Không thể phân tích CV tự động. Vui lòng xem xét thủ công.",
                Strengths = new List<string> { "Cần đánh giá thủ công" },
                Weaknesses = new List<string> { "Cần đánh giá thủ công" },
                ImprovementSuggestions = new List<string> { "Vui lòng liên hệ để được tư vấn" },
                CandidateInfo = new CandidateInfo
                {
                    Skills = new List<string>(),
                    ExperienceYears = 0,
                    Education = "Chưa rõ",
                    PreviousPositions = new List<string>(),
                    Projects = new List<string>()
                }
            };
        }

        private List<JobRecommendation> ParsePersonalizedJobRecommendationsResponse(string response)
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

        private List<CandidateMatchResult> ParseCandidateMatchResponse(string response)
        {
            try
            {
                if (response.Contains('[') && response.Contains(']'))
                {
                    var startIndex = response.IndexOf('[');
                    var endIndex = response.LastIndexOf(']') + 1;
                    var jsonArray = response.Substring(startIndex, endIndex - startIndex);
                    
                    return JsonSerializer.Deserialize<List<CandidateMatchResult>>(jsonArray) ?? new List<CandidateMatchResult>();
                }
                
                return new List<CandidateMatchResult>();
            }
            catch
            {
                return new List<CandidateMatchResult>();
            }
        }

        private List<CandidateMatchResult> GetDefaultCandidateMatches()
        {
            return new List<CandidateMatchResult>
            {
                new CandidateMatchResult
                {
                    CandidateId = "sample-id",
                    CandidateName = "Sample Candidate",
                    MatchScore = 75,
                    KeyStrengths = new List<string> { "Kinh nghiệm tốt", "Kỹ năng phù hợp" },
                    RelevantExperience = "3 năm kinh nghiệm trong lĩnh vực tương tự",
                    MatchReasons = new List<string> { "Đáp ứng yêu cầu kỹ năng", "Kinh nghiệm phù hợp" },
                    PotentialConcerns = new List<string>(),
                    RecommendationLevel = "recommended"
                }
            };
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
        public string Reason { get; set; } = string.Empty;
        public string CareerGrowth { get; set; } = string.Empty;
        public string JobType { get; set; } = string.Empty;
        public string ExperienceLevel { get; set; } = string.Empty;
    }

    public class CandidateRecommendation
    {
        public string Name { get; set; } = string.Empty;
        public int ExperienceYears { get; set; }
        public List<string> Skills { get; set; } = new List<string>();
        public int MatchPercentage { get; set; }
        public string CurrentPosition { get; set; } = string.Empty;
    }

    public class CVAnalysisResult
    {
        public CandidateInfo CandidateInfo { get; set; } = new CandidateInfo();
        public int MatchScore { get; set; }
        public List<string> Strengths { get; set; } = new List<string>();
        public List<string> Weaknesses { get; set; } = new List<string>();
        public List<string> ImprovementSuggestions { get; set; } = new List<string>();
        public string DetailedAnalysis { get; set; } = string.Empty;
    }

    public class CandidateInfo
    {
        public List<string> Skills { get; set; } = new List<string>();
        public int ExperienceYears { get; set; }
        public string Education { get; set; } = string.Empty;
        public List<string> PreviousPositions { get; set; } = new List<string>();
        public List<string> Projects { get; set; } = new List<string>();
    }

    public class CandidateMatchResult
    {
        public string CandidateId { get; set; } = string.Empty;
        public string CandidateName { get; set; } = string.Empty;
        public int MatchScore { get; set; }
        public List<string> KeyStrengths { get; set; } = new List<string>();
        public string RelevantExperience { get; set; } = string.Empty;
        public List<string> MatchReasons { get; set; } = new List<string>();
        public List<string> PotentialConcerns { get; set; } = new List<string>();
        public string RecommendationLevel { get; set; } = string.Empty;
    }
} 