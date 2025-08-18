import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/application_model.dart';
import '../services/interview_service.dart';

class ScheduleInterviewScreen extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const ScheduleInterviewScreen({
    super.key,
    required this.application,
  });

  @override
  ConsumerState<ScheduleInterviewScreen> createState() => _ScheduleInterviewScreenState();
}

class _ScheduleInterviewScreenState extends ConsumerState<ScheduleInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Phỏng vấn vị trí ${widget.application.jobTitle}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lên lịch phỏng vấn'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin ứng viên',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(widget.application.applicantName),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.work, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.application.jobTitle)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(widget.application.applicantEmail),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Interview Details Form
              Text(
                'Thông tin lịch phỏng vấn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề cuộc phỏng vấn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date & Time Picker
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDateTime != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!)
                              : 'Chọn ngày và giờ phỏng vấn',
                          style: TextStyle(
                            color: _selectedDateTime != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả cuộc phỏng vấn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Mô tả ngắn về cuộc phỏng vấn, yêu cầu chuẩn bị...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Meeting Link Field
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Link meeting (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_call),
                  hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Địa chỉ văn phòng hoặc "Online"',
                ),
              ),

              const SizedBox(height: 32),

              // Schedule Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _scheduleInterview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gửi lịch hẹn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Lưu ý',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Ứng viên sẽ nhận được thông báo qua email và app\n'
                        '• Hãy chọn thời gian phù hợp với cả hai bên\n'
                        '• Nếu phỏng vấn online, nhớ cung cấp link meeting\n'
                        '• Có thể thay đổi hoặc hủy lịch hẹn sau khi tạo',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _scheduleInterview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày và giờ phỏng vấn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian phỏng vấn phải sau thời điểm hiện tại'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final interviewService = InterviewService();
      
      final success = await interviewService.scheduleInterview(
        applicationId: widget.application.id,
        scheduledAt: _selectedDateTime!,
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        meetingLink: _meetingLinkController.text.isNotEmpty ? _meetingLinkController.text : null,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lịch hẹn phỏng vấn thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
