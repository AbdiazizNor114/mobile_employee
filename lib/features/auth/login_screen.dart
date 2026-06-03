import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/service_providers.dart';
import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Clear any stale data before logging in as a new user
      ref.read(resetWorkDataProvider)();

      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      ref.read(demoSessionProvider.notifier).state = false;
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      String message = 'Could not sign in. Check your email and password.';
      if (error is DioException) {
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (status != null) {
          message = 'Sign-in failed ($status). Please try again.';
        }
        if (data is Map && data['error'] is String) {
          message = data['error'] as String;
        }
      }
      setState(() {
        _message = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.appTitle,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.loginTitle, style: AppTypography.headingLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.loginSubtitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.password),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: Text(_isLoading ? 'Signing in...' : l10n.signIn),
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
