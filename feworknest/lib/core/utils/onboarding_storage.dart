import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const String _onboardingKey = 'has_seen_onboarding';
  
  /// Check if user has seen onboarding before
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
  
  /// Mark onboarding as seen
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  /// Reset onboarding status (for testing purposes)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
