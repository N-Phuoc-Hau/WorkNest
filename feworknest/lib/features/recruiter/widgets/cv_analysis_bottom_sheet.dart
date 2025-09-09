import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/application_model.dart';
import '../../../core/models/cv_analysis_models.dart';
import '../../../core/providers/cv_analysis_provider.dart';

class CVAnalysisBottomSheet extends ConsumerStatefulWidget {
  final ApplicationModel application;

  const CVAnalysisBottomSheet({
    super.key,
    required this.application,
  });

  @override
  ConsumerState<CVAnalysisBottomSheet> createState() => _CVAnalysisBottomSheetState();
}

class _CVAnalysisBottomSheetState extends ConsumerState<CVAnalysisBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Load CV analysis when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cvAnalysisProvider.notifier).getCVAnalysis(widget.application.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(cvAnalysisProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Content
          Expanded(
            child: _buildContent(analysisState),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 24,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân tích CV',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.application.applicantName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CVAnalysisState analysisState) {
    if (analysisState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải phân tích CV...'),
          ],
        ),
      );
    }

    if (analysisState.isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang phân tích CV...'),
            SizedBox(height: 8),
            Text(
              'Quá trình này có thể mất vài phút',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (analysisState.error != null) {
      return _buildErrorState(analysisState.error!);
    }

    if (analysisState.analysisResult == null) {
      return _buildNoAnalysisState();
    }

    return _buildAnalysisResult(analysisState.analysisResult!);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Lỗi khi phân tích CV',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(cvAnalysisProvider.notifier).getCVAnalysis(widget.application.id);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAnalysisState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'CV chưa được phân tích',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn nút bên dưới để bắt đầu phân tích CV của ứng viên',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(cvAnalysisProvider.notifier).requestCVAnalysis(widget.application.id);
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Phân tích CV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(CVAnalysisResponse result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Score Card
          _buildMatchScoreCard(result),
          
          const SizedBox(height: 20),
          
          // Skills Section
          _buildSkillsSection(result),
          
          const SizedBox(height: 20),
          
          // Strengths Section
          _buildStrengthsSection(result),
          
          const SizedBox(height: 20),
          
          // Weaknesses Section
          _buildWeaknessesSection(result),
          
          const SizedBox(height: 20),
          
          // Improvement Suggestions
          _buildImprovementSection(result),
          
          const SizedBox(height: 20),
          
          // Detailed Analysis
          _buildDetailedAnalysisSection(result),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMatchScoreCard(CVAnalysisResponse result) {
    final matchScore = result.scores.overallScore;
    final matchScoreColor = _getScoreColor(matchScore);
    final matchScoreText = _getScoreText(matchScore);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            matchScoreColor.withOpacity(0.1),
            matchScoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: matchScoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Độ phù hợp tổng thể',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: matchScoreColor, width: 8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$matchScore%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: matchScoreColor,
                    ),
                  ),
                  Text(
                    matchScoreText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: matchScoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phân tích vào ${_formatDate(result.analyzedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(CVAnalysisResponse result) {
    if (result.profile.skills.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Kỹ năng được trích xuất',
      icon: Icons.build_outlined,
      color: Colors.blue,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.profile.skills.map((skill) => Chip(
          label: Text(skill),
          backgroundColor: Colors.blue[50],
          side: BorderSide(color: Colors.blue[200]!),
        )).toList(),
      ),
    );
  }

  Widget _buildStrengthsSection(CVAnalysisResponse result) {
    if (result.strengths.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Điểm mạnh',
      icon: Icons.thumb_up_outlined,
      color: Colors.green,
      child: Column(
        children: result.strengths.map((strength) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(strength)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWeaknessesSection(CVAnalysisResponse result) {
    if (result.weaknesses.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Điểm cần cải thiện',
      icon: Icons.warning_outlined,
      color: Colors.orange,
      child: Column(
        children: result.weaknesses.map((weakness) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(weakness)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildImprovementSection(CVAnalysisResponse result) {
    if (result.improvementSuggestions.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Gợi ý cải thiện',
      icon: Icons.lightbulb_outlined,
      color: Colors.purple,
      child: Column(
        children: result.improvementSuggestions.map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(suggestion)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDetailedAnalysisSection(CVAnalysisResponse result) {
    if (result.detailedAnalysis.isEmpty) return const SizedBox.shrink();
    
    return _buildSection(
      title: 'Phân tích chi tiết',
      icon: Icons.description_outlined,
      color: Colors.indigo,
      child: Text(
        result.detailedAnalysis,
        style: const TextStyle(height: 1.5),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF4CAF50); // Green
    if (score >= 80) return const Color(0xFF8BC34A); // Light Green
    if (score >= 70) return const Color(0xFFFFC107); // Amber
    if (score >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String _getScoreText(int score) {
    if (score >= 90) return 'Rất phù hợp';
    if (score >= 80) return 'Phù hợp';
    if (score >= 70) return 'Khá phù hợp';
    if (score >= 60) return 'Trung bình';
    return 'Ít phù hợp';
  }
}
