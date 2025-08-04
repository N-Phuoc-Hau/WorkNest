import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/onboarding_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusMessage = 'Đang khởi động...';

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Step 1: Test backend connection
      _updateStatus('Đang kết nối server...');
      
      final authService = AuthService();
      final isConnected = await authService.testConnection();
      
      if (!isConnected) {
        _updateStatus('Không thể kết nối đến server');
        await Future.delayed(const Duration(seconds: 1));
        // Continue anyway to allow offline browsing
      }
      
      // Step 2: Wait for auth loading to complete
      _updateStatus('Đang kiểm tra đăng nhập...');
      
      // Wait for auth provider to finish loading
      while (ref.read(authProvider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Step 3: Check if user has seen onboarding
      _updateStatus('Đang khởi tạo...');
      
      final hasSeenOnboarding = await OnboardingStorage.hasSeenOnboarding();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        final authState = ref.read(authProvider);
        
        if (authState.isAuthenticated && authState.user != null) {
          _updateStatus('Chào mừng trở lại!');
          await Future.delayed(const Duration(milliseconds: 500));
          // User is authenticated, go to appropriate dashboard
          final user = authState.user!;
          if (mounted) {
            if (user.role == 'Admin') {
              context.go('/admin-dashboard');
            } else if (user.isRecruiter) {
              context.go('/recruiter-dashboard');
            } else {
              context.go('/candidate-dashboard');
            }
          }
        } else if (!hasSeenOnboarding) {
          _updateStatus('Chào mừng đến với WorkNest!');
          await Future.delayed(const Duration(milliseconds: 500));
          // First time user, show onboarding
          if (mounted) context.go('/onboarding');
        } else {
          _updateStatus('Chuyển đến trang chủ...');
          await Future.delayed(const Duration(milliseconds: 500));
          // User has seen onboarding but not authenticated, go to main navigation
          if (mounted) context.go('/main');
        }
      }
    } catch (e) {
      _updateStatus('Có lỗi xảy ra, đang thử lại...');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work,
                size: 60,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 24),
            
            // App Name
            const Text(
              'WorkNest',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            const Text(
              'Nơi tìm kiếm việc làm',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            
            // Status message
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
