import 'package:flutter/material.dart';

import '../../../core/models/review_model.dart';

class ReviewStats extends StatelessWidget {
  final List<ReviewModel> reviews;

  const ReviewStats({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final averageRating = _calculateAverageRating();
    final ratingCounts = _calculateRatingCounts();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê đánh giá',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Average Rating Display
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRatingStars(averageRating),
                      const SizedBox(height: 8),
                      Text(
                        '${reviews.length} đánh giá',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Rating Breakdown
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      for (int i = 5; i >= 1; i--)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _buildRatingBar(context, i, ratingCounts[i] ?? 0, reviews.length),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageRating() {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold(0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  Map<int, int> _calculateRatingCounts() {
    final counts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      counts[i] = 0;
    }
    
    for (final review in reviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
    }
    
    return counts;
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 20, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 20, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 20, color: Colors.grey);
        }
      }),
    );
  }

  Widget _buildRatingBar(BuildContext context, int rating, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Row(
      children: [
        Text(
          '$rating',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
