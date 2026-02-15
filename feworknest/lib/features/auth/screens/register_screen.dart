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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRecruiter = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = ref.read(localizationsProvider);

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.agreeToTerms),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.clearError();

    final userData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'fullName': _fullNameController.text.trim(),
      if (_isRecruiter) 'companyName': _companyNameController.text.trim(),
    };

    final success = await authNotifier.register(
      userData,
      isRecruiter: _isRecruiter,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.registerSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } else {
      setState(() {});
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
            SizedBox(height: AppSpacing.spacing24),

            // Logo and branding
            _buildBranding(context, l10n),
            SizedBox(height: AppSpacing.spacing32),

            // Register form
            _buildRegisterForm(context, authState, l10n),
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
        // Left side - Illustration
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary.withOpacity(0.05),
            padding: EdgeInsets.all(AppSpacing.spacing48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WorkNestLogo(size: 60),
                SizedBox(height: AppSpacing.spacing32),
                Text(
                  l10n.registerTitle,
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacing16),
                Text(
                  l10n.registerSubtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacing48),
                Icon(
                  Icons.person_add_rounded,
                  size: 200,
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),

        // Right side - Form
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.spacing48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    LanguageToggleButton(),
                  ],
                ),
                SizedBox(height: AppSpacing.spacing32),
                Text(
                  l10n.signUp,
                  style: AppTypography.h2,
                ),
                SizedBox(height: AppSpacing.spacing48),
                _buildRegisterForm(context, authState, l10n),
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
        const WorkNestLogo(size: 80),
        SizedBox(height: AppSpacing.spacing20),
        Text(
          l10n.appName,
          style: AppTypography.h2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacing8),
        Text(
          l10n.registerSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    BuildContext context,
    AuthState authState,
    dynamic l10n,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role selector tabs
          _buildRoleTabs(context, l10n),
          SizedBox(height: AppSpacing.spacing24),

          // Google Sign-up button
          _buildGoogleSignUpButton(context, l10n),
          SizedBox(height: AppSpacing.spacing24),

          // Divider
          _buildDivider(context, l10n),
          SizedBox(height: AppSpacing.spacing24),

          // Full Name / Company Name
          AppTextField(
            controller: _isRecruiter ? _companyNameController : _fullNameController,
            label: _isRecruiter ? l10n.companyName : l10n.fullName,
            hintText: _isRecruiter ? l10n.companyNameHint : l10n.fullNameHint,
            prefixIcon: Icon(_isRecruiter ? Icons.business : Icons.person_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fullNameRequired;
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.spacing16),

          // Email
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

          // Password
          AppTextField(
            controller: _passwordController,
            label: l10n.password,
            hintText: l10n.passwordHint,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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
          SizedBox(height: AppSpacing.spacing16),

          // Confirm Password
          AppTextField(
            controller: _confirmPasswordController,
            label: l10n.confirmPassword,
            hintText: l10n.confirmPasswordHint,
            obscureText: _obscureConfirmPassword,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.passwordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.passwordsNotMatch;
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.spacing20),

          // Terms & Privacy checkbox
          _buildTermsCheckbox(context, l10n),
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

          // Register button
          AppButton(
            onPressed: authState.isLoading ? null : _register,
            isLoading: authState.isLoading,
            text: l10n.signUp,
          ),
          SizedBox(height: AppSpacing.spacing24),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.alreadyHaveAccount,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  l10n.loginNow,
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

  Widget _buildRoleTabs(BuildContext context, dynamic l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleTab(
              context,
              l10n.jobSeeker,
              Icons.person_outline,
              !_isRecruiter,
              () => setState(() => _isRecruiter = false),
            ),
          ),
          Expanded(
            child: _buildRoleTab(
              context,
              l10n.company,
              Icons.business_outlined,
              _isRecruiter,
              () => setState(() => _isRecruiter = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.spacing12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.neutral600,
              size: 20,
            ),
            SizedBox(width: AppSpacing.spacing8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.neutral600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignUpButton(BuildContext context, dynamic l10n) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-Up coming soon!'),
            backgroundColor: AppColors.info,
          ),
        );
      },
      icon: Image.network(
        'https://www.google.com/favicon.ico',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
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
        const Expanded(child: Divider(color: AppColors.neutral300, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
          child: Text(
            l10n.orSignUpWith,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.neutral300, thickness: 1)),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context, dynamic l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: AppSpacing.spacing12),
            child: Wrap(
              children: [
                Text(
                  '${l10n.agreeToTerms.split(',')[0]}, ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Open Terms of Service
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.termsOfService,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' ${l10n.and} ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Open Privacy Policy
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.privacyPolicy,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
