import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/cv_analysis_model.dart';
import '../../../core/providers/cv_analysis_provider.dart';

class MatchScoreWidget extends ConsumerWidget {
  final int applicationId;
  final bool isCompact;
  final VoidCallback? onTap;

  const MatchScoreWidget({
    super.key,
    required this.applicationId,
    this.isCompact = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(cvAnalysisProvider);
    
    // Check if we have analysis for this specific application
    final hasAnalysis = analysisState.analysisResult?.applicationId == applicationId;
    
    if (!hasAnalysis) {
      return _buildNoAnalysisWidget(context);
    }

    final result = analysisState.analysisResult!;
    
    if (isCompact) {
      return _buildCompactWidget(context, result);
    } else {
      return _buildFullWidget(context, result);
    }
  }

  Widget _buildNoAnalysisWidget(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Chưa phân tích',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWidget(BuildContext context, CVAnalysisResult result) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: result.matchScoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: result.matchScoreColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: result.matchScoreColor,
              ),
              child: Center(
                child: Text(
                  '${result.matchScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${result.matchScore}%',
              style: TextStyle(
                color: result.matchScoreColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidget(BuildContext context, CVAnalysisResult result) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              result.matchScoreColor.withOpacity(0.1),
              result.matchScoreColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: result.matchScoreColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: result.matchScoreColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '${result.matchScore}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.matchScoreColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Độ phù hợp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    result.matchScoreText,
                    style: TextStyle(
                      color: result.matchScoreColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: result.matchScoreColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class MatchScoreProvider {
  static Widget buildPlaceholder({
    bool isCompact = true,
    VoidCallback? onRequestAnalysis,
  }) {
    return GestureDetector(
      onTap: onRequestAnalysis,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: isCompact ? 12 : 16,
              color: Colors.blue[600],
            ),
            const SizedBox(width: 4),
            Text(
              isCompact ? 'Phân tích' : 'Phân tích CV',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLoading({bool isCompact = true}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isCompact ? 12 : 16,
            height: isCompact ? 12 : 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isCompact ? 'Đang phân tích...' : 'Đang phân tích CV...',
            style: TextStyle(
              color: Colors.orange[600],
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
