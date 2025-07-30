using Microsoft.AspNetCore.Mvc;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GuideController : ControllerBase
    {
        [HttpGet("app-guide")]
        public IActionResult GetAppGuide()
        {
            var guide = new
            {
                appName = "WorkNest",
                version = "1.0.0",
                description = "Ứng dụng tìm việc làm kết nối ứng viên và nhà tuyển dụng",
                
                authentication = new
                {
                    tokenExpiry = "7 ngày",
                    autoLogout = "Token hết hạn sau 7 ngày hoặc khi người dùng logout",
                    persistentLogin = "Đăng nhập được lưu trữ trong SharedPreferences, chỉ bị xóa khi người dùng logout hoặc token hết hạn",
                    sessionManagement = "Ứng dụng tự động kiểm tra token khi khởi động và làm mới thông tin người dùng"
                },
                
                userRoles = new
                {
                    candidate = new
                    {
                        name = "Ứng viên",
                        permissions = new[]
                        {
                            "Xem danh sách việc làm (không cần đăng nhập)",
                            "Xem chi tiết việc làm (cần đăng nhập)",
                            "Nộp hồ sơ ứng tuyển (cần đăng nhập)",
                            "Quản lý hồ sơ ứng tuyển của bản thân (thêm, sửa, xóa)",
                            "Theo dõi nhà tuyển dụng",
                            "Yêu thích việc làm",
                            "Đánh giá nhà tuyển dụng",
                            "Nhận thông báo"
                        },
                        restrictions = new[]
                        {
                            "Không thể tạo, sửa, xóa việc làm",
                            "Không thể xem hồ sơ ứng tuyển của người khác",
                            "Chỉ có thể sửa/xóa hồ sơ ứng tuyển khi trạng thái là 'Pending'"
                        }
                    },
                    recruiter = new
                    {
                        name = "Nhà tuyển dụng",
                        permissions = new[]
                        {
                            "Xem danh sách việc làm",
                            "Tạo việc làm mới",
                            "Quản lý việc làm của bản thân (thêm, sửa, xóa)",
                            "Xem hồ sơ ứng tuyển cho việc làm của mình",
                            "Cập nhật trạng thái hồ sơ ứng tuyển",
                            "Quản lý thông tin công ty",
                            "Đánh giá ứng viên",
                            "Nhận thông báo"
                        },
                        restrictions = new[]
                        {
                            "Không thể nộp hồ sơ ứng tuyển",
                            "Không thể xem/sửa việc làm của nhà tuyển dụng khác",
                            "Không thể xem hồ sơ ứng tuyển của việc làm không phải của mình"
                        }
                    }
                },
                
                features = new
                {
                    jobManagement = new
                    {
                        title = "Quản lý việc làm",
                        forRecruiters = new[]
                        {
                            "Tạo việc làm: POST /api/JobPost (Cần token, role: recruiter)",
                            "Sửa việc làm: PUT /api/JobPost/{id} (Cần token, chỉ chủ sở hữu)",
                            "Xóa việc làm: DELETE /api/JobPost/{id} (Cần token, chỉ chủ sở hữu)",
                            "Xem việc làm của tôi: GET /api/JobPost/my-jobs"
                        },
                        forEveryone = new[]
                        {
                            "Xem danh sách: GET /api/JobPost (Không cần token)",
                            "Xem chi tiết: GET /api/JobPost/{id} (Không cần token)"
                        }
                    },
                    
                    applicationManagement = new
                    {
                        title = "Quản lý hồ sơ ứng tuyển",
                        forCandidates = new[]
                        {
                            "Nộp hồ sơ: POST /api/Application (Cần token, role: candidate)",
                            "Sửa hồ sơ: PUT /api/Application/{id} (Cần token, chỉ khi trạng thái Pending)",
                            "Xóa hồ sơ: DELETE /api/Application/{id} (Cần token, chỉ khi trạng thái Pending)",
                            "Xem hồ sơ của tôi: GET /api/Application/my-applications",
                            "Xem chi tiết hồ sơ: GET /api/Application/{id} (Chỉ hồ sơ của mình)"
                        },
                        forRecruiters = new[]
                        {
                            "Xem hồ sơ ứng tuyển: GET /api/Application/job/{jobId}/applications",
                            "Cập nhật trạng thái: PUT /api/Application/{id}/status",
                            "Xem chi tiết hồ sơ: GET /api/Application/{id} (Chỉ hồ sơ cho việc làm của mình)"
                        }
                    },
                    
                    otherFeatures = new[]
                    {
                        "Theo dõi nhà tuyển dụng: POST/DELETE /api/Follow",
                        "Yêu thích việc làm: POST/DELETE /api/Favorite",
                        "Đánh giá: POST /api/Review",
                        "Thông báo: GET /api/Notification",
                        "Tải lên file: POST /api/Upload"
                    }
                },
                
                securityNotes = new
                {
                    tokenSecurity = new[]
                    {
                        "Token JWT được ký bằng HMAC SHA256",
                        "Token chứa thông tin user ID, email, role, tên",
                        "Token tự động hết hạn sau 7 ngày",
                        "API tự động xác thực token cho các endpoint cần authentication"
                    },
                    dataProtection = new[]
                    {
                        "Mật khẩu được hash bằng ASP.NET Core Identity",
                        "File CV chỉ chấp nhận định dạng PDF",
                        "Hình ảnh được lưu trữ trên Cloudinary",
                        "Soft delete cho hầu hết các thao tác xóa"
                    }
                },
                
                troubleshooting = new
                {
                    commonIssues = new[]
                    {
                        "Lỗi 401 Unauthorized: Token không hợp lệ hoặc hết hạn - Cần đăng nhập lại",
                        "Lỗi 403 Forbidden: Không có quyền truy cập - Kiểm tra role và ownership",
                        "Lỗi 400 Bad Request: Dữ liệu không hợp lệ - Kiểm tra format và required fields",
                        "Lỗi 404 Not Found: Resource không tồn tại hoặc đã bị xóa"
                    },
                    tips = new[]
                    {
                        "Luôn gửi kèm Authorization header: 'Bearer {token}' cho các API cần authentication",
                        "Kiểm tra role của user trước khi gọi API có yêu cầu role cụ thể",
                        "File CV phải là PDF và có kích thước hợp lý",
                        "Sử dụng HTTPS trong production environment"
                    }
                }
            };

            return Ok(guide);
        }

        [HttpGet("api-documentation")]
        public IActionResult GetApiDocumentation()
        {
            var apiDocs = new
            {
                baseUrl = "http://localhost:5006",
                contentType = "application/json",
                
                authEndpoints = new
                {
                    login = new
                    {
                        method = "POST",
                        url = "/api/Auth/login",
                        requiresAuth = false,
                        body = new { email = "string", password = "string" },
                        response = new { token = "string", user = new { id = "string", email = "string", firstName = "string", lastName = "string", role = "string" } }
                    },
                    register = new
                    {
                        candidate = new
                        {
                            method = "POST",
                            url = "/api/Auth/register/candidate",
                            body = new { email = "string", password = "string", firstName = "string", lastName = "string" }
                        },
                        recruiter = new
                        {
                            method = "POST",
                            url = "/api/Auth/register/recruiter",
                            body = "FormData with company info and images"
                        }
                    },
                    profile = new
                    {
                        get = new { method = "GET", url = "/api/Auth/profile", requiresAuth = true },
                        update = new { method = "PUT", url = "/api/Auth/profile", requiresAuth = true }
                    }
                },
                
                jobEndpoints = new
                {
                    list = new { method = "GET", url = "/api/JobPost?page=1&pageSize=10", requiresAuth = false },
                    detail = new { method = "GET", url = "/api/JobPost/{id}", requiresAuth = false },
                    create = new { method = "POST", url = "/api/JobPost", requiresAuth = true, role = "recruiter" },
                    update = new { method = "PUT", url = "/api/JobPost/{id}", requiresAuth = true, role = "recruiter", note = "Only job owner" },
                    delete = new { method = "DELETE", url = "/api/JobPost/{id}", requiresAuth = true, role = "recruiter", note = "Only job owner" },
                    myJobs = new { method = "GET", url = "/api/JobPost/my-jobs", requiresAuth = true, role = "recruiter" }
                },
                
                applicationEndpoints = new
                {
                    create = new { method = "POST", url = "/api/Application", requiresAuth = true, role = "candidate", contentType = "multipart/form-data" },
                    update = new { method = "PUT", url = "/api/Application/{id}", requiresAuth = true, role = "candidate", note = "Only pending applications" },
                    delete = new { method = "DELETE", url = "/api/Application/{id}", requiresAuth = true, role = "candidate", note = "Only pending applications" },
                    detail = new { method = "GET", url = "/api/Application/{id}", requiresAuth = true, note = "Only owner or job recruiter" },
                    myApplications = new { method = "GET", url = "/api/Application/my-applications", requiresAuth = true, role = "candidate" },
                    jobApplications = new { method = "GET", url = "/api/Application/job/{jobId}/applications", requiresAuth = true, role = "recruiter" },
                    updateStatus = new { method = "PUT", url = "/api/Application/{id}/status", requiresAuth = true, role = "recruiter" }
                }
            };

            return Ok(apiDocs);
        }
    }
}
