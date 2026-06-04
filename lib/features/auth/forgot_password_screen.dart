import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/service_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _sent = false;
        _message = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await ref.read(authServiceProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _message = 'Password reset email sent. Check your inbox.';
      });
    } catch (error) {
      if (!mounted) return;
      var message = 'Could not send reset email. Try again.';
      if (error is ArgumentError) {
        message = error.message.toString();
      }
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map && data['error'] is String) {
          message = data['error'] as String;
        }
      }
      setState(() {
        _sent = false;
        _message = message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.lg * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const Spacer(),
                    Text('Reset password', style: AppTypography.headingLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter your account email and we will send you a secure reset link.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _isLoading ? null : _sendReset(),
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _isLoading ? null : _sendReset,
                      child:
                          Text(_isLoading ? 'Sending...' : 'Send reset link'),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _sent
                              ? AppColors.greenSoft
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                _sent ? AppColors.primaryGreen : AppColors.line,
                          ),
                        ),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: _sent
                                ? AppColors.primaryGreenDark
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
