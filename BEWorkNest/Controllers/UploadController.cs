using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BEWorkNest.Services;

namespace BEWorkNest.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UploadController : ControllerBase
    {
        private readonly CloudinaryService _cloudinaryService;

        public UploadController(CloudinaryService cloudinaryService)
        {
            _cloudinaryService = cloudinaryService;
        }

        [HttpPost("avatar")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadAvatar(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file uploaded");
            }

            try
            {
                if (!_cloudinaryService.IsImageFile(file))
                {
                    return BadRequest("Only image files are allowed for avatar upload");
                }

                var imageUrl = await _cloudinaryService.UploadImageAsync(file, "avatars");
                return Ok(new { imageUrl });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Upload failed", error = ex.Message });
            }
        }

        [HttpPost("image")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadImage(IFormFile file, [FromQuery] string folder = "images")
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file uploaded");
            }

            try
            {
                if (!_cloudinaryService.IsImageFile(file))
                {
                    return BadRequest("Only image files are allowed");
                }

                var imageUrl = await _cloudinaryService.UploadImageAsync(file, folder);
                return Ok(new { imageUrl });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Upload failed", error = ex.Message });
            }
        }

        [HttpPost("images")]
        [AllowAnonymous]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadImages(List<IFormFile> files, [FromQuery] string folder = "images")
        {
            if (files == null || files.Count == 0)
            {
                return BadRequest("No files uploaded");
            }

            try
            {
                var imageUrls = new List<string>();
                
                foreach (var file in files)
                {
                    if (!_cloudinaryService.IsImageFile(file))
                    {
                        return BadRequest($"File {file.FileName} is not a valid image file");
                    }

                    var imageUrl = await _cloudinaryService.UploadImageAsync(file, folder);
                    imageUrls.Add(imageUrl);
                }

                return Ok(new { imageUrls });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Upload failed", error = ex.Message });
            }
        }

        [HttpPost("pdf")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadPdf(IFormFile file, [FromQuery] string folder = "pdfs")
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file uploaded");
            }

            try
            {
                if (!_cloudinaryService.IsPdfFile(file))
                {
                    return BadRequest("Only PDF files are allowed");
                }

                var fileUrl = await _cloudinaryService.UploadPdfAsync(file, folder);
                return Ok(new { fileUrl });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Upload failed", error = ex.Message });
            }
        }

        [HttpPost("cv")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadCv(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No CV file uploaded");
            }

            try
            {
                if (!_cloudinaryService.IsPdfFile(file))
                {
                    return BadRequest("CV must be in PDF format");
                }

                var cvUrl = await _cloudinaryService.UploadPdfAsync(file, "cvs");
                return Ok(new { cvUrl });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "CV upload failed", error = ex.Message });
            }
        }

        [HttpPost("file")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFile(IFormFile file, [FromQuery] string folder = "files")
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest("No file uploaded");
            }

            try
            {
                var fileUrl = await _cloudinaryService.UploadFileAsync(file, folder);
                return Ok(new { fileUrl });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Upload failed", error = ex.Message });
            }
        }

        [HttpDelete("image")]
        public async Task<IActionResult> DeleteImage([FromQuery] string publicId)
        {
            if (string.IsNullOrEmpty(publicId))
            {
                return BadRequest("Public ID is required");
            }

            try
            {
                var result = await _cloudinaryService.DeleteImageAsync(publicId);
                if (result)
                {
                    return Ok(new { message = "Image deleted successfully" });
                }
                return BadRequest("Failed to delete image");
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Delete failed", error = ex.Message });
            }
        }

        [HttpDelete("file")]
        public async Task<IActionResult> DeleteFile([FromQuery] string publicId)
        {
            if (string.IsNullOrEmpty(publicId))
            {
                return BadRequest("Public ID is required");
            }

            try
            {
                var result = await _cloudinaryService.DeleteFileAsync(publicId);
                if (result)
                {
                    return Ok(new { message = "File deleted successfully" });
                }
                return BadRequest("Failed to delete file");
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Delete failed", error = ex.Message });
            }
        }
    }
}
