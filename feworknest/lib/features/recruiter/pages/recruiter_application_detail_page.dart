import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../../../core/providers/recruiter_applicants_provider.dart';
import 'application_detail_page.dart';

class RecruiterApplicationDetailPage extends ConsumerStatefulWidget {
  final String applicationId;

  const RecruiterApplicationDetailPage({
    super.key,
    required this.applicationId,
  });

  @override
  ConsumerState<RecruiterApplicationDetailPage> createState() => _RecruiterApplicationDetailPageState();
}

class _RecruiterApplicationDetailPageState extends ConsumerState<RecruiterApplicationDetailPage> {
  ApplicationModel? _application;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('DEBUG RecruiterApplicationDetailPage: Loading application ID: ${widget.applicationId}');

      // Try to get from current loaded applicants first
      // final applicantsState = ref.read(recruiterApplicantsProvider);
      // final existingApplication = applicantsState.applicants
      //     .where((app) => app.id.toString() == widget.applicationId)
      //     .firstOrNull;

      // if (existingApplication != null) {
      //   print('DEBUG RecruiterApplicationDetailPage: Found application in state: ${existingApplication.applicantName}');
      //   setState(() {
      //     _application = existingApplication;
      //     _isLoading = false;
      //   });
      //   return;
      // }

      // print('DEBUG RecruiterApplicationDetailPage: Application not found in state, fetching from API');

      // If not found, load from API
      final applicationId = int.tryParse(widget.applicationId);
      if (applicationId == null) {
        print('DEBUG RecruiterApplicationDetailPage: Invalid application ID');
        setState(() {
          _error = 'ID ứng viên không hợp lệ';
          _isLoading = false;
        });
        return;
      }

      final application = await ref.read(recruiterApplicantsProvider.notifier)
          .getApplicationById(widget.applicationId);
      
      if (application != null) {
        print('DEBUG RecruiterApplicationDetailPage: Application loaded from API: ${application.applicantName}');
        print('DEBUG RecruiterApplicationDetailPage: Email: ${application.applicantEmail}');
        print('DEBUG RecruiterApplicationDetailPage: Avatar: ${application.avatarUrl}');
        setState(() {
          _application = application;
          _isLoading = false;
        });
      } else {
        print('DEBUG RecruiterApplicationDetailPage: Application not found');
        setState(() {
          _error = 'Không tìm thấy thông tin ứng viên';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG RecruiterApplicationDetailPage: Error loading application: $e');
      setState(() {
        _error = 'Lỗi khi tải thông tin ứng viên: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin ứng viên...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết ứng viên'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadApplication,
                child: const Text('Thử lại'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_application == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết ứng viên'),
        ),
        body: const Center(
          child: Text('Không tìm thấy thông tin ứng viên'),
        ),
      );
    }

    return ApplicationDetailPage(application: _application!);
  }
}
