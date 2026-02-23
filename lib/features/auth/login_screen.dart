import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/theme/theme_variant.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isGoogleLoading = false;

  bool get _isAnyLoading => _isGoogleLoading;

  Future<void> _handleGoogleSignIn() async {
    final authService = ref.read(authServiceProvider);
    setState(() => _isGoogleLoading = true);
    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_readableErrorMessage(l10n, e)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
      case 'auth/apple_provider_not_enabled':
        return l10n.loginAppleProviderNotEnabled;
      case 'auth/apple_authorization_failed':
        return l10n.loginAppleAuthorizationFailed;
      case 'auth/apple_credential_request_failed':
        return l10n.loginAppleCredentialRequestFailed;
      case 'auth/apple_flow_timeout':
        return l10n.loginAppleFlowTimeout;
      case 'auth/google_sign_in_config_error':
        return l10n.loginGoogleConfigError;
      case 'auth/firebase_unavailable':
        return l10n.loginFirebaseUnavailable;
      case 'auth/account_exists_with_different_credential_apple':
        return l10n.loginAccountExistsWithGoogleMessage;
      default:
        return '${l10n.errorPrefix}: ${error.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<JournalSemanticColors>();
    final activeVariant = ref.watch(themeProvider).effectiveVariant;
    final isVioletTheme =
        activeVariant == AppThemeVariant.violetNebulaJournal ||
        activeVariant == AppThemeVariant.testedTheme;
    final isTestedTheme = activeVariant == AppThemeVariant.testedTheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = theme.brightness == Brightness.dark;

    final visual = _LoginVisualTokens.resolve(
      isDark: isDark,
      isVioletTheme: isVioletTheme,
      isTestedTheme: isTestedTheme,
      colorScheme: colorScheme,
    );

    final titleColor = isDark ? visual.titleColorDark : visual.titleColorLight;
    final subtitleColor = titleColor.withValues(
      alpha: isVioletTheme && isDark ? 0.72 : (isDark ? 0.88 : 0.78),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: visual.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -110,
              child: _BackdropOrb(size: 320, color: visual.orbPrimary),
            ),
            Positioned(
              top: 170,
              left: -95,
              child: _BackdropOrb(size: 250, color: visual.orbWarm),
            ),
            Positioned(
              bottom: -130,
              right: -70,
              child: _BackdropOrb(size: 290, color: visual.orbMint),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final topSection = _buildTopSection(
                    context: context,
                    l10n: l10n,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    isVioletTheme: isVioletTheme,
                    semantic: semantic,
                  );

                  final authPanel = _buildAuthPanel(
                    context: context,
                    l10n: l10n,
                    isDark: isDark,
                    isVioletTheme: isVioletTheme,
                    semantic: semantic,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          reduceMotion
                              ? topSection
                              : topSection
                                    .animate()
                                    .fadeIn(duration: 420.ms)
                                    .slideY(
                                      begin: 0.08,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                          const SizedBox(height: 22),
                          reduceMotion
                              ? authPanel
                              : authPanel
                                    .animate()
                                    .fadeIn(delay: 220.ms, duration: 420.ms)
                                    .slideY(
                                      begin: 0.08,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required Color titleColor,
    required Color subtitleColor,
    required bool isDark,
    required bool isVioletTheme,
    required JournalSemanticColors? semantic,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _HeroBadge(
          isDark: isDark,
          isVioletTheme: isVioletTheme,
          semantic: semantic,
        ),
        const SizedBox(height: 28),
        Text(
          l10n.appTitle,
          style: textTheme.displaySmall?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.loginTagline,
          style: textTheme.titleMedium?.copyWith(
            color: subtitleColor,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),
        _HighlightsPanel(
          firstLabel: l10n.onboardingTitleCaptureMemories,
          firstDescription: l10n.onboardingDescCaptureMemories,
          secondLabel: l10n.onboardingTitleShareTogether,
          secondDescription: l10n.onboardingDescShareTogether,
          thirdLabel: l10n.onboardingTitlePersonalize,
          thirdDescription: l10n.onboardingDescPersonalize,
          isVioletTheme: isVioletTheme,
          semantic: semantic,
        ),
      ],
    );
  }

  Widget _buildAuthPanel({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isDark,
    required bool isVioletTheme,
    required JournalSemanticColors? semantic,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authStateProvider).value;
    final firebaseAvailable = ref.watch(firebaseAvailableProvider);
    final firebaseError = ref.watch(firebaseErrorProvider);

    final shouldShowGmailButton =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: isVioletTheme
            ? (semantic?.elevated ?? colorScheme.surface).withValues(
                alpha: isDark ? 0.92 : 0.9,
              )
            : colorScheme.surface.withValues(alpha: isDark ? 0.88 : 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isVioletTheme
              ? (semantic?.divider ?? colorScheme.outlineVariant).withValues(
                  alpha: isDark ? 0.95 : 0.82,
                )
              : colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.78 : 0.9,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: isVioletTheme
                  ? (isDark ? 0.42 : 0.2)
                  : (isDark ? 0.32 : 0.16),
            ),
            blurRadius: isVioletTheme ? (isDark ? 28 : 24) : 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.appTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (authState != null) ...[
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                l10n.loginProfileChecking,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                    ref.read(needsProfileSetupProvider.notifier).state = null;
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.errorPrefix}: $e')),
                    );
                  }
                },
                icon: Icon(
                  Icons.logout_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  l10n.signOut,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ] else ...[
            _LoginButton(
              label: l10n.loginGoogleSignIn,
              icon: const _GmailLogoIcon(size: 20),
              onPressed: shouldShowGmailButton && !_isAnyLoading
                  ? _handleGoogleSignIn
                  : null,
              isLoading: _isGoogleLoading,
            ),
            if (!firebaseAvailable) ...[
              const SizedBox(height: 12),
              Text(
                firebaseError ?? l10n.loginFirebaseUnavailable,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.isDark,
    required this.isVioletTheme,
    required this.semantic,
  });

  final bool isDark;
  final bool isVioletTheme;
  final JournalSemanticColors? semantic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: isVioletTheme
              ? [
                  (semantic?.card ?? colorScheme.surface).withValues(
                    alpha: isDark ? 1 : 0.96,
                  ),
                  (semantic?.elevated ?? colorScheme.surface).withValues(
                    alpha: isDark ? 1 : 0.96,
                  ),
                ]
              : isDark
              ? const [Color(0xFF2B3042), Color(0xFF3F4C66)]
              : const [Color(0xFFF8F4EC), Color(0xFFE4DDD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.72 : 0.9,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: isVioletTheme
                  ? (isDark ? 0.4 : 0.18)
                  : (isDark ? 0.36 : 0.14),
            ),
            blurRadius: isVioletTheme ? (isDark ? 26 : 22) : 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isVioletTheme
              ? (semantic?.background ?? colorScheme.surface).withValues(
                  alpha: isDark ? 0.34 : 0.36,
                )
              : colorScheme.surface.withValues(alpha: isDark ? 0.26 : 0.74),
        ),
        child: Center(
          child: Icon(
            Icons.menu_book_rounded,
            size: 46,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _HighlightsPanel extends StatelessWidget {
  const _HighlightsPanel({
    required this.firstLabel,
    required this.firstDescription,
    required this.secondLabel,
    required this.secondDescription,
    required this.thirdLabel,
    required this.thirdDescription,
    required this.isVioletTheme,
    required this.semantic,
  });

  final String firstLabel;
  final String firstDescription;
  final String secondLabel;
  final String secondDescription;
  final String thirdLabel;
  final String thirdDescription;
  final bool isVioletTheme;
  final JournalSemanticColors? semantic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVioletTheme
            ? (semantic?.card ?? colorScheme.surface).withValues(
                alpha: isDark ? 0.46 : 0.66,
              )
            : colorScheme.surface.withValues(alpha: isDark ? 0.18 : 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVioletTheme
              ? (semantic?.divider ?? colorScheme.outlineVariant).withValues(
                  alpha: isDark ? 0.95 : 0.82,
                )
              : colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.72 : 0.88,
                ),
        ),
      ),
      child: Column(
        children: [
          _HighlightItem(
            icon: Icons.auto_stories_rounded,
            label: firstLabel,
            description: firstDescription,
            isVioletTheme: isVioletTheme,
          ),
          const SizedBox(height: 10),
          _HighlightItem(
            icon: Icons.groups_rounded,
            label: secondLabel,
            description: secondDescription,
            isVioletTheme: isVioletTheme,
          ),
          const SizedBox(height: 10),
          _HighlightItem(
            icon: Icons.palette_rounded,
            label: thirdLabel,
            description: thirdDescription,
            isVioletTheme: isVioletTheme,
          ),
        ],
      ),
    );
  }
}

class _LoginVisualTokens {
  final List<Color> backgroundGradient;
  final Color titleColorDark;
  final Color titleColorLight;
  final Color orbPrimary;
  final Color orbWarm;
  final Color orbMint;

  const _LoginVisualTokens({
    required this.backgroundGradient,
    required this.titleColorDark,
    required this.titleColorLight,
    required this.orbPrimary,
    required this.orbWarm,
    required this.orbMint,
  });

  static _LoginVisualTokens resolve({
    required bool isDark,
    required bool isVioletTheme,
    required bool isTestedTheme,
    required ColorScheme colorScheme,
  }) {
    if (isTestedTheme) {
      return _LoginVisualTokens(
        backgroundGradient: isDark
            ? const [Color(0xFF070B16), Color(0xFF0F1124), Color(0xFF15102E)]
            : const [Color(0xFFF1EEFF), Color(0xFFE5E2FF), Color(0xFFD9D7F8)],
        titleColorDark: Colors.white,
        titleColorLight: BrandColors.primary900,
        orbPrimary: const Color(
          0xFF7C3AED,
        ).withValues(alpha: isDark ? 0.45 : 0.22),
        orbWarm: Colors.transparent,
        orbMint: const Color(
          0xFF38BDF8,
        ).withValues(alpha: isDark ? 0.12 : 0.08),
      );
    }

    if (isVioletTheme) {
      return _LoginVisualTokens(
        backgroundGradient: isDark
            ? const [Color(0xFF0B1020), Color(0xFF13112B), Color(0xFF2A145C)]
            : const [Color(0xFFF2ECFF), Color(0xFFE9E1FF), Color(0xFFDAD0F5)],
        titleColorDark: Colors.white,
        titleColorLight: BrandColors.primary900,
        orbPrimary: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        orbWarm: const Color(0xFFB794F4).withValues(alpha: isDark ? 0.24 : 0.2),
        orbMint: const Color(0xFFA78BFA).withValues(alpha: isDark ? 0.2 : 0.16),
      );
    }

    return _LoginVisualTokens(
      backgroundGradient: isDark
          ? const [Color(0xFF17161D), Color(0xFF252330), Color(0xFF36445A)]
          : const [Color(0xFFECE7DE), Color(0xFFD8D3C8), Color(0xFFC5CEDC)],
      titleColorDark: const Color(0xFFF4EFE5),
      titleColorLight: BrandColors.primary900,
      orbPrimary: colorScheme.primary.withValues(alpha: isDark ? 0.26 : 0.18),
      orbWarm: BrandColors.warmAccent.withValues(alpha: isDark ? 0.22 : 0.3),
      orbMint: BrandColors.softMint.withValues(alpha: isDark ? 0.2 : 0.26),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  const _HighlightItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.isVioletTheme,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool isVioletTheme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVioletTheme
            ? colorScheme.surface.withValues(alpha: isDark ? 0.34 : 0.86)
            : colorScheme.surface.withValues(alpha: isDark ? 0.2 : 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isVioletTheme
                ? (isDark ? 0.74 : 0.6)
                : (isDark ? 0.5 : 0.65),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null || isLoading;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: onPressed,
          style: ButtonStyle(
            elevation: WidgetStateProperty.all(0),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 16),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (isLoading) return colorScheme.primary;
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.surfaceContainerHighest;
              }
              return colorScheme.primary;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (isLoading) return colorScheme.onPrimary;
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurfaceVariant;
              }
              return colorScheme.onPrimary;
            }),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? colorScheme.onPrimary.withValues(alpha: 0.14)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(child: icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isEnabled
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: isEnabled
                          ? colorScheme.onPrimary.withValues(alpha: 0.9)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GmailLogoIcon extends StatelessWidget {
  const _GmailLogoIcon({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ],
          stops: [0.0, 0.4, 0.72, 1.0],
        ).createShader(bounds),
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.78,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
