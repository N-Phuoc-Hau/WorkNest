import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/application_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class JobApplicationDialog extends ConsumerStatefulWidget {
  final int jobId;
  final String jobTitle;
  final String companyName;

  const JobApplicationDialog({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
  });

  @override
  ConsumerState<JobApplicationDialog> createState() => _JobApplicationDialogState();
}

class _JobApplicationDialogState extends ConsumerState<JobApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  
  File? _selectedCvFile;
  XFile? _selectedCvXFile;
  String? _selectedFileName;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickCvFile() async {
    try {
      if (kIsWeb) {
        // Web version
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          _selectedCvXFile = XFile.fromData(
            file.bytes!,
            name: file.name,
          );
          _selectedFileName = file.name;
          setState(() {});
        }
      } else {
        // Mobile/Desktop version
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          _selectedCvFile = File(result.files.first.path!);
          _selectedFileName = result.files.first.name;
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCvFile == null && _selectedCvXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn file CV (PDF)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Debug: Check auth state before submission
    final authState = ref.read(authProvider);
    print('DEBUG JobApplicationDialog: Auth state check');
    print('DEBUG JobApplicationDialog: Is authenticated: ${authState.isAuthenticated}');
    print('DEBUG JobApplicationDialog: User: ${authState.user?.email}');
    print('DEBUG JobApplicationDialog: Has accessToken: ${authState.accessToken != null}');
    if (authState.accessToken != null) {
      print('DEBUG JobApplicationDialog: AccessToken preview: ${authState.accessToken!.substring(0, 20)}...');
    }

    print('DEBUG JobApplicationDialog: Starting application submission');
    print('DEBUG JobApplicationDialog: JobId: ${widget.jobId}');
    print('DEBUG JobApplicationDialog: Cover letter length: ${_coverLetterController.text.trim().length}');
    print('DEBUG JobApplicationDialog: CV file selected: ${_selectedCvFile != null || _selectedCvXFile != null}');

    final success = await ref.read(applicationProvider.notifier).submitApplication(
      jobId: widget.jobId,
      coverLetter: _coverLetterController.text.trim(),
      cvFile: _selectedCvFile,
      cvXFile: _selectedCvXFile,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ứng tuyển thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(applicationProvider).error;
        print('DEBUG JobApplicationDialog: Application failed with error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationState = ref.watch(applicationProvider);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ứng tuyển',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.jobTitle} - ${widget.companyName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Letter
                    AppTextField(
                      controller: _coverLetterController,
                      label: 'Thư xin việc *',
                      hintText: 'Viết thư giới thiệu bản thân và lý do ứng tuyển...',
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập thư xin việc';
                        }
                        if (value.trim().length < 50) {
                          return 'Thư xin việc phải có ít nhất 50 ký tự';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // CV File Upload
                    Text(
                      'Tải lên CV (PDF) *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    InkWell(
                      onTap: _pickCvFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedFileName != null
                                  ? Icons.picture_as_pdf
                                  : Icons.upload_file,
                              color: _selectedFileName != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFileName ?? 'Chọn file CV (PDF)',
                                style: TextStyle(
                                  color: _selectedFileName != null
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            if (_selectedFileName != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCvFile = null;
                                    _selectedCvXFile = null;
                                    _selectedFileName = null;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Chỉ chấp nhận file PDF, kích thước tối đa 10MB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: applicationState.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    onPressed: applicationState.isLoading ? null : _submitApplication,
                    isLoading: applicationState.isLoading,
                    text: 'Ứng tuyển',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
