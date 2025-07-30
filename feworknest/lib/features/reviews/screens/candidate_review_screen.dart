import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/models/review_model.dart';
import '../widgets/review_form.dart';

class CandidateReviewScreen extends ConsumerWidget {
  static const String routeName = '/candidate-review';
  
  final String candidateId;
  final String candidateName;

  const CandidateReviewScreen({
    super.key,
    required this.candidateId,
    required this.candidateName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewProvider);
    final reviewNotifier = ref.read(reviewProvider.notifier);

    ref.listen(reviewProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error == null) {
          // Success - show snackbar and go back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đánh giá ứng viên đã được gửi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          // Error - show error snackbar
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
        title: const Text('Đánh giá ứng viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Candidate Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Candidate Avatar placeholder
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green[100],
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.green[700],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Candidate Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidateName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đánh giá hiệu suất và thái độ làm việc của ứng viên',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Review Form
            ReviewForm(
              title: 'Đánh giá ứng viên',
              targetName: candidateName,
              submitButtonText: 'Gửi đánh giá',
              isLoading: reviewState.isLoading,
              onSubmit: (rating, comment) {
                final createReview = CreateRecruiterReviewModel(
                  candidateId: candidateId,
                  rating: rating,
                  comment: comment,
                );
                reviewNotifier.createRecruiterReview(createReview);
              },
            ),

            const SizedBox(height: 24),

            // Review Categories (Optional enhancement)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tiêu chí đánh giá',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Kỹ năng chuyên môn và kinh nghiệm\n'
                      '• Thái độ làm việc và tinh thần trách nhiệm\n'
                      '• Khả năng giao tiếp và làm việc nhóm\n'
                      '• Sự chủ động và khả năng học hỏi\n'
                      '• Tính đúng giờ và tuân thủ quy định',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Guidelines
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lưu ý về đánh giá',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Đánh giá khách quan và công bằng\n'
                      '• Dựa trên hiệu suất công việc thực tế\n'
                      '• Tránh đánh giá dựa trên yếu tố cá nhân\n'
                      '• Đánh giá sẽ giúp ứng viên cải thiện bản thân',
                      style: TextStyle(fontSize: 14, height: 1.4),
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
}
