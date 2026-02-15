import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/application_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/saved_cv_provider.dart';
import '../../core/services/saved_cv_service.dart';
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

enum CVSelectionMode { fromFile, fromSavedCV }

class _JobApplicationDialogState extends ConsumerState<JobApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  
  File? _selectedCvFile;
  XFile? _selectedCvXFile;
  String? _selectedFileName;
  
  CVSelectionMode _cvSelectionMode = CVSelectionMode.fromFile;
  SavedCVFromAnalysis? _selectedSavedCV;

  @override
  void initState() {
    super.initState();
    // Load saved CVs when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedCVProvider.notifier).loadSavedCVs();
    });
  }

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
    
    // Validate CV selection based on mode
    if (_cvSelectionMode == CVSelectionMode.fromFile) {
      if (_selectedCvFile == null && _selectedCvXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn file CV (PDF)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_selectedSavedCV == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn CV đã lưu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Debug: Check auth state before submission
    final authState = ref.read(authProvider);
    debugPrint('DEBUG JobApplicationDialog: Auth state check');
    debugPrint('DEBUG JobApplicationDialog: Is authenticated: ${authState.isAuthenticated}');
    debugPrint('DEBUG JobApplicationDialog: User: ${authState.user?.email}');
    debugPrint('DEBUG JobApplicationDialog: Has accessToken: ${authState.accessToken != null}');
    if (authState.accessToken != null) {
      debugPrint('DEBUG JobApplicationDialog: AccessToken preview: ${authState.accessToken!.substring(0, 20)}...');
    }

    debugPrint('DEBUG JobApplicationDialog: Starting application submission');
    debugPrint('DEBUG JobApplicationDialog: JobId: ${widget.jobId}');
    debugPrint('DEBUG JobApplicationDialog: Cover letter length: ${_coverLetterController.text.trim().length}');
    debugPrint('DEBUG JobApplicationDialog: CV selection mode: $_cvSelectionMode');
    
    bool success;
    
    if (_cvSelectionMode == CVSelectionMode.fromFile) {
      debugPrint('DEBUG JobApplicationDialog: CV file selected: ${_selectedCvFile != null || _selectedCvXFile != null}');
      success = await ref.read(applicationProvider.notifier).submitApplication(
        jobId: widget.jobId,
        coverLetter: _coverLetterController.text.trim(),
        cvFile: _selectedCvFile,
        cvXFile: _selectedCvXFile,
      );
    } else {
      debugPrint('DEBUG JobApplicationDialog: Saved CV selected: ${_selectedSavedCV?.fileName}');
      // Submit with saved CV URL
      success = await ref.read(applicationProvider.notifier).submitApplicationWithSavedCV(
        jobId: widget.jobId,
        coverLetter: _coverLetterController.text.trim(),
        savedCVUrl: _selectedSavedCV!.cvUrl,
        savedCVFileName: _selectedSavedCV!.fileName,
      );
      
      // Mark CV as used if submission successful
      if (success) {
        await ref.read(savedCVProvider.notifier).markCVAsUsed(_selectedSavedCV!.id);
      }
    }

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
        debugPrint('DEBUG JobApplicationDialog: Application failed with error: $error');
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700), // Increased from 600 to 700
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Letter
                      AppTextField(
                        controller: _coverLetterController,
                        label: 'Thư xin việc *',
                        hintText: 'Viết thư giới thiệu bản thân và lý do ứng tuyển...',
                        maxLines: 4, // Reduced from 6 to save space
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

                    // CV Selection Tabs
                    Text(
                      'Chọn CV *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Tab Selection
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Tab Headers
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _cvSelectionMode = CVSelectionMode.fromSavedCV;
                                      // Clear file selection when switching to saved CV
                                      _selectedCvFile = null;
                                      _selectedCvXFile = null;
                                      _selectedFileName = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _cvSelectionMode == CVSelectionMode.fromSavedCV
                                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(7),
                                        bottomLeft: _cvSelectionMode == CVSelectionMode.fromSavedCV
                                            ? Radius.zero
                                            : const Radius.circular(7),
                                      ),
                                    ),
                                    child: Text(
                                      'CV đã lưu',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _cvSelectionMode == CVSelectionMode.fromSavedCV
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                        fontWeight: _cvSelectionMode == CVSelectionMode.fromSavedCV
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _cvSelectionMode = CVSelectionMode.fromFile;
                                      // Clear saved CV selection when switching to file upload
                                      _selectedSavedCV = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _cvSelectionMode == CVSelectionMode.fromFile
                                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.only(
                                        topRight: const Radius.circular(7),
                                        bottomRight: _cvSelectionMode == CVSelectionMode.fromFile
                                            ? Radius.zero
                                            : const Radius.circular(7),
                                      ),
                                    ),
                                    child: Text(
                                      'Tải từ máy tính',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _cvSelectionMode == CVSelectionMode.fromFile
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                        fontWeight: _cvSelectionMode == CVSelectionMode.fromFile
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Tab Content
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: _cvSelectionMode == CVSelectionMode.fromSavedCV
                                ? _buildSavedCVSelection()
                                : _buildFileUploadSelection(),
                          ),
                        ],
                      ),
                    ),
                  ], // End of Column children inside SingleChildScrollView
                ), // End of Column
              ), // End of SingleChildScrollView
            ), // End of Form
          ), // End of Expanded

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

  /// Build saved CV selection widget
  Widget _buildSavedCVSelection() {
    final savedCVState = ref.watch(savedCVProvider);
    
    if (savedCVState.isLoadingSavedCVs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final availableCVs = savedCVState.savedCVs.where((cv) => cv.cvUrl.isNotEmpty).toList();
    
    if (availableCVs.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có CV nào được lưu',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy phân tích CV để lưu vào danh sách',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn CV từ danh sách đã lưu (${availableCVs.length})',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 150), // Reduced from 200 to 150
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCVs.length,
            itemBuilder: (context, index) {
              final cv = availableCVs[index];
              final isSelected = _selectedSavedCV?.id == cv.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSavedCV = cv;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.red[400],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cv.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cv.overallScore}/100',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cv.analyzedAt.day}/${cv.analyzedAt.month}/${cv.analyzedAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build file upload selection widget
  Widget _buildFileUploadSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickCvFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
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
    );
  }
}
