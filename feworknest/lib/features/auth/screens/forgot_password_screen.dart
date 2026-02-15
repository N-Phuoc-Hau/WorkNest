import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/language_toggle_widget.dart';
import '../../../shared/widgets/worknest_logo.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.sendForgotPasswordOtp(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      final l10n = ref.read(localizationsProvider);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.otpSentSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/verify-otp?email=${_emailController.text.trim()}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: EdgeInsets.all(AppSpacing.spacing48),
                  child: _buildContent(context, l10n),
                ),
              );
            } else {
              return SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.spacing24),
                child: _buildContent(context, l10n),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.spacing32),

          // Logo
          Center(
            child: const WorkNestLogo(size: 80),
          ),
          SizedBox(height: AppSpacing.spacing32),

          // Title
          Text(
            l10n.forgotPasswordTitle,
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacing12),

          // Subtitle
          Text(
            l10n.forgotPasswordSubtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacing48),

          // Info card
          Container(
            padding: EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 24,
                ),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Text(
                    l10n.otpInfo,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          SizedBox(height: AppSpacing.spacing32),

          // Send OTP button
          AppButton(
            onPressed: _isLoading ? null : _sendOtp,
            isLoading: _isLoading,
            text: l10n.sendOtpCode,
          ),
          SizedBox(height: AppSpacing.spacing24),

          // Back to login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.rememberPassword,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  l10n.backToLogin,
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
}
