import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = l10n.validEmailRequired);
      return;
    }

    if (password.length < 6) {
      setState(() => _message = l10n.passwordMinLength);
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
      String message = l10n.signInGenericError;
      if (error is DioException) {
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          message = l10n.serverUnreachable;
        } else if (status == 401 || status == 404) {
          message = _accountNotFoundMessage;
        } else if (status != null) {
          message = l10n.signInFailedWithStatus(status);
        }
        if (data is Map && data['error'] is String) {
          message = _loginErrorMessage(data['error'] as String, message);
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
                    const Spacer(),
                    Center(
                      child: SvgPicture.asset(
                        'assets/logos/shaqonet-logo-transparent-dark.svg',
                        width: 230,
                        semanticsLabel: l10n.appTitle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.go,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(labelText: l10n.password),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go('/forgot-password'),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: Text(_isLoading ? l10n.signingIn : l10n.signIn),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8E1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFB7A8),
                          ),
                        ),
                        child: Text(
                          _message!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFFC43C24),
                            fontWeight: FontWeight.w700,
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

const _accountNotFoundMessage =
    'We could not find a ShaqoNet account for those details. If your company uses ShaqoNet, ask your manager to invite you first or check the email and password.';

String _loginErrorMessage(String serverError, String fallback) {
  final normalized = serverError.toLowerCase();
  if (normalized.contains('user does not exist') ||
      normalized.contains('invalid') ||
      normalized.contains('not found') ||
      normalized.contains('membership')) {
    return _accountNotFoundMessage;
  }
  if (serverError.contains('Smartplan')) {
    return serverError
        .replaceAll('Smartplan', 'ShaqoNet')
        .replaceAll('SmartPlan', 'ShaqoNet');
  }
  return serverError.trim().isEmpty ? fallback : serverError;
}
