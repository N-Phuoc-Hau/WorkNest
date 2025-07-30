using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models.DTOs
{
    public class CompanyDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string TaxCode { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public List<string> Images { get; set; } = new List<string>();
    }

    public class CreateCompanyDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        public string TaxCode { get; set; } = string.Empty;
        
        [Required]
        public string Description { get; set; } = string.Empty;
        
        [Required]
        public string Location { get; set; } = string.Empty;
        
        [Required]
        [MinLength(3, ErrorMessage = "Công ty phải có ít nhất 3 ảnh môi trường làm việc")]
        public List<string> Images { get; set; } = new List<string>();
    }

    public class UpdateCompanyDto
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? Location { get; set; }
        public List<string>? Images { get; set; }
    }
}
