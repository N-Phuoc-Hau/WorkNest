using System.ComponentModel.DataAnnotations;

namespace BEWorkNest.Models
{
    public abstract class BaseModel
    {
        [Key]
        public int Id { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        public bool IsDeleted { get; set; } = false;
    }
}
