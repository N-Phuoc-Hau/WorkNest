import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cv_analysis_model.dart';
import '../services/cv_analysis_service.dart';

class CVAnalysisNotifier extends StateNotifier<CVAnalysisState> {
  final CVAnalysisService _cvAnalysisService;

  CVAnalysisNotifier(this._cvAnalysisService) : super(const CVAnalysisState());

  /// Get CV Analysis for an application
  Future<void> getCVAnalysis(int applicationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('DEBUG CVAnalysisProvider: Getting CV analysis for application $applicationId');
      
      final analysisResult = await _cvAnalysisService.getCVAnalysis(applicationId);
      
      if (analysisResult != null) {
        print('DEBUG CVAnalysisProvider: CV analysis retrieved successfully');
        print('DEBUG CVAnalysisProvider: Match score: ${analysisResult.matchScore}%');
        
        state = state.copyWith(
          analysisResult: analysisResult,
          isLoading: false,
        );
      } else {
        print('DEBUG CVAnalysisProvider: CV analysis not available yet');
        
        state = state.copyWith(
          isLoading: false,
          error: 'Phân tích CV chưa sẵn sàng. Vui lòng thử lại sau.',
        );
      }
    } catch (e) {
      print('DEBUG CVAnalysisProvider: Error getting CV analysis: $e');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Request CV Analysis for an application
  Future<bool> requestCVAnalysis(int applicationId) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      print('DEBUG CVAnalysisProvider: Requesting CV analysis for application $applicationId');
      
      await _cvAnalysisService.requestCVAnalysis(applicationId);
      
      print('DEBUG CVAnalysisProvider: CV analysis requested successfully');
      
      state = state.copyWith(isAnalyzing: false);
      
      // Wait a bit and then try to get the result
      await Future.delayed(const Duration(seconds: 3));
      await getCVAnalysis(applicationId);
      
      return true;
    } catch (e) {
      print('DEBUG CVAnalysisProvider: Error requesting CV analysis: $e');
      
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear the current analysis result
  void clearAnalysis() {
    state = const CVAnalysisState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final cvAnalysisServiceProvider = Provider<CVAnalysisService>((ref) => CVAnalysisService());

final cvAnalysisProvider = StateNotifierProvider<CVAnalysisNotifier, CVAnalysisState>((ref) {
  return CVAnalysisNotifier(ref.watch(cvAnalysisServiceProvider));
});
