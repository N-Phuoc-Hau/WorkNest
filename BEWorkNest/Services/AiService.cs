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
        private readonly string _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

        private readonly List<string> _jobDomains = new List<string>
        {
            "Software Development", "Web Development", "Mobile Development", "DevOps", "Data Science",
            "Digital Marketing", "Content Marketing", "SEO/SEM", "Social Media Marketing",
            "Sales", "Business Development", "Account Management", "Customer Success",
            "HR", "Recruitment", "Training & Development", "Compensation & Benefits",
            "Finance", "Accounting", "Financial Analysis", "Risk Management",
            "Operations", "Project Management", "Quality Assurance", "Supply Chain",
            "Design", "UI/UX Design", "Graphic Design", "Product Design",
            "Engineering", "Mechanical Engineering", "Civil Engineering", "Electrical Engineering"
        };

        private readonly Dictionary<string, List<string>> _skillDatabase = new Dictionary<string, List<string>>
        {
            ["Software Development"] = new List<string> { "Java", "C#", ".NET", "Python", "JavaScript", "TypeScript", "React", "Angular", "Vue.js", "Node.js", "Spring Boot", "ASP.NET" },
            ["Mobile Development"] = new List<string> { "Flutter", "Dart", "React Native", "Swift", "Kotlin", "Java", "Xamarin", "Firebase", "iOS", "Android" },
            ["Digital Marketing"] = new List<string> { "SEO", "SEM", "Google Ads", "Facebook Ads", "Google Analytics", "Content Marketing", "Email Marketing", "Social Media", "PPC" },
            ["Data Science"] = new List<string> { "Python", "R", "SQL", "Machine Learning", "Deep Learning", "TensorFlow", "PyTorch", "Pandas", "NumPy", "Jupyter" },
            ["DevOps"] = new List<string> { "Docker", "Kubernetes", "AWS", "Azure", "Jenkins", "CI/CD", "Terraform", "Ansible", "Linux", "Bash" },
            ["UI/UX Design"] = new List<string> { "Figma", "Adobe XD", "Sketch", "Photoshop", "Illustrator", "InVision", "Principle", "User Research", "Wireframing", "Prototyping" }
        };

        public AiService(HttpClient httpClient, IConfiguration configuration, ILogger<AiService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            
            // Read API key from file
            var apiKeyPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "apikeyDeepSeek.txt");
            if (File.Exists(apiKeyPath))
            {
                var fileContent = File.ReadAllText(apiKeyPath).Trim();
                // Extract just the API key (first line, before any spaces)
                _apiKey = fileContent.Split('\n')[0].Split(' ')[0].Trim();
                _logger.LogInformation($"Loaded Gemini API key from file: {apiKeyPath}");
            }
            else
            {
                _apiKey = "AIzaSyD6JGsQZBtoj0uI2lvvNcqtXc5WTE7p9ow"; // Fallback Gemini key
                _logger.LogWarning($"API key file not found at {apiKeyPath}, using fallback Gemini key");
            }
            
            // Gemini uses X-goog-api-key header, not Authorization
            _httpClient.DefaultRequestHeaders.Add("X-goog-api-key", _apiKey);
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
                _logger.LogInformation($"[CV Analysis] Input cvText length: {cvText?.Length ?? 0}");
                _logger.LogInformation($"[CV Analysis] CV Content preview: {(string.IsNullOrEmpty(cvText) ? "EMPTY/NULL" : cvText.Substring(0, Math.Min(200, cvText.Length)))}...");
                
                var jobJson = JsonSerializer.Serialize(jobDetails);
                _logger.LogInformation($"[CV Analysis] Job details: {jobJson}");
                
                var prompt = $@"
                Bạn là AI CHUYÊN GIA đánh giá CV với tiêu chuẩn CỰC KỲ KHẮT KHE như các HR chuyên nghiệp.

                ⚠️ CẢNH BÁO: Hãy THẬT SỰ KHẮT KHE - Đừng tử tế quá!

                QUY TẮC BẮT BUỘC:
                🔴 CHUYÊN NGÀNH KHÁC NHAU = ĐIỂM CỰC THẤP (0-20 điểm)
                - Mobile Developer ứng tuyển Marketing = 5-15 điểm
                - Developer ứng tuyển Sales/HR = 5-15 điểm  
                - Technical ứng tuyển Non-technical = 5-20 điểm

                🔴 THIẾU KINH NGHIỆM = TRỪ ĐIỂM NẶNG
                - Fresher ứng tuyển Senior = 10-25 điểm
                - Thiếu 1-2 năm exp = trừ 25-40 điểm

                🔴 THIẾU KỸ NĂNG CHÍNH = TRỪ ĐIỂM MẠNH  
                - Thiếu 50%+ skill yêu cầu = trừ 30-50 điểm
                - Không có skill chính = 0-20 điểm

                🔴 CHỈ CHO ĐIỂM CAO KHI:
                - Đúng chuyên ngành 100%
                - Đủ kinh nghiệm yêu cầu
                - Có 80%+ kỹ năng cần thiết
                - 70+ điểm chỉ dành cho CV THẬT SỰ phù hợp

                CV CONTENT: {(string.IsNullOrEmpty(cvText) ? "RỖNG/LỖI - KHÔNG CÓ NỘI DUNG CV" : cvText)}
                JOB REQUIREMENTS: {jobJson}

                PHẢI TRẢ VỀ JSON - KHÔNG TEXT:
                {{
                    ""field_compatibility"": {{
                        ""cv_field"": ""Unknown"",
                        ""job_field"": ""Social Media Marketing"",  
                        ""compatibility_score"": 0,
                        ""field_change_penalty"": 70,
                        ""analysis"": ""CV rỗng/lỗi extraction""
                    }},
                    ""experience_analysis"": {{
                        ""cv_experience_years"": 0,
                        ""cv_relevant_experience"": 0,
                        ""job_required_years"": 2,
                        ""experience_gap_severity"": ""Critical"",
                        ""experience_penalty"": 50
                    }},
                    ""skills_analysis"": {{
                        ""cv_skills"": [],
                        ""job_required_skills"": [""Social Media"", ""Content Creation""],
                        ""matched_skills"": [],
                        ""critical_missing_skills"": [""All skills missing""],
                        ""skills_match_rate"": 0,
                        ""skills_penalty"": 50
                    }},
                    ""final_assessment"": {{
                        ""base_score"": 100,
                        ""field_penalty"": 70,
                        ""experience_penalty"": 50,
                        ""skills_penalty"": 50,
                        ""final_score"": 0,
                        ""score_reasoning"": ""CV rỗng - không thể đánh giá"",
                        ""recommendation"": ""REJECT"",
                        ""major_red_flags"": [""CV không có nội dung""],
                        ""minor_concerns"": [],
                        ""positive_points"": []
                    }},
                    ""hr_summary"": ""CV lỗi/rỗng - yêu cầu nộp lại""
                }}
                ";

                _logger.LogInformation($"[CV Analysis] Sending prompt to AI with cvText length: {cvText?.Length ?? 0}");
                var response = await CallDeepSeekApiAsync(prompt);
                _logger.LogInformation($"[CV Analysis] AI Response received: {response?.Substring(0, Math.Min(300, response?.Length ?? 0))}...");
                
                var result = ParseStrictCVAnalysisResponse(response ?? "");
                _logger.LogInformation($"[CV Analysis] Parsed result - MatchScore: {result.MatchScore}, Analysis: {result.DetailedAnalysis?.Substring(0, Math.Min(100, result.DetailedAnalysis?.Length ?? 0))}...");
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[CV Analysis] Error analyzing CV for job - cvText length: {CvTextLength}", cvText?.Length ?? 0);
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
            // Gemini API format
            var requestBody = new
            {
                contents = new[]
                {
                    new
                    {
                        parts = new[]
                        {
                            new { text = prompt }
                        }
                    }
                },
                generationConfig = new
                {
                    temperature = 0.7,
                    maxOutputTokens = 1000
                }
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _logger.LogInformation($"Sending request to Gemini API: {_baseUrl}");
            var response = await _httpClient.PostAsync(_baseUrl, content);
            
            var responseContent = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"Gemini API response status: {response.StatusCode}");
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"Gemini API error: {responseContent}");
                throw new HttpRequestException($"Gemini API error: {response.StatusCode} - {responseContent}");
            }

            var responseObj = JsonSerializer.Deserialize<JsonElement>(responseContent);
            
            // Gemini response format: candidates[0].content.parts[0].text
            if (responseObj.TryGetProperty("candidates", out var candidates) && 
                candidates.GetArrayLength() > 0)
            {
                var firstCandidate = candidates[0];
                if (firstCandidate.TryGetProperty("content", out var content_prop) &&
                    content_prop.TryGetProperty("parts", out var parts) &&
                    parts.GetArrayLength() > 0)
                {
                    var firstPart = parts[0];
                    if (firstPart.TryGetProperty("text", out var textElement))
                    {
                        return textElement.GetString() ?? "";
                    }
                }
            }

            _logger.LogWarning("Could not extract text from Gemini response");
            return "";
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

        private CVAnalysisResult ParseStrictCVAnalysisResponse(string response)
        {
            try
            {
                _logger.LogInformation($"[Parse CV Analysis] Response length: {response?.Length ?? 0}");
                _logger.LogInformation($"[Parse CV Analysis] Response content: {response}");
                
                if (!string.IsNullOrEmpty(response) && response.Contains('{') && response.Contains('}'))
                {
                    var startIndex = response.IndexOf('{');
                    var endIndex = response.LastIndexOf('}') + 1;
                    var jsonObject = response.Substring(startIndex, endIndex - startIndex);
                    
                    _logger.LogInformation($"[Parse CV Analysis] Extracted JSON: {jsonObject}");
                    
                    var jsonDoc = JsonDocument.Parse(jsonObject);
                    var root = jsonDoc.RootElement;

                    var result = new CVAnalysisResult();

                    // Parse final assessment with new structure
                    if (root.TryGetProperty("final_assessment", out var finalElement))
                    {
                        // Handle negative scores and clamp to 0-100 range
                        var rawScore = finalElement.TryGetProperty("final_score", out var scoreElement) ? scoreElement.GetInt32() : 10;
                        result.MatchScore = Math.Max(0, Math.Min(100, rawScore)); // Clamp between 0-100
                        
                        _logger.LogInformation("[Parse CV Analysis] Raw score: {RawScore}, Clamped score: {ClampedScore}", rawScore, result.MatchScore);
                        
                        // Build detailed reasoning from the penalty system
                        var reasoning = "";
                        if (finalElement.TryGetProperty("score_reasoning", out var reasoningElement))
                        {
                            reasoning = reasoningElement.GetString() ?? "";
                        }
                        
                        // Add penalty breakdown
                        JsonElement fieldPenalty = default;
                        JsonElement expPenalty = default;
                        JsonElement skillsPenalty = default;
                        
                        bool hasFieldPenalty = finalElement.TryGetProperty("field_penalty", out fieldPenalty);
                        bool hasExpPenalty = finalElement.TryGetProperty("experience_penalty", out expPenalty);
                        bool hasSkillsPenalty = finalElement.TryGetProperty("skills_penalty", out skillsPenalty);
                        
                        if (hasFieldPenalty || hasExpPenalty || hasSkillsPenalty)
                        {
                            reasoning += $"\n\nPenalty Breakdown:";
                            if (hasFieldPenalty && fieldPenalty.GetInt32() > 0) 
                                reasoning += $"\n- Field mismatch: -{fieldPenalty.GetInt32()} points";
                            if (hasExpPenalty && expPenalty.GetInt32() > 0) 
                                reasoning += $"\n- Experience gap: -{expPenalty.GetInt32()} points";
                            if (hasSkillsPenalty && skillsPenalty.GetInt32() > 0) 
                                reasoning += $"\n- Skills gap: -{skillsPenalty.GetInt32()} points";
                        }
                        
                        result.DetailedAnalysis = reasoning;
                        
                        // Parse positive points as strengths
                        result.Strengths = finalElement.TryGetProperty("positive_points", out var strengthsElement) ? 
                            strengthsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : 
                            new List<string> { "Minimal strengths identified" };
                        
                        // Combine red flags and concerns as weaknesses
                        var weaknesses = new List<string>();
                        if (finalElement.TryGetProperty("major_red_flags", out var redFlagsElement))
                        {
                            weaknesses.AddRange(redFlagsElement.EnumerateArray().Select(s => "🔴 " + (s.GetString() ?? "")));
                        }
                        if (finalElement.TryGetProperty("minor_concerns", out var concernsElement))
                        {
                            weaknesses.AddRange(concernsElement.EnumerateArray().Select(s => "⚠️ " + (s.GetString() ?? "")));
                        }
                        result.Weaknesses = weaknesses.Any() ? weaknesses : new List<string> { "Multiple compatibility issues" };
                    }

                    // Parse skills for candidate info
                    if (root.TryGetProperty("skills_analysis", out var skillsElement))
                    {
                        var cvSkills = skillsElement.TryGetProperty("cv_skills", out var cvSkillsElement) ?
                            cvSkillsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList() : new List<string>();
                        
                        result.CandidateInfo = new CandidateInfo
                        {
                            Skills = cvSkills
                        };

                        // Add skills-based improvement suggestions
                        if (skillsElement.TryGetProperty("critical_missing_skills", out var missingSkillsElement))
                        {
                            var missingSkills = missingSkillsElement.EnumerateArray().Select(s => s.GetString() ?? "").ToList();
                            result.ImprovementSuggestions = missingSkills.Select(skill => $"Acquire {skill} skill").ToList();
                            
                            // Add at least 3 suggestions
                            if (result.ImprovementSuggestions.Count < 3)
                            {
                                result.ImprovementSuggestions.AddRange(new List<string>
                                {
                                    "Gain relevant industry experience",
                                    "Consider role-specific training or certification",
                                    "Build portfolio demonstrating required skills"
                                });
                            }
                        }
                    }

                    // Parse experience
                    if (root.TryGetProperty("experience_analysis", out var expElement))
                    {
                        if (result.CandidateInfo == null) result.CandidateInfo = new CandidateInfo();
                        
                        // Handle both int and double values for experience years
                        if (expElement.TryGetProperty("cv_experience_years", out var yearsElement))
                        {
                            if (yearsElement.ValueKind == JsonValueKind.Number)
                            {
                                // Try double first, then convert to int
                                if (yearsElement.TryGetDouble(out var doubleYears))
                                {
                                    result.CandidateInfo.ExperienceYears = (int)Math.Round(doubleYears);
                                }
                                else if (yearsElement.TryGetInt32(out var intYears))
                                {
                                    result.CandidateInfo.ExperienceYears = intYears;
                                }
                                else
                                {
                                    result.CandidateInfo.ExperienceYears = 0;
                                }
                            }
                            else
                            {
                                result.CandidateInfo.ExperienceYears = 0;
                            }
                        }
                        else
                        {
                            result.CandidateInfo.ExperienceYears = 0;
                        }
                    }

                    // Add HR summary to detailed analysis if available
                    if (root.TryGetProperty("hr_summary", out var hrSummaryElement))
                    {
                        var hrSummary = hrSummaryElement.GetString() ?? "";
                        if (!string.IsNullOrEmpty(hrSummary))
                        {
                            result.DetailedAnalysis = $"HR Assessment: {hrSummary}\n\n{result.DetailedAnalysis}";
                        }
                    }

                    // Ensure we have default values
                    if (result.ImprovementSuggestions == null || !result.ImprovementSuggestions.Any())
                    {
                        result.ImprovementSuggestions = new List<string>
                        {
                            "Develop skills relevant to target role",
                            "Gain experience in the required field",
                            "Consider transitional roles to bridge the gap"
                        };
                    }

                    return result;
                }

                _logger.LogWarning($"[Parse CV Analysis] No valid JSON found in response, returning default result");
                return GetStrictDefaultCVAnalysisResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Parse CV Analysis] Error parsing strict CV analysis response");
                return GetStrictDefaultCVAnalysisResult();
            }
        }

        private CVAnalysisResult GetStrictDefaultCVAnalysisResult()
        {
            return new CVAnalysisResult
            {
                MatchScore = 25, // Điểm thấp để phản ánh việc không thể phân tích được
                DetailedAnalysis = "Không thể phân tích CV tự động do lỗi kỹ thuật. Đề xuất xem xét thủ công với tiêu chí khắt khe.",
                Strengths = new List<string> { "Cần đánh giá chi tiết bằng tay" },
                Weaknesses = new List<string> { "Không thể xác định kỹ năng từ CV", "Cần review thủ công" },
                ImprovementSuggestions = new List<string> { 
                    "Cập nhật CV với format rõ ràng hơn", 
                    "Liệt kê kỹ năng cụ thể",
                    "Mô tả kinh nghiệm chi tiết"
                },
                CandidateInfo = new CandidateInfo
                {
                    Skills = new List<string>(),
                    ExperienceYears = 0,
                    Education = "Chưa xác định",
                    PreviousPositions = new List<string>(),
                    Projects = new List<string>()
                }
            };
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

        public async Task<List<string>> GetEnhancedSearchSuggestionsAsync(string query, string userRole, List<string>? userSkills = null)
        {
            try
            {
                // RAG: Tìm domain phù hợp từ database
                var relevantDomains = _jobDomains
                    .Where(d => d.ToLower().Contains(query.ToLower()) || 
                               query.ToLower().Contains(d.ToLower()))
                    .ToList();

                // RAG: Tìm skills liên quan
                var relevantSkills = new List<string>();
                foreach (var domain in relevantDomains)
                {
                    if (_skillDatabase.ContainsKey(domain))
                    {
                        relevantSkills.AddRange(_skillDatabase[domain]);
                    }
                }

                var ragContext = $@"
                DOMAIN CONTEXT: {string.Join(", ", relevantDomains)}
                RELATED SKILLS: {string.Join(", ", relevantSkills.Take(10))}
                USER SKILLS: {string.Join(", ", userSkills ?? new List<string>())}
                ";

                var prompt = $@"
                Dựa trên RAG context và từ khóa tìm kiếm, đưa ra 5 gợi ý tìm kiếm CHÍNH XÁC và THỰC TẾ.

                {ragContext}
                
                Query: '{query}'
                User Role: {userRole}
                
                YÊU CẦU:
                - Ưu tiên các gợi ý trong cùng domain với query
                - Xem xét skills của user để gợi ý phù hợp
                - Không gợi ý những vị trí quá cao so với level của user
                - Trả về đúng 5 gợi ý realistic
                
                Format: [""suggestion1"", ""suggestion2"", ""suggestion3"", ""suggestion4"", ""suggestion5""]
                ";

                var response = await CallDeepSeekApiAsync(prompt);
                return ParseSuggestionsResponse(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting enhanced search suggestions");
                return GetContextualDefaultSuggestions(query, userRole);
            }
        }

        private List<string> GetContextualDefaultSuggestions(string query, string userRole)
        {
            var queryLower = query.ToLower();
            
            if (queryLower.Contains("flutter") || queryLower.Contains("mobile"))
            {
                return userRole == "candidate" 
                    ? new List<string> { "Flutter Developer", "Mobile App Developer", "Cross-platform Developer", "Android Developer", "iOS Developer" }
                    : new List<string> { "Junior Flutter Developer", "Mid-level Mobile Developer", "Senior Flutter Engineer", "Lead Mobile Developer", "Mobile Team Lead" };
            }
            
            if (queryLower.Contains("marketing"))
            {
                return userRole == "candidate"
                    ? new List<string> { "Digital Marketing Specialist", "Content Marketing", "SEO Specialist", "Social Media Manager", "Marketing Coordinator" }
                    : new List<string> { "Marketing Executive", "Senior Marketing Manager", "Marketing Director", "Growth Marketing", "Performance Marketing" };
            }
            
            // Default fallback
            return userRole == "candidate" 
                ? new List<string> { "Junior Developer", "Marketing Assistant", "Sales Executive", "Customer Support", "Data Entry" }
                : new List<string> { "Software Engineer", "Marketing Manager", "Sales Manager", "Project Manager", "Business Analyst" };
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