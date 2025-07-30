using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace BEWorkNest.Services
{
    public class CloudinaryService
    {
        private readonly Cloudinary _cloudinary;

        public CloudinaryService(IConfiguration configuration)
        {
            var cloudinaryUrl = configuration["Cloudinary:CloudinaryUrl"];
            _cloudinary = new Cloudinary(cloudinaryUrl);
        }

        public async Task<string> UploadImageAsync(IFormFile file, string folder = "images")
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File is null or empty");
            }

            // Validate file size (max 5MB for images)
            const int maxFileSize = 5 * 1024 * 1024; // 5MB
            if (file.Length > maxFileSize)
            {
                throw new ArgumentException("Image file size cannot exceed 5MB");
            }

            // Validate image file types
            var allowedImageTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
            if (!allowedImageTypes.Contains(file.ContentType.ToLower()))
            {
                throw new ArgumentException("Only image files (JPEG, PNG, GIF) are allowed");
            }

            using var stream = file.OpenReadStream();
            var uploadParams = new ImageUploadParams()
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder,
                Transformation = new Transformation().Quality("auto").FetchFormat("auto")
            };

            var result = await _cloudinary.UploadAsync(uploadParams);
            
            if (result.Error != null)
            {
                throw new Exception($"Cloudinary upload failed: {result.Error.Message}");
            }

            return result.SecureUrl.ToString();
        }

        public async Task<string> UploadFileAsync(IFormFile file, string folder = "files")
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File is null or empty");
            }

            // Validate file size (max 10MB)
            const int maxFileSize = 10 * 1024 * 1024; // 10MB
            if (file.Length > maxFileSize)
            {
                throw new ArgumentException("File size cannot exceed 10MB");
            }

            using var stream = file.OpenReadStream();
            var uploadParams = new RawUploadParams()
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder
            };

            var result = await _cloudinary.UploadAsync(uploadParams);
            
            if (result.Error != null)
            {
                throw new Exception($"Cloudinary upload failed: {result.Error.Message}");
            }

            return result.SecureUrl.ToString();
        }

        public async Task<string> UploadPdfAsync(IFormFile file, string folder = "cvs")
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File is null or empty");
            }

            // Validate PDF file type
            var allowedPdfTypes = new[] { "application/pdf", "application/x-pdf" };
            if (!allowedPdfTypes.Contains(file.ContentType.ToLower()) && 
                !file.FileName.ToLower().EndsWith(".pdf"))
            {
                throw new ArgumentException("Only PDF files are allowed for CV uploads");
            }

            // Validate file size (max 5MB for CV)
            const int maxFileSize = 5 * 1024 * 1024; // 5MB
            if (file.Length > maxFileSize)
            {
                throw new ArgumentException("CV file size cannot exceed 5MB");
            }

            using var stream = file.OpenReadStream();
            var uploadParams = new RawUploadParams()
            {
                File = new FileDescription(file.FileName, stream),
                Folder = folder
            };

            var result = await _cloudinary.UploadAsync(uploadParams);
            
            if (result.Error != null)
            {
                throw new Exception($"Cloudinary upload failed: {result.Error.Message}");
            }

            return result.SecureUrl.ToString();
        }

        public async Task<List<string>> UploadMultipleImagesAsync(List<IFormFile> files, string folder = "images")
        {
            if (files == null || files.Count == 0)
            {
                throw new ArgumentException("Files list is null or empty");
            }

            var uploadTasks = new List<Task<string>>();
            
            foreach (var file in files)
            {
                uploadTasks.Add(UploadImageAsync(file, folder));
            }

            var results = await Task.WhenAll(uploadTasks);
            return results.ToList();
        }

        public async Task<bool> DeleteImageAsync(string publicId)
        {
            var deleteParams = new DeletionParams(publicId);
            var result = await _cloudinary.DestroyAsync(deleteParams);
            return result.Result == "ok";
        }

        public async Task<bool> DeleteFileAsync(string publicId)
        {
            var deleteParams = new DeletionParams(publicId)
            {
                ResourceType = ResourceType.Raw
            };
            var result = await _cloudinary.DestroyAsync(deleteParams);
            return result.Result == "ok";
        }

        public string GetPublicIdFromUrl(string url)
        {
            if (string.IsNullOrEmpty(url))
                return string.Empty;

            try
            {
                var uri = new Uri(url);
                var segments = uri.Segments;
                
                // Find the segment that contains the public ID
                for (int i = 0; i < segments.Length; i++)
                {
                    if (segments[i].Contains("upload/"))
                    {
                        // The public ID is typically after "upload/" and before file extension
                        var publicIdSegment = segments[i + 1];
                        var publicId = publicIdSegment.TrimEnd('/');
                        
                        // Remove file extension if present
                        var dotIndex = publicId.LastIndexOf('.');
                        if (dotIndex > 0)
                        {
                            publicId = publicId.Substring(0, dotIndex);
                        }
                        
                        return publicId;
                    }
                }

                // Fallback method
                var path = uri.AbsolutePath;
                var lastSlash = path.LastIndexOf('/');
                var lastDot = path.LastIndexOf('.');
                
                if (lastSlash >= 0 && lastDot > lastSlash)
                {
                    return path.Substring(lastSlash + 1, lastDot - lastSlash - 1);
                }
                
                return string.Empty;
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        public bool IsImageFile(IFormFile file)
        {
            var allowedImageTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif" };
            return allowedImageTypes.Contains(file.ContentType.ToLower());
        }

        public bool IsPdfFile(IFormFile file)
        {
            var allowedPdfTypes = new[] { "application/pdf", "application/x-pdf" };
            return allowedPdfTypes.Contains(file.ContentType.ToLower()) || 
                   file.FileName.ToLower().EndsWith(".pdf");
        }
    }
}
