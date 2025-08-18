import 'package:flutter/material.dart';

class CVAnalysisResult {
  final int applicationId;
  final int matchScore;
  final List<String> extractedSkills;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> improvementSuggestions;
  final String detailedAnalysis;
  final DateTime analyzedAt;

  CVAnalysisResult({
    required this.applicationId,
    required this.matchScore,
    required this.extractedSkills,
    required this.strengths,
    required this.weaknesses,
    required this.improvementSuggestions,
    required this.detailedAnalysis,
    required this.analyzedAt,
  });

  factory CVAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CVAnalysisResult(
      applicationId: json['applicationId'] ?? 0,
      matchScore: json['matchScore'] ?? 0,
      extractedSkills: List<String>.from(json['extractedSkills'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      improvementSuggestions: List<String>.from(json['improvementSuggestions'] ?? []),
      detailedAnalysis: json['detailedAnalysis'] ?? '',
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'matchScore': matchScore,
      'extractedSkills': extractedSkills,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvementSuggestions': improvementSuggestions,
      'detailedAnalysis': detailedAnalysis,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get matchScoreText {
    if (matchScore >= 90) return 'Rất phù hợp';
    if (matchScore >= 80) return 'Phù hợp';
    if (matchScore >= 70) return 'Khá phù hợp';
    if (matchScore >= 60) return 'Trung bình';
    return 'Ít phù hợp';
  }

  Color get matchScoreColor {
    if (matchScore >= 90) return const Color(0xFF4CAF50); // Green
    if (matchScore >= 80) return const Color(0xFF8BC34A); // Light Green
    if (matchScore >= 70) return const Color(0xFFFFC107); // Amber
    if (matchScore >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }
}

// State for CV Analysis Provider
class CVAnalysisState {
  final CVAnalysisResult? analysisResult;
  final bool isLoading;
  final String? error;
  final bool isAnalyzing;

  const CVAnalysisState({
    this.analysisResult,
    this.isLoading = false,
    this.error,
    this.isAnalyzing = false,
  });

  CVAnalysisState copyWith({
    CVAnalysisResult? analysisResult,
    bool? isLoading,
    String? error,
    bool? isAnalyzing,
  }) {
    return CVAnalysisState(
      analysisResult: analysisResult ?? this.analysisResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}
