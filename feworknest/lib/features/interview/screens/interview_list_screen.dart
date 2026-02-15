import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/interview_model.dart';
import '../../../core/services/interview_service.dart';

class InterviewListScreen extends ConsumerStatefulWidget {
  const InterviewListScreen({super.key});

  @override
  ConsumerState<InterviewListScreen> createState() => _InterviewListScreenState();
}

class _InterviewListScreenState extends ConsumerState<InterviewListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InterviewModel> _upcomingInterviews = [];
  List<InterviewModel> _pastInterviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInterviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInterviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interviewService = InterviewService();
      final interviews = await interviewService.getMyInterviews();
      
      setState(() {
        _upcomingInterviews = interviews.where((interview) => interview.isUpcoming).toList();
        _pastInterviews = interviews.where((interview) => interview.isPast).toList();
        
        // Sort by date
        _upcomingInterviews.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _pastInterviews.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách phỏng vấn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch phỏng vấn'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Sắp tới (${_upcomingInterviews.length})',
            ),
            Tab(
              text: 'Đã qua (${_pastInterviews.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInterviewList(_upcomingInterviews, isUpcoming: true),
                _buildInterviewList(_pastInterviews, isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildInterviewList(List<InterviewModel> interviews, {required bool isUpcoming}) {
    if (interviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming 
                  ? 'Chưa có lịch phỏng vấn nào sắp tới'
                  : 'Chưa có lịch phỏng vấn nào trong quá khứ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInterviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: interviews.length,
        itemBuilder: (context, index) {
          final interview = interviews[index];
          return _buildInterviewCard(interview, isUpcoming: isUpcoming);
        },
      ),
    );
  }

  Widget _buildInterviewCard(InterviewModel interview, {required bool isUpcoming}) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(interview.scheduledAt) == 
                   DateFormat('yyyy-MM-dd').format(now);
    final isWithinHour = interview.scheduledAt.difference(now).inMinutes.abs() <= 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showInterviewDetails(interview),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      interview.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(interview.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(interview.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interview.statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(interview.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isToday ? Colors.orange : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy • HH:mm', 'vi').format(interview.scheduledAt),
                    style: TextStyle(
                      color: isToday ? Colors.orange : Colors.grey[600],
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isToday && isUpcoming) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Hôm nay',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Candidate/Company info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      interview.candidateName ?? 'Ứng viên',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              if (interview.jobTitle != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.work, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(interview.jobTitle!)),
                  ],
                ),
              ],

              if (interview.location != null || interview.meetingLink != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      interview.meetingLink != null ? Icons.video_call : Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        interview.meetingLink != null 
                            ? 'Phỏng vấn online'
                            : interview.location!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],

              // Quick actions for upcoming interviews
              if (isUpcoming && interview.status == InterviewStatus.scheduled) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (interview.meetingLink != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _joinMeeting(interview.meetingLink!),
                          icon: const Icon(Icons.video_call, size: 16),
                          label: const Text('Tham gia'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (interview.meetingLink != null) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateInterviewStatus(interview),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Cập nhật'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Urgent indicator for interviews starting soon
              if (isUpcoming && isWithinHour && interview.status == InterviewStatus.scheduled) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Cuộc phỏng vấn sắp bắt đầu!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InterviewStatus status) {
    switch (status) {
      case InterviewStatus.scheduled:
        return Colors.blue;
      case InterviewStatus.completed:
        return Colors.green;
      case InterviewStatus.cancelled:
        return Colors.red;
      case InterviewStatus.rescheduled:
        return Colors.orange;
    }
  }

  void _showInterviewDetails(InterviewModel interview) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildInterviewDetailsSheet(interview),
    );
  }

  Widget _buildInterviewDetailsSheet(InterviewModel interview) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                interview.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Details content here...
                      _buildDetailItem('Thời gian', 
                        DateFormat('EEEE, dd/MM/yyyy • HH:mm', 'vi').format(interview.scheduledAt)),
                      
                      if (interview.candidateName != null)
                        _buildDetailItem('Ứng viên', interview.candidateName!),
                      
                      if (interview.jobTitle != null)
                        _buildDetailItem('Vị trí', interview.jobTitle!),
                      
                      if (interview.description != null)
                        _buildDetailItem('Mô tả', interview.description!),
                      
                      if (interview.location != null)
                        _buildDetailItem('Địa điểm', interview.location!),
                      
                      if (interview.meetingLink != null)
                        _buildDetailItem('Link meeting', interview.meetingLink!, 
                          isLink: true),
                      
                      _buildDetailItem('Trạng thái', interview.statusDisplayText),
                      
                      if (interview.notes != null)
                        _buildDetailItem('Ghi chú', interview.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          isLink
              ? InkWell(
                  onTap: () => _joinMeeting(value),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(value),
        ],
      ),
    );
  }

  void _joinMeeting(String meetingLink) {
    // Handle meeting link opening
    // You can use url_launcher here
  }

  void _updateInterviewStatus(InterviewModel interview) {
    // Show dialog to update interview status
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: const Text('Chức năng cập nhật trạng thái phỏng vấn'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
