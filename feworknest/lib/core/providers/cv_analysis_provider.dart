import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cv_analysis_models.dart';
import '../services/api_service.dart';
import '../services/cv_analysis_service.dart';
import '../utils/cross_platform_file.dart';

// State classes cho CV Analysis
class CVAnalysisState {
  final bool isLoading;
  final bool isAnalyzing;
  final CVAnalysisResponse? currentAnalysis;
  final CVAnalysisResponse? analysisResult; // Alias for compatibility
  final List<CVAnalysisHistory> history;
  final CVAnalysisStats? stats;
  final String? error;

  const CVAnalysisState({
    this.isLoading = false,
    this.isAnalyzing = false,
    this.currentAnalysis,
    this.history = const [],
    this.stats,
    this.error,
  }) : analysisResult = currentAnalysis;

  CVAnalysisState copyWith({
    bool? isLoading,
    bool? isAnalyzing,
    CVAnalysisResponse? currentAnalysis,
    CVAnalysisResponse? analysisResult,
    List<CVAnalysisHistory>? history,
    CVAnalysisStats? stats,
    String? error,
  }) {
    return CVAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      currentAnalysis: currentAnalysis ?? analysisResult ?? this.currentAnalysis,
      history: history ?? this.history,
      stats: stats ?? this.stats,
      error: error,
    );
  }
}

class CVAnalysisNotifier extends StateNotifier<CVAnalysisState> {
  final CVAnalysisService _cvAnalysisService;

  CVAnalysisNotifier(this._cvAnalysisService) : super(const CVAnalysisState());

  /// Analyze CV from file
  Future<void> analyzeCVFromFile(CrossPlatformFile file) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final analysisResult = await _cvAnalysisService.analyzeCVFromFile(file);
      
      state = state.copyWith(
        currentAnalysis: analysisResult,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Analyze CV from text
  Future<void> analyzeCVFromText(String cvText) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final analysisResult = await _cvAnalysisService.analyzeCVFromText(cvText);
      
      state = state.copyWith(
        currentAnalysis: analysisResult,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get CV analysis history
  Future<void> getAnalysisHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final historyData = await _cvAnalysisService.getAnalysisHistory();
      
      state = state.copyWith(
        history: historyData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get job recommendations based on current analysis
  Future<void> getJobRecommendations() async {
    if (state.currentAnalysis == null) {
      state = state.copyWith(error: 'Vui lòng phân tích CV trước');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final recommendations = await _cvAnalysisService.getJobRecommendations();
      
      // Update current analysis with new recommendations
      final updatedAnalysis = CVAnalysisResponse(
        analysisId: state.currentAnalysis!.analysisId,
        userId: state.currentAnalysis!.userId,
        profile: state.currentAnalysis!.profile,
        scores: state.currentAnalysis!.scores,
        strengths: state.currentAnalysis!.strengths,
        weaknesses: state.currentAnalysis!.weaknesses,
        improvementSuggestions: state.currentAnalysis!.improvementSuggestions,
        recommendedJobs: recommendations,
        detailedAnalysis: state.currentAnalysis!.detailedAnalysis,
        analyzedAt: state.currentAnalysis!.analyzedAt,
      );

      state = state.copyWith(
        currentAnalysis: updatedAnalysis,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear the current analysis result
  void clearAnalysis() {
    state = state.copyWith(currentAnalysis: null, error: null);
  }

  /// Get CV analysis for an application (recruiter feature)
  Future<void> getCVAnalysis(int applicationId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint('Getting CV analysis for application: $applicationId');
      // This would be an API call to get analysis for specific application
      // For now, return empty state
      state = state.copyWith(isLoading: false, currentAnalysis: null);
    } catch (e) {
      debugPrint('Error getting CV analysis: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Request CV analysis for an application (recruiter feature)
  Future<bool> requestCVAnalysis(int applicationId) async {
    state = state.copyWith(isAnalyzing: true, error: null);
    
    try {
      debugPrint('Requesting CV analysis for application: $applicationId');
      // This would be an API call to trigger analysis for specific application
      // For now, simulate success
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isAnalyzing: false);
      return true;
    } catch (e) {
      debugPrint('Error requesting CV analysis: $e');
      state = state.copyWith(isAnalyzing: false, error: e.toString());
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final cvAnalysisServiceProvider = Provider<CVAnalysisService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return CVAnalysisService(apiService);
});

final cvAnalysisProvider = StateNotifierProvider<CVAnalysisNotifier, CVAnalysisState>((ref) {
  return CVAnalysisNotifier(ref.watch(cvAnalysisServiceProvider));
});
