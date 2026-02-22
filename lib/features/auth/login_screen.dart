import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/theme/design_tokens.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isAnyLoading => _isGoogleLoading || _isAppleLoading;

  Future<void> _handleGoogleSignIn() async {
    final authService = ref.read(authServiceProvider);
    setState(() => _isGoogleLoading = true);
    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_readableErrorMessage(l10n, e)),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authService = ref.read(authServiceProvider);
    setState(() => _isAppleLoading = true);
    try {
      await authService.signInWithApple();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e is AuthError &&
          e.code == 'auth/account_exists_with_different_credential_apple') {
        await _showAccountExistsWithGoogleDialog(l10n);
        return;
      }
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_readableErrorMessage(l10n, e)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _showAccountExistsWithGoogleDialog(AppLocalizations l10n) async {
    final shouldContinueWithGoogle = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.loginAccountExistsWithGoogleTitle),
        content: Text(
          '${l10n.loginAccountExistsWithGoogleMessage}\n\n${l10n.loginCanLinkAppleLater}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.loginContinueWithGoogle),
          ),
        ],
      ),
    );
    if (shouldContinueWithGoogle == true && mounted) {
      await _handleGoogleSignIn();
    }
  }

  String _readableErrorMessage(AppLocalizations l10n, Object error) {
    if (error is! AuthError) {
      return '${l10n.errorPrefix}: $error';
    }
    switch (error.code) {
      case 'auth/apple_sign_in_ios_only':
        return l10n.loginAppleIOSOnly;
      case 'auth/apple_missing_identity_token':
        return l10n.loginAppleMissingToken;
      case 'auth/apple_invalid_credential':
        return l10n.loginAppleInvalidCredential;
      case 'auth/google_sign_in_config_error':
        return l10n.loginGoogleConfigError;
      case 'auth/firebase_unavailable':
        return l10n.loginFirebaseUnavailable;
      default:
        return '${l10n.errorPrefix}: ${error.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? const [AppColorTokens.darkSurfaceContainerAlt, Color(0xFF5A2F1E)]
        : const [Color(0xFFFFE6C4), Color(0xFFF7B97A)];
    final heroTextColor = isDark ? Colors.white : const Color(0xFF432210);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (reduceMotion
                      ? _buildLogoCircle(context)
                      : _buildLogoCircle(context).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )),
                  const SizedBox(height: 40),
                  (reduceMotion
                      ? Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(color: heroTextColor),
                        )
                      : Text(
                              l10n.appTitle,
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(color: heroTextColor),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .moveY(begin: 20, end: 0)),
                  const SizedBox(height: 12),
                  (reduceMotion
                      ? Text(
                          l10n.loginTagline,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: heroTextColor.withValues(alpha: 0.86),
                              ),
                        )
                      : Text(
                              l10n.loginTagline,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: heroTextColor.withValues(
                                      alpha: 0.86,
                                    ),
                                  ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .moveY(begin: 20, end: 0)),
                  const SizedBox(height: 60),
                  (reduceMotion
                      ? _buildLoginCard(context, l10n)
                      : _buildLoginCard(context, l10n)
                            .animate()
                            .fadeIn(delay: 600.ms)
                            .moveY(begin: 50, end: 0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoCircle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.book, size: 64, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldShowAppleButton =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          if (ref.watch(authStateProvider).value != null) ...[
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.loginProfileChecking,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                ref.read(needsProfileSetupProvider.notifier).state = null;
              },
              icon: Icon(Icons.logout, color: colorScheme.onSurfaceVariant),
              label: Text(
                l10n.signOut,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ] else ...[
            _LoginButton(
              label: l10n.loginGoogleSignIn,
              icon: Icons.g_mobiledata,
              onPressed: _isAnyLoading ? null : _handleGoogleSignIn,
              isLoading: _isGoogleLoading,
            ),
            if (shouldShowAppleButton) ...[
              const SizedBox(height: 12),
              _AppleLoginButton(
                label: l10n.loginAppleSignIn,
                onPressed: _isAnyLoading ? null : _handleAppleSignIn,
                isLoading: _isAppleLoading,
              ),
            ],
            if (!ref.watch(firebaseAvailableProvider)) ...[
              const SizedBox(height: 8),
              Text(
                ref.watch(firebaseErrorProvider) ??
                    l10n.loginFirebaseUnavailable,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AppleLoginButton extends StatelessWidget {
  const _AppleLoginButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isDark
        ? SignInWithAppleButtonStyle.white
        : SignInWithAppleButtonStyle.black;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: enabled ? 1 : 0.6,
              child: AbsorbPointer(
                absorbing: !enabled,
                child: SignInWithAppleButton(
                  onPressed: onPressed ?? () {},
                  style: style,
                  text: label,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
