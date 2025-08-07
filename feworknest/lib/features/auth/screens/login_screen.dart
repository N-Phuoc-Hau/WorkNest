import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    
    // Clear any previous errors
    authNotifier.clearError();
    
    print('DEBUG LoginScreen: Starting login process...');
    
    final user = await authNotifier.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    print('DEBUG LoginScreen: Login completed, user result: $user');

    if (!mounted) return;

    if (user != null) {
      // Đăng nhập thành công
      print('DEBUG LoginScreen: Login SUCCESS - User: ${user.fullName}, Role: ${user.role}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thành công! Chào mừng ${user.fullName}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Small delay to ensure auth state is fully updated
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check if we're still mounted and authenticated before navigation
      if (!mounted) return;
      
      final currentAuthState = ref.read(authProvider);
      if (currentAuthState.isAuthenticated && currentAuthState.user != null) {
        print('DEBUG LoginScreen: Auth state confirmed, forcing navigation');
        // Force navigation immediately
        if (user.role == 'Admin') {
          print('DEBUG LoginScreen: Redirecting Admin to /admin-dashboard');
          context.go('/admin-dashboard');
        } else if (user.isRecruiter) {
          print('DEBUG LoginScreen: Redirecting Recruiter to /recruiter/home');
          context.go('/recruiter/home');
        } else {
          print('DEBUG LoginScreen: Redirecting Candidate to /home');
          context.go('/home');
        }
      } else {
        print('DEBUG LoginScreen: Auth state not ready, waiting for router redirect');
      }
    } else {
      // Đăng nhập thất bại - KHÔNG redirect, chỉ hiển thị lỗi
      print('DEBUG LoginScreen: Login FAILED - user is null, staying on login page');
      final authState = ref.read(authProvider);
      print('DEBUG LoginScreen: Current error state: ${authState.error}');
      print('DEBUG LoginScreen: Current loading state: ${authState.isLoading}');
      print('DEBUG LoginScreen: Current authenticated state: ${authState.isAuthenticated}');
      
      // Force rebuild to show error widget
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

        // Auto redirect when authenticated
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null && !next.isLoading) {
        print('DEBUG LoginScreen: Auth state changed, user is authenticated');
        print('DEBUG LoginScreen: User role: ${next.user!.role}');
        print('DEBUG LoginScreen: User isRecruiter: ${next.user!.isRecruiter}');
        
        // Force immediate navigation
        final user = next.user!;
        if (user.role == 'Admin') {
          print('DEBUG LoginScreen: Auto redirect to /admin-dashboard');
          context.go('/admin-dashboard');
        } else if (user.isRecruiter) {
          print('DEBUG LoginScreen: Auto redirect to /recruiter/home');
          context.go('/recruiter/home');
        } else {
          print('DEBUG LoginScreen: Auto redirect to /home');
          context.go('/home');
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.work,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'WorkNest',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập vào tài khoản của bạn',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email field
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Nhập email của bạn',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password field
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu của bạn',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Error message display
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Login button
                AppButton(
                  onPressed: authState.isLoading ? null : _login,
                  isLoading: authState.isLoading,
                  text: 'Đăng nhập',
                ),
                const SizedBox(height: 16),
                
                // Forgot password
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Đăng ký ngay'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
