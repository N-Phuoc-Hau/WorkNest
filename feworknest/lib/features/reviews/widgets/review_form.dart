import 'package:flutter/material.dart';

class ReviewForm extends StatefulWidget {
  final Function(int rating, String? comment) onSubmit;
  final bool isLoading;
  final String title;
  final String submitButtonText;
  final String? targetName; // Company name or candidate name

  const ReviewForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.title = 'Viết đánh giá',
    this.submitButtonText = 'Gửi đánh giá',
    this.targetName,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          if (widget.targetName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Đánh giá cho: ${widget.targetName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Rating Section
          Text(
            'Đánh giá *',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = starIndex;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: starIndex <= _rating ? Colors.amber : Colors.grey[400],
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // Rating Text
          Center(
            child: Text(
              _getRatingText(_rating),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _getRatingColor(_rating),
              ),
            ),
          ),

          if (_rating == 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Vui lòng chọn số sao đánh giá',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Comment Section
          Text(
            'Nhận xét',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Nhận xét phải có ít nhất 10 ký tự';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (widget.isLoading || _rating == 0) ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.submitButtonText,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hướng dẫn viết đánh giá',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Đánh giá trung thực và khách quan\n'
                  '• Chia sẻ trải nghiệm cụ thể\n'
                  '• Tránh sử dụng ngôn ngữ không phù hợp\n'
                  '• Tập trung vào nội dung công việc',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất kém';
      case 2:
        return 'Kém';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Rất tốt';
      default:
        return 'Chưa đánh giá';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _submitReview() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final comment = _commentController.text.trim();
    widget.onSubmit(_rating, comment.isNotEmpty ? comment : null);
  }
}
