import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/upload_provider.dart';
import '../../../core/services/cv_analysis_service.dart';
import '../../../core/utils/cross_platform_file.dart';

class EditApplicationDialog extends ConsumerStatefulWidget {
  final ApplicationModel application;
  final VoidCallback onUpdated;

  const EditApplicationDialog({
    super.key,
    required this.application,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditApplicationDialog> createState() => _EditApplicationDialogState();
}

class _EditApplicationDialogState extends ConsumerState<EditApplicationDialog> {
  late TextEditingController _coverLetterController;
  CrossPlatformFile? _selectedCvFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _coverLetterController = TextEditingController(
      text: widget.application.coverLetter ?? '',
    );
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Text(
                    'Chỉnh sửa ứng tuyển',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Info (read-only)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.work, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.application.job?.title ?? 'Không có tiêu đề',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.application.job?.recruiter.company?.name != null)
                                  Text(
                                    widget.application.job!.recruiter.company!.name,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CV Upload Section
                    Text(
                      'CV đính kèm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Current CV (if exists)
                    if (widget.application.cvUrl != null && _selectedCvFile == null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CV hiện tại',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Đã có CV được tải lên',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _pickCV,
                              child: const Text('Thay đổi'),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedCvFile != null) ...[
                      // New CV selected
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CV mới',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  Text(
                                    _selectedCvFile!.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCvFile = null;
                                });
                              },
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // No CV
                      GestureDetector(
                        onTap: _pickCV,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chọn file CV',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'PDF, DOC, DOCX (tối đa 5MB)',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),

                    // Cover Letter
                    Text(
                      'Thư giới thiệu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _coverLetterController,
                      decoration: const InputDecoration(
                        hintText: 'Viết thư giới thiệu của bạn...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 6,
                    ),
                    
                    if (uploadState.isUploading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Đang tải CV lên...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting || uploadState.isUploading ? null : _updateApplication,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cập nhật'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCV() async {
    try {
      final cvAnalysisService = ref.read(cvAnalysisServiceProvider);
      final file = await cvAnalysisService.pickCVFile();
      
      if (file != null) {
        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File quá lớn. Vui lòng chọn file nhỏ hơn 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedCvFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateApplication() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? cvUrl = widget.application.cvUrl;

      // Upload new CV if selected
      if (_selectedCvFile != null) {
        try {
          final uploadResult = await ref.read(uploadProvider.notifier).uploadFile(
            await _selectedCvFile!.toFile(),
            'cv',
          );

          if (!uploadResult.success) {
            throw Exception(uploadResult.message ?? 'Không thể tải CV lên');
          }

          cvUrl = uploadResult.url;
        } catch (e) {
          if (e.toString().contains('not supported on web')) {
            // For web platform, we'll skip file upload for now
            throw Exception('Upload file chưa được hỗ trợ trên web platform');
          } else {
            rethrow;
          }
        }
      }

      // Update application
      final success = await ref.read(applicationProvider.notifier).updateApplication(
        widget.application.id,
        coverLetter: _coverLetterController.text.trim().isEmpty 
            ? null 
            : _coverLetterController.text.trim(),
        cvUrl: cvUrl,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật đơn ứng tuyển thành công'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onUpdated();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
