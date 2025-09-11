using System.Text;
using iText.Kernel.Pdf;
using iText.Kernel.Pdf.Canvas.Parser;
using iText.Kernel.Pdf.Canvas.Parser.Listener;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using Tesseract;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using ImageMagick;

namespace BEWorkNest.Services
{
    public class CVProcessingService
    {
        private readonly ILogger<CVProcessingService> _logger;

        public CVProcessingService(ILogger<CVProcessingService> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Extract text from CV file (PDF, DOCX, or TXT)
        /// </summary>
        public async Task<string> ExtractTextFromCVAsync(IFormFile cvFile)
        {
            try
            {
                var fileExtension = Path.GetExtension(cvFile.FileName).ToLowerInvariant();

                switch (fileExtension)
                {
                    case ".pdf":
                        return ExtractTextFromPdfAsync(cvFile);
                    case ".docx":
                        return ExtractTextFromDocxAsync(cvFile);
                    case ".txt":
                        return await ExtractTextFromTxtAsync(cvFile);
                    default:
                        throw new NotSupportedException($"File type {fileExtension} is not supported. Only PDF, DOCX, and TXT files are allowed.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting text from CV file: {FileName}", cvFile.FileName);
                throw;
            }
        }

        /// <summary>
        /// Extract text from URL (if CV is stored as URL)
        /// </summary>
        public async Task<string> ExtractTextFromUrlAsync(string cvUrl)
        {
            try
            {
                using var httpClient = new HttpClient();
                var response = await httpClient.GetAsync(cvUrl);
                response.EnsureSuccessStatusCode();

                var fileName = Path.GetFileName(new Uri(cvUrl).LocalPath);
                var fileExtension = Path.GetExtension(fileName).ToLowerInvariant();
                
                using var stream = await response.Content.ReadAsStreamAsync();

                switch (fileExtension)
                {
                    case ".pdf":
                        return ExtractTextFromPdfStream(stream);
                    case ".docx":
                        return ExtractTextFromDocxStream(stream);
                    case ".txt":
                        {
                            using var reader = new StreamReader(stream);
                            return await reader.ReadToEndAsync();
                        }
                    default:
                        throw new NotSupportedException($"File type {fileExtension} is not supported.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting text from CV URL: {CvUrl}", cvUrl);
                throw;
            }
        }

        private string ExtractTextFromPdfAsync(IFormFile pdfFile)
        {
            // Copy the stream to a MemoryStream to avoid stream disposal issues
            using var originalStream = pdfFile.OpenReadStream();
            using var memoryStream = new MemoryStream();
            originalStream.CopyTo(memoryStream);
            memoryStream.Position = 0;
            
            return ExtractTextFromPdfStream(memoryStream);
        }

        private string ExtractTextFromPdfStream(Stream pdfStream)
        {
            try
            {
                // Ensure stream is at the beginning
                if (pdfStream.CanSeek)
                {
                    pdfStream.Position = 0;
                }

                string extractedText;
                byte[] streamBytes;
                
                // Read stream into byte array for multiple uses
                if (pdfStream is MemoryStream ms)
                {
                    streamBytes = ms.ToArray();
                }
                else
                {
                    using var tempMs = new MemoryStream();
                    pdfStream.CopyTo(tempMs);
                    streamBytes = tempMs.ToArray();
                }

                // First attempt: normal PDF text extraction
                using (var textStream = new MemoryStream(streamBytes))
                {
                    using var pdfReader = new PdfReader(textStream);
                    using var pdfDocument = new PdfDocument(pdfReader);

                    var text = new StringBuilder();
                    for (int i = 1; i <= pdfDocument.GetNumberOfPages(); i++)
                    {
                        var page = pdfDocument.GetPage(i);
                        var textExtractionStrategy = new SimpleTextExtractionStrategy();
                        var pageText = PdfTextExtractor.GetTextFromPage(page, textExtractionStrategy);
                        text.AppendLine(pageText);
                    }

                    extractedText = text.ToString().Trim();
                }
                
                // If extracted text is too short (likely scanned PDF), try OCR
                if (extractedText.Length < 50)
                {
                    _logger.LogInformation("Text extraction yielded minimal text ({Length} chars), attempting OCR...", extractedText.Length);
                    
                    using var ocrStream = new MemoryStream(streamBytes);
                    var ocrText = ExtractTextFromPdfUsingOCR(ocrStream);
                    
                    if (!string.IsNullOrEmpty(ocrText) && ocrText.Length > extractedText.Length)
                    {
                        _logger.LogInformation("OCR extracted {OcrLength} chars vs normal extraction {NormalLength} chars", 
                            ocrText.Length, extractedText.Length);
                        return ocrText;
                    }
                }

                return extractedText;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting text from PDF stream");
                throw new Exception("Unable to extract text from PDF file. The file may be corrupted or password protected.", ex);
            }
        }

        private string ExtractTextFromDocxAsync(IFormFile docxFile)
        {
            // Copy the stream to a MemoryStream to avoid stream disposal issues
            using var originalStream = docxFile.OpenReadStream();
            using var memoryStream = new MemoryStream();
            originalStream.CopyTo(memoryStream);
            memoryStream.Position = 0;
            
            return ExtractTextFromDocxStream(memoryStream);
        }

        private string ExtractTextFromDocxStream(Stream docxStream)
        {
            try
            {
                using var wordDocument = WordprocessingDocument.Open(docxStream, false);
                var mainPart = wordDocument.MainDocumentPart;
                
                if (mainPart?.Document.Body == null)
                {
                    return string.Empty;
                }

                var text = new StringBuilder();
                var paragraphs = mainPart.Document.Body.Elements<Paragraph>();

                foreach (var paragraph in paragraphs)
                {
                    var runs = paragraph.Elements<Run>();
                    foreach (var run in runs)
                    {
                        var texts = run.Elements<Text>();
                        foreach (var textElement in texts)
                        {
                            text.Append(textElement.Text);
                        }
                    }
                    text.AppendLine();
                }

                return text.ToString();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error extracting text from DOCX stream");
                throw new Exception("Unable to extract text from DOCX file. The file may be corrupted.", ex);
            }
        }

        private async Task<string> ExtractTextFromTxtAsync(IFormFile txtFile)
        {
            try
            {
                using var reader = new StreamReader(txtFile.OpenReadStream());
                return await reader.ReadToEndAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reading text file");
                throw new Exception("Unable to read text file.", ex);
            }
        }

        /// <summary>
        /// Clean and normalize extracted text
        /// </summary>
        public string CleanExtractedText(string rawText)
        {
            if (string.IsNullOrWhiteSpace(rawText))
                return string.Empty;

            // Remove excessive whitespace
            var cleanText = System.Text.RegularExpressions.Regex.Replace(rawText, @"\s+", " ");
            
            // Remove special characters but keep important punctuation
            cleanText = System.Text.RegularExpressions.Regex.Replace(cleanText, @"[^\w\s\.\,\-\+\(\)\@\:\/]", "");
            
            // Trim and return
            return cleanText.Trim();
        }

        /// <summary>
        /// Extract text from PDF using OCR for scanned documents
        /// </summary>
        private string ExtractTextFromPdfUsingOCR(Stream pdfStream)
        {
            try
            {
                _logger.LogInformation("Starting OCR extraction from PDF...");
                
                // Ensure stream is at the beginning
                if (pdfStream.CanSeek)
                {
                    pdfStream.Position = 0;
                    _logger.LogInformation("Stream position reset to 0");
                }

                // Use Magick.NET to read PDF pages as images
                var combinedText = new StringBuilder();

                _logger.LogInformation("Initializing MagickImageCollection...");
                // Create temp directory for images (in memory, not persisted)
                using (var images = new MagickImageCollection())
                {
                    var settings = new MagickReadSettings()
                    {
                        Density = new Density(300, 300), // high density for better OCR
                        ColorType = ColorType.TrueColor
                    };

                    _logger.LogInformation("Reading PDF from stream with settings...");
                    
                    // Read stream into byte array first to avoid stream issues
                    byte[] pdfBytes;
                    if (pdfStream is MemoryStream ms)
                    {
                        pdfBytes = ms.ToArray();
                    }
                    else
                    {
                        using var tempMs = new MemoryStream();
                        pdfStream.CopyTo(tempMs);
                        pdfBytes = tempMs.ToArray();
                    }
                    
                    // Read PDF from byte array
                    images.Read(pdfBytes, settings);
                    _logger.LogInformation("PDF read successfully. Page count: {Count}", images.Count);

                    _logger.LogInformation("Initializing TesseractEngine with tessdata path: ./tessdata");
                    using var engine = new TesseractEngine(@"./tessdata", "eng", EngineMode.Default);
                    _logger.LogInformation("TesseractEngine initialized successfully");

                    for (int i = 0; i < images.Count; i++)
                    {
                        _logger.LogInformation("Processing page {PageNum} of {Total}", i + 1, images.Count);
                        using var page = (MagickImage)images[i];

                        // Preprocess image for OCR: convert to grayscale and enhance
                        page.Grayscale();
                        page.Contrast();
                        page.Strip();

                        // Convert MagickImage to a memory stream in PNG format
                        using var imageMs = new MemoryStream();
                        page.Write(imageMs, MagickFormat.Png);
                        var imageBytes = imageMs.ToArray();
                        _logger.LogInformation("Page {PageNum} converted to PNG, size: {Size} bytes", i + 1, imageBytes.Length);

                        using var img = Pix.LoadFromMemory(imageBytes);
                        using var pagePix = engine.Process(img);
                        var pageText = pagePix.GetText();

                        _logger.LogInformation("Page {PageNum} OCR result length: {Length}", i + 1, pageText?.Length ?? 0);
                        if (!string.IsNullOrWhiteSpace(pageText))
                        {
                            combinedText.AppendLine(pageText.Trim());
                        }
                    }
                }

                var resultText = combinedText.ToString().Trim();
                _logger.LogInformation("OCR extraction completed. Total length: {Len}", resultText.Length);
                return resultText;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during OCR extraction: {Message}", ex.Message);
                _logger.LogError("Stack trace: {StackTrace}", ex.StackTrace);
                return "";
            }
        }

        /// <summary>
        /// Validate CV file before processing
        /// </summary>
        public bool IsValidCVFile(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return false;

            var allowedExtensions = new[] { ".pdf", ".docx", ".txt" };
            var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(fileExtension))
                return false;

            // Check file size (max 10MB)
            var maxSizeInBytes = 10 * 1024 * 1024; // 10MB
            if (file.Length > maxSizeInBytes)
                return false;

            return true;
        }
    }
}
