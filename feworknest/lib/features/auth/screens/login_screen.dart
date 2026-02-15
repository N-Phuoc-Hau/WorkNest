import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/language_toggle_widget.dart';
import '../../../shared/widgets/worknest_logo.dart';

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
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Wait a moment to ensure auth state is fully propagated
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      // Navigate based on role
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
      // Đăng nhập thất bại - Stay on login page and show error
      print('DEBUG LoginScreen: Login FAILED - user is null, staying on login page');
      final authState = ref.read(authProvider);
      print('DEBUG LoginScreen: Current error: ${authState.error}');
      
      // Show error snackbar
      if (authState.error != null && authState.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = ref.watch(localizationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout
            final isWide = constraints.maxWidth > 900;
            
            if (isWide) {
              return _buildWideLayout(context, authState, l10n);
            } else {
              return _buildMobileLayout(context, authState, l10n);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AuthState authState,
    dynamic l10n,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                LanguageToggleButton(),
              ],
            ),
            SizedBox(height: AppSpacing.spacing32),

            // Logo and branding
            _buildBranding(context, l10n),
            SizedBox(height: AppSpacing.spacing48),

            // Login form
            _buildLoginForm(context, authState, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    AuthState authState,
    dynamic l10n,
  ) {
    return Row(
      children: [
        // Left side - Illustration & Stats
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary.withOpacity(0.05),
            padding: EdgeInsets.all(AppSpacing.spacing48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                const WorkNestLogo(
                  size: 60,
                  showName: false,
                ),
                SizedBox(height: AppSpacing.spacing32),

                // Stats
                _buildStatItem(
                  context,
                  '100K+',
                  l10n.peopleGotHired,
                  Icons.people_rounded,
                ),
                SizedBox(height: AppSpacing.spacing24),

                // Illustration placeholder
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 200,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),

                // Testimonial
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacing20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.borderRadiusLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              'A',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.spacing12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adam Sandler',
                                style: AppTypography.labelLarge,
                              ),
                              Text(
                                'Lead Engineer at Canva',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.spacing12),
                      Text(
                        '"Great platform for the job seeker that searching for new career heights."',
                        style: AppTypography.bodyMedium.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right side - Login form
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.spacing48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    LanguageToggleButton(),
                  ],
                ),
                SizedBox(height: AppSpacing.spacing32),

                // Title
                Text(
                  l10n.loginTitle,
                  style: AppTypography.h2,
                ),
                SizedBox(height: AppSpacing.spacing8),
                Text(
                  l10n.loginSubtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacing48),

                // Login form
                _buildLoginForm(context, authState, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranding(BuildContext context, dynamic l10n) {
    return Column(
      children: [
        // Logo
        const WorkNestLogo(
          size: 80,
          showName: false,
        ),
        SizedBox(height: AppSpacing.spacing20),

        // App name
        Text(
          l10n.appName,
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing8),

        // Subtitle
        Text(
          l10n.loginSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(
    BuildContext context,
    AuthState authState,
    dynamic l10n,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role tabs (Job Seeker / Company) - Optional, you can remove if not needed
          // _buildRoleTabs(context, l10n),
          // SizedBox(height: AppSpacing.spacing24),

          // Google Sign-in button
          _buildGoogleSignInButton(context, l10n),
          SizedBox(height: AppSpacing.spacing24),

          // Divider
          _buildDivider(context, l10n),
          SizedBox(height: AppSpacing.spacing24),

          // Email field
          AppTextField(
            controller: _emailController,
            label: l10n.email,
            hintText: l10n.emailHint,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.emailRequired;
              }
              if (!value.contains('@')) {
                return l10n.emailInvalid;
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.spacing16),

          // Password field
          AppTextField(
            controller: _passwordController,
            label: l10n.password,
            hintText: l10n.passwordHint,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.passwordRequired;
              }
              if (value.length < 6) {
                return l10n.passwordTooShort;
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.spacing12),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.push('/forgot-password');
              },
              child: Text(
                l10n.forgotPassword,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacing24),

          // Error message
          if (authState.error != null) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Text(
                      authState.error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.spacing16),
          ],

          // Login button
          AppButton(
            onPressed: authState.isLoading ? null : _login,
            isLoading: authState.isLoading,
            text: l10n.login,
          ),
          SizedBox(height: AppSpacing.spacing24),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.dontHaveAccount,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(
                  l10n.registerNow,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, dynamic l10n) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement Google Sign-In
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In coming soon!'),
            backgroundColor: AppColors.info,
          ),
        );
      },
      icon: Image.network(
        'https://www.google.com/favicon.ico',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.g_mobiledata_rounded,
            color: AppColors.primary,
            size: 24,
          );
        },
      ),
      label: Text(
        l10n.loginWithGoogle,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.neutral900,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing20,
          vertical: AppSpacing.spacing16,
        ),
        side: BorderSide(
          color: AppColors.neutral300,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context, dynamic l10n) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.neutral300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
          child: Text(
            l10n.orLoginWith,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.neutral300,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String number,
    String label,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        SizedBox(width: AppSpacing.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: AppTypography.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
