import 'package:flutter/material.dart';

import '../../../core/models/job_model.dart';
import '../../../shared/widgets/app_text_field.dart';

class JobForm extends StatefulWidget {
  final JobModel? initialJob;
  final Function(CreateJobModel) onCreateJob;
  final Function(UpdateJobModel)? onUpdateJob;
  final bool isLoading;

  const JobForm({
    super.key,
    this.initialJob,
    required this.onCreateJob,
    this.onUpdateJob,
    this.isLoading = false,
  });

  @override
  State<JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _specializedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _workingHoursController = TextEditingController();
  
  String? _selectedJobType;
  
  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Remote',
    'Hybrid',
  ];

  final List<String> _specializedOptions = [
    'Công nghệ thông tin',
    'Marketing',
    'Kinh doanh',
    'Nhân sự',
    'Tài chính - Kế toán',
    'Thiết kế',
    'Giáo dục',
    'Y tế',
    'Xây dựng',
    'Du lịch - Khách sạn',
    'Luật',
    'Kỹ thuật',
    'Bán lẻ',
    'Logistics',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialJob != null) {
      _populateForm(widget.initialJob!);
    }
  }

  void _populateForm(JobModel job) {
    _titleController.text = job.title;
    _specializedController.text = job.specialized;
    _descriptionController.text = job.description;
    _requirementsController.text = job.requirements;
    _benefitsController.text = job.benefits;
    _locationController.text = job.location;
    _salaryController.text = job.salary.toString();
    _workingHoursController.text = job.workingHours;
    _selectedJobType = job.jobType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specializedController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title
          AppTextField(
            controller: _titleController,
            label: 'Tiêu đề công việc *',
            hintText: 'VD: Senior Flutter Developer',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tiêu đề công việc';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),

          // Specialized Field
          AppTextField(
            controller: _specializedController,
            label: 'Lĩnh vực chuyên môn *',
            hintText: 'Chọn hoặc nhập lĩnh vực',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng chọn lĩnh vực chuyên môn';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 8),
          
          // Specialized Chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _specializedOptions.map((option) {
              final isSelected = _specializedController.text == option;
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _specializedController.text = selected ? option : '';
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Job Description
          AppTextField(
            controller: _descriptionController,
            label: 'Mô tả công việc *',
            hintText: 'Mô tả chi tiết về công việc và trách nhiệm...',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mô tả công việc';
              }
              if (value.trim().length < 50) {
                return 'Mô tả công việc phải có ít nhất 50 ký tự';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Requirements
          AppTextField(
            controller: _requirementsController,
            label: 'Yêu cầu công việc *',
            hintText: 'Kinh nghiệm, kỹ năng, bằng cấp yêu cầu...',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập yêu cầu công việc';
              }
              if (value.trim().length < 20) {
                return 'Yêu cầu công việc phải có ít nhất 20 ký tự';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Benefits
          AppTextField(
            controller: _benefitsController,
            label: 'Quyền lợi và phúc lợi *',
            hintText: 'Lương thưởng, bảo hiểm, nghỉ phép, đào tạo...',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập quyền lợi và phúc lợi';
              }
              if (value.trim().length < 20) {
                return 'Quyền lợi phải có ít nhất 20 ký tự';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Location
          AppTextField(
            controller: _locationController,
            label: 'Địa điểm làm việc *',
            hintText: 'VD: Hồ Chí Minh, Hà Nội, Remote',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập địa điểm làm việc';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Salary
          AppTextField(
            controller: _salaryController,
            label: 'Mức lương (USD) *',
            hintText: 'VD: 1000',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mức lương';
              }
              final salary = double.tryParse(value);
              if (salary == null || salary <= 0) {
                return 'Mức lương không hợp lệ';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Working Hours
          AppTextField(
            controller: _workingHoursController,
            label: 'Giờ làm việc *',
            hintText: 'VD: 8:00 - 17:00, Thứ 2 - Thứ 6',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập giờ làm việc';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Job Type
          Text(
            'Loại hình công việc',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<String>(
            value: _selectedJobType,
            hint: const Text('Chọn loại hình công việc'),
            items: _jobTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedJobType = value;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.initialJob != null ? 'Cập nhật' : 'Đăng tin',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final salary = double.parse(_salaryController.text);

    if (widget.initialJob != null) {
      // Update existing job
      final updateJob = UpdateJobModel(
        title: _titleController.text.trim(),
        specialized: _specializedController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        benefits: _benefitsController.text.trim(),
        location: _locationController.text.trim(),
        salary: salary,
        workingHours: _workingHoursController.text.trim(),
        jobType: _selectedJobType,
      );
      widget.onUpdateJob?.call(updateJob);
    } else {
      // Create new job
      final createJob = CreateJobModel(
        title: _titleController.text.trim(),
        specialized: _specializedController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: _requirementsController.text.trim(),
        benefits: _benefitsController.text.trim(),
        location: _locationController.text.trim(),
        salary: salary,
        workingHours: _workingHoursController.text.trim(),
        jobType: _selectedJobType,
      );
      widget.onCreateJob(createJob);
    }
  }
}
