import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_posting_provider.dart';
import '../widgets/job_form.dart';

class CreateJobScreen extends ConsumerWidget {
  static const String routeName = '/create-job';

  const CreateJobScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobPostingState = ref.watch(jobPostingProvider);
    final jobPostingNotifier = ref.read(jobPostingProvider.notifier);

    ref.listen(jobPostingProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error == null) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng tin tuyển dụng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${next.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin tuyển dụng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tạo tin tuyển dụng mới',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Điền đầy đủ thông tin để tạo tin tuyển dụng hấp dẫn và thu hút ứng viên phù hợp.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Job Form
            JobForm(
              onCreateJob: (createJobModel) {
                jobPostingNotifier.createJob(createJobModel);
              },
              isLoading: jobPostingState.isLoading,
            ),

            const SizedBox(height: 24),

            // Tips Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mẹo viết tin tuyển dụng hiệu quả',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTip('• Viết tiêu đề rõ ràng, cụ thể về vị trí tuyển dụng'),
                        _buildTip('• Mô tả chi tiết về trách nhiệm công việc'),
                        _buildTip('• Nêu rõ yêu cầu về kỹ năng và kinh nghiệm'),
                        _buildTip('• Đề cập đến quyền lợi và lợi ích của công ty'),
                        _buildTip('• Sử dụng từ ngữ tích cực và chuyên nghiệp'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
