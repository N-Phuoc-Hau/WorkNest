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
  final bool isRequestingAnalysis;
  final bool isLoadingHistory;
  final bool isLoadingStats;
  final CVAnalysisResponse? currentAnalysis;
  final List<CVAnalysisHistory> history;
  final CVAnalysisStats? stats;
  final String? error;

  const CVAnalysisState({
    this.isLoading = false,
    this.isAnalyzing = false,
    this.isRequestingAnalysis = false,
    this.isLoadingHistory = false,
    this.isLoadingStats = false,
    this.currentAnalysis,
    this.history = const [],
    this.stats,
    this.error,
  });

  // Alias for backward compatibility
  CVAnalysisResponse? get analysisResult => currentAnalysis;

  CVAnalysisState copyWith({
    bool? isLoading,
    bool? isAnalyzing,
    bool? isRequestingAnalysis,
    bool? isLoadingHistory,
    bool? isLoadingStats,
    CVAnalysisResponse? currentAnalysis,
    List<CVAnalysisHistory>? history,
    CVAnalysisStats? stats,
    String? error,
    bool clearCurrentAnalysis = false,
    bool clearError = false,
  }) {
    return CVAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isRequestingAnalysis: isRequestingAnalysis ?? this.isRequestingAnalysis,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      currentAnalysis: clearCurrentAnalysis ? null : (currentAnalysis ?? this.currentAnalysis),
      history: history ?? this.history,
      stats: stats ?? this.stats,
      error: clearError ? null : error,
    );
  }
}

class CVAnalysisNotifier extends StateNotifier<CVAnalysisState> {
  final CVAnalysisService _cvAnalysisService;

  CVAnalysisNotifier(this._cvAnalysisService) : super(const CVAnalysisState());

  /// Analyze CV from file
  Future<void> analyzeCVFromFile(CrossPlatformFile file) async {
    state = state.copyWith(isAnalyzing: true, clearError: true);

    try {
      final analysisResult = await _cvAnalysisService.analyzeCVFromFile(file);
      
      state = state.copyWith(
        currentAnalysis: analysisResult,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  /// Analyze CV from text
  Future<void> analyzeCVFromText(String cvText) async {
    state = state.copyWith(isAnalyzing: true, clearError: true);

    try {
      final analysisResult = await _cvAnalysisService.analyzeCVFromText(cvText);
      
      state = state.copyWith(
        currentAnalysis: analysisResult,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  /// Get CV analysis history
  Future<void> getAnalysisHistory() async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);

    try {
      final historyData = await _cvAnalysisService.getAnalysisHistory();
      
      state = state.copyWith(
        history: historyData,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: e.toString(),
      );
    }
  }

  /// Get CV analysis stats
  Future<void> getAnalysisStats() async {
    state = state.copyWith(isLoadingStats: true, clearError: true);

    try {
      final statsData = await _cvAnalysisService.getAnalysisStats();
      
      state = state.copyWith(
        stats: statsData,
        isLoadingStats: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStats: false,
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

    state = state.copyWith(isLoading: true, clearError: true);

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
    state = state.copyWith(clearCurrentAnalysis: true, clearError: true);
  }

  /// Get analysis detail by ID
  Future<void> getAnalysisDetail(String analysisId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final detail = await _cvAnalysisService.getAnalysisDetail(analysisId);
      
      state = state.copyWith(
        currentAnalysis: detail,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get CV analysis for an application (recruiter feature)
  Future<void> getCVAnalysis(int applicationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      debugPrint('Getting CV analysis for application: $applicationId');
      final analysis = await _cvAnalysisService.getCVAnalysisForApplication(applicationId);
      
      if (analysis != null) {
        // Analysis found
        state = state.copyWith(
          isLoading: false, 
          currentAnalysis: analysis,
        );
      } else {
        // No analysis available yet
        state = state.copyWith(
          isLoading: false, 
          currentAnalysis: null,
          error: 'Phân tích CV chưa sẵn sàng. Vui lòng yêu cầu phân tích.',
        );
      }
    } catch (e) {
      debugPrint('Error getting CV analysis: $e');
      state = state.copyWith(
        isLoading: false, 
        error: 'Lỗi khi tải phân tích CV: $e',
        currentAnalysis: null,
      );
    }
  }

  /// Request CV analysis for an application (recruiter feature)
  Future<bool> requestCVAnalysis(int applicationId) async {
    state = state.copyWith(isAnalyzing: true, clearError: true);
    
    try {
      debugPrint('Requesting CV analysis for application: $applicationId');
      final success = await _cvAnalysisService.triggerCVAnalysisForApplication(applicationId);
      
      if (success) {
        // After triggering analysis, wait a bit and then try to get the result
        await Future.delayed(const Duration(seconds: 3));
        await getCVAnalysis(applicationId);
      } else {
        state = state.copyWith(
          isAnalyzing: false,
          error: 'Không thể yêu cầu phân tích CV. Vui lòng thử lại.',
        );
      }
      
      state = state.copyWith(isAnalyzing: false);
      return success;
    } catch (e) {
      debugPrint('Error requesting CV analysis: $e');
      state = state.copyWith(isAnalyzing: false, error: 'Lỗi khi yêu cầu phân tích CV: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear all data when user logs out
  void clearAllData() {
    state = const CVAnalysisState();
  }

  /// Reset state to initial
  void reset() {
    state = const CVAnalysisState();
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
