import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/review_provider.dart';
import '../../../core/models/review_model.dart';
import '../widgets/review_form.dart';

class CompanyReviewScreen extends ConsumerWidget {
  static const String routeName = '/company-review';
  
  final int companyId;
  final String companyName;

  const CompanyReviewScreen({
    super.key,
    required this.companyId,
    required this.companyName,
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
              content: Text('Đánh giá của bạn đã được gửi thành công!'),
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
        title: const Text('Đánh giá công ty'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Company Logo placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        size: 30,
                        color: Colors.blue[700],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Company Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chia sẻ trải nghiệm của bạn về công ty này',
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
              title: 'Đánh giá công ty',
              targetName: companyName,
              submitButtonText: 'Gửi đánh giá',
              isLoading: reviewState.isLoading,
              onSubmit: (rating, comment) {
                final createReview = CreateCandidateReviewModel(
                  companyId: companyId,
                  rating: rating,
                  comment: comment,
                );
                reviewNotifier.createCandidateReview(createReview);
              },
            ),

            const SizedBox(height: 24),

            // Review Guidelines
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
                          Icons.warning_amber,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lưu ý quan trọng',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Đánh giá sẽ được công khai và có thể được nhà tuyển dụng xem\n'
                      '• Không được sử dụng ngôn từ xúc phạm hoặc không phù hợp\n'
                      '• Tập trung vào trải nghiệm thực tế về môi trường làm việc\n'
                      '• Đánh giá giúp các ứng viên khác có thêm thông tin tham khảo',
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
