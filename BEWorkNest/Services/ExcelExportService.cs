using OfficeOpenXml;
using OfficeOpenXml.Style;
using BEWorkNest.Models;
using System.Drawing;

namespace BEWorkNest.Services
{
    public class ExcelExportService
    {
        public async Task<byte[]> ExportDetailedAnalyticsToExcel(DetailedAnalytics analytics, string recruiterId)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            
            using var package = new ExcelPackage();
            
            // Create worksheets
            CreateSummaryWorksheet(package, analytics);
            CreateJobsWorksheet(package, analytics.Jobs);
            CreateApplicationsWorksheet(package, analytics.Recruiter);
            CreateFollowersWorksheet(package, analytics.Recruiter);
            CreateChartsWorksheet(package, analytics);
            
            return await Task.FromResult(package.GetAsByteArray());
        }

        private void CreateSummaryWorksheet(ExcelPackage package, DetailedAnalytics analytics)
        {
            var worksheet = package.Workbook.Worksheets.Add("Tổng quan");
            
            // Title
            worksheet.Cells["A1"].Value = "BÁO CÁO PHÂN TÍCH TUYỂN DỤNG";
            worksheet.Cells["A1:F1"].Merge = true;
            worksheet.Cells["A1"].Style.Font.Size = 16;
            worksheet.Cells["A1"].Style.Font.Bold = true;
            worksheet.Cells["A1"].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            worksheet.Cells["A2"].Value = $"Ngày tạo báo cáo: {analytics.GeneratedAt:dd/MM/yyyy HH:mm}";
            worksheet.Cells["A2:F2"].Merge = true;
            worksheet.Cells["A2"].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            
            // Company Info
            int row = 4;
            worksheet.Cells[$"A{row}"].Value = "THÔNG TIN CÔNG TY";
            worksheet.Cells[$"A{row}:F{row}"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells[$"A{row}:F{row}"]);
            
            row++;
            worksheet.Cells[$"A{row}"].Value = "Tên công ty:";
            worksheet.Cells[$"B{row}"].Value = analytics.Company.CompanyName;
            row++;
            worksheet.Cells[$"A{row}"].Value = "Địa điểm:";
            worksheet.Cells[$"B{row}"].Value = analytics.Company.CompanyLocation;
            row++;
            worksheet.Cells[$"A{row}"].Value = "Trạng thái xác minh:";
            worksheet.Cells[$"B{row}"].Value = analytics.Company.IsVerified ? "Đã xác minh" : "Chưa xác minh";
            row++;
            worksheet.Cells[$"A{row}"].Value = "Số người theo dõi:";
            worksheet.Cells[$"B{row}"].Value = analytics.Company.TotalFollowers;
            
            // Job Statistics
            row += 2;
            worksheet.Cells[$"A{row}"].Value = "THỐNG KÊ CÔNG VIỆC";
            worksheet.Cells[$"A{row}:F{row}"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells[$"A{row}:F{row}"]);
            
            row++;
            AddStatRow(worksheet, ref row, "Tổng số việc làm đã đăng:", analytics.Recruiter.TotalJobsPosted);
            AddStatRow(worksheet, ref row, "Việc làm đang hoạt động:", analytics.Recruiter.ActiveJobs);
            AddStatRow(worksheet, ref row, "Việc làm đã đóng:", analytics.Recruiter.InactiveJobs);
            AddStatRow(worksheet, ref row, "Tổng lượt xem:", analytics.Recruiter.TotalJobViews);
            AddStatRow(worksheet, ref row, "Trung bình lượt xem/việc làm:", analytics.Recruiter.AverageViewsPerJob);
            
            // Application Statistics
            row++;
            worksheet.Cells[$"A{row}"].Value = "THỐNG KÊ ỨNG TUYỂN";
            worksheet.Cells[$"A{row}:F{row}"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells[$"A{row}:F{row}"]);
            
            row++;
            AddStatRow(worksheet, ref row, "Tổng số ứng tuyển:", analytics.Recruiter.TotalApplicationsReceived);
            AddStatRow(worksheet, ref row, "Đơn chờ xử lý:", analytics.Recruiter.PendingApplications);
            AddStatRow(worksheet, ref row, "Đơn được chấp nhận:", analytics.Recruiter.AcceptedApplications);
            AddStatRow(worksheet, ref row, "Đơn bị từ chối:", analytics.Recruiter.RejectedApplications);
            AddStatRow(worksheet, ref row, "Trung bình ứng tuyển/việc làm:", analytics.Recruiter.AverageApplicationsPerJob);
            AddStatRow(worksheet, ref row, "Tỷ lệ ứng tuyển/xem:", $"{analytics.Recruiter.ApplicationToViewRatio:P2}");
            
            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateJobsWorksheet(ExcelPackage package, JobAnalytics jobAnalytics)
        {
            var worksheet = package.Workbook.Worksheets.Add("Chi tiết công việc");
            
            // Headers
            var headers = new[]
            {
                "ID", "Tiêu đề", "Danh mục", "Địa điểm", "Mức lương", "Kinh nghiệm",
                "Ngày đăng", "Hạn nộp", "Trạng thái", "Lượt xem", "Ứng tuyển",
                "Chờ xử lý", "Chấp nhận", "Từ chối", "Tỷ lệ chuyển đổi", "Yêu thích"
            };
            
            for (int i = 0; i < headers.Length; i++)
            {
                worksheet.Cells[1, i + 1].Value = headers[i];
            }
            ApplyHeaderStyle(worksheet.Cells[1, 1, 1, headers.Length]);
            
            // Data
            int row = 2;
            foreach (var job in jobAnalytics.AllJobs)
            {
                worksheet.Cells[row, 1].Value = job.JobId;
                worksheet.Cells[row, 2].Value = job.JobTitle;
                worksheet.Cells[row, 3].Value = job.JobCategory;
                worksheet.Cells[row, 4].Value = job.JobLocation;
                worksheet.Cells[row, 5].Value = job.Salary;
                worksheet.Cells[row, 6].Value = job.ExperienceLevel;
                worksheet.Cells[row, 7].Value = job.PostedDate.ToString("dd/MM/yyyy");
                worksheet.Cells[row, 8].Value = job.DeadLine?.ToString("dd/MM/yyyy") ?? "Không giới hạn";
                worksheet.Cells[row, 9].Value = job.IsActive ? "Đang mở" : "Đã đóng";
                worksheet.Cells[row, 10].Value = job.TotalViews;
                worksheet.Cells[row, 11].Value = job.TotalApplications;
                worksheet.Cells[row, 12].Value = job.PendingApplications;
                worksheet.Cells[row, 13].Value = job.AcceptedApplications;
                worksheet.Cells[row, 14].Value = job.RejectedApplications;
                worksheet.Cells[row, 15].Value = $"{job.ViewToApplicationRatio:P2}";
                worksheet.Cells[row, 16].Value = job.FavoriteCount;
                
                row++;
            }
            
            // Format salary column
            worksheet.Cells[2, 5, row - 1, 5].Style.Numberformat.Format = "#,##0 ₫";
            
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateApplicationsWorksheet(ExcelPackage package, RecruiterAnalytics recruiterAnalytics)
        {
            var worksheet = package.Workbook.Worksheets.Add("Chi tiết ứng tuyển");
            
            // Create summary table first
            worksheet.Cells["A1"].Value = "TỔNG KẾT ỨNG TUYỂN THEO THÁNG";
            worksheet.Cells["A1:C1"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells["A1:C1"]);
            
            worksheet.Cells["A2"].Value = "Tháng";
            worksheet.Cells["B2"].Value = "Số ứng tuyển";
            worksheet.Cells["C2"].Value = "Tăng trưởng";
            ApplyHeaderStyle(worksheet.Cells["A2:C2"]);
            
            int row = 3;
            decimal previousValue = 0;
            foreach (var monthData in recruiterAnalytics.ApplicationsByMonth)
            {
                worksheet.Cells[row, 1].Value = monthData.Label;
                worksheet.Cells[row, 2].Value = monthData.Value;
                
                if (previousValue > 0)
                {
                    var growth = (((double)monthData.Value - (double)previousValue) / (double)previousValue) * 100;
                    worksheet.Cells[row, 3].Value = $"{growth:F1}%";
                    
                    if (growth > 0)
                        worksheet.Cells[row, 3].Style.Font.Color.SetColor(Color.Green);
                    else if (growth < 0)
                        worksheet.Cells[row, 3].Style.Font.Color.SetColor(Color.Red);
                }
                else
                {
                    worksheet.Cells[row, 3].Value = "N/A";
                }
                
                previousValue = (decimal)monthData.Value;
                row++;
            }
            
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateFollowersWorksheet(ExcelPackage package, RecruiterAnalytics recruiterAnalytics)
        {
            var worksheet = package.Workbook.Worksheets.Add("Người theo dõi");
            
            // Headers
            worksheet.Cells["A1"].Value = "Tên";
            worksheet.Cells["B1"].Value = "Email";
            worksheet.Cells["C1"].Value = "Ngày theo dõi";
            ApplyHeaderStyle(worksheet.Cells["A1:C1"]);
            
            // Data
            int row = 2;
            foreach (var follower in recruiterAnalytics.RecentFollowers)
            {
                worksheet.Cells[row, 1].Value = follower.UserName;
                worksheet.Cells[row, 2].Value = follower.UserEmail;
                worksheet.Cells[row, 3].Value = follower.FollowedDate.ToString("dd/MM/yyyy HH:mm");
                row++;
            }
            
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateChartsWorksheet(ExcelPackage package, DetailedAnalytics analytics)
        {
            var worksheet = package.Workbook.Worksheets.Add("Biểu đồ dữ liệu");
            
            // Job Categories Chart Data
            worksheet.Cells["A1"].Value = "PHÂN BỐ THEO DANH MỤC CÔNG VIỆC";
            worksheet.Cells["A1:B1"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells["A1:B1"]);
            
            worksheet.Cells["A2"].Value = "Danh mục";
            worksheet.Cells["B2"].Value = "Số lượng";
            ApplyHeaderStyle(worksheet.Cells["A2:B2"]);
            
            int row = 3;
            foreach (var category in analytics.Recruiter.TopJobCategories)
            {
                worksheet.Cells[row, 1].Value = category.Label;
                worksheet.Cells[row, 2].Value = category.Value;
                row++;
            }
            
            // Location Chart Data
            row += 2;
            worksheet.Cells[$"A{row}"].Value = "PHÂN BỐ THEO ĐỊA ĐIỂM";
            worksheet.Cells[$"A{row}:B{row}"].Merge = true;
            ApplyHeaderStyle(worksheet.Cells[$"A{row}:B{row}"]);
            
            row++;
            worksheet.Cells[$"A{row}"].Value = "Địa điểm";
            worksheet.Cells[$"B{row}"].Value = "Số lượng";
            ApplyHeaderStyle(worksheet.Cells[$"A{row}:B{row}"]);
            
            row++;
            foreach (var location in analytics.Jobs.JobsByLocation)
            {
                worksheet.Cells[row, 1].Value = location.Label;
                worksheet.Cells[row, 2].Value = location.Value;
                row++;
            }
            
            worksheet.Cells.AutoFitColumns();
        }

        private void AddStatRow(ExcelWorksheet worksheet, ref int row, string label, object value)
        {
            worksheet.Cells[row, 1].Value = label;
            worksheet.Cells[row, 2].Value = value;
            worksheet.Cells[row, 1].Style.Font.Bold = true;
            row++;
        }

        private void ApplyHeaderStyle(ExcelRange range)
        {
            range.Style.Font.Bold = true;
            range.Style.Fill.PatternType = ExcelFillStyle.Solid;
            range.Style.Fill.BackgroundColor.SetColor(Color.LightBlue);
            range.Style.Border.Top.Style = ExcelBorderStyle.Thin;
            range.Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
            range.Style.Border.Left.Style = ExcelBorderStyle.Thin;
            range.Style.Border.Right.Style = ExcelBorderStyle.Thin;
        }
    }
}
