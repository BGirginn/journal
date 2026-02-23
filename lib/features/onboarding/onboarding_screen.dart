import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/theme/theme_provider.dart';
import 'package:journal_app/core/theme/theme_variant.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _kOnboardingCompleteKey = 'onboarding_complete';

  List<_OnboardingPage> _buildPages(
    AppLocalizations l10n,
    bool isDark,
    bool isVioletTheme,
    bool isTestedTheme,
    ColorScheme colorScheme,
    JournalSemanticColors? semantic,
  ) {
    if (isTestedTheme) {
      return [
        _OnboardingPage(
          icon: Icons.book_rounded,
          title: l10n.onboardingTitleCaptureMemories,
          description: l10n.onboardingDescCaptureMemories,
          gradient: isDark
              ? const [Color(0xFF070B16), Color(0xFF0F1124), Color(0xFF15102E)]
              : const [Color(0xFFF1EEFF), Color(0xFFE5E2FF), Color(0xFFD9D7F8)],
        ),
        _OnboardingPage(
          icon: Icons.group_rounded,
          title: l10n.onboardingTitleShareTogether,
          description: l10n.onboardingDescShareTogether,
          gradient: isDark
              ? const [Color(0xFF0A0F1E), Color(0xFF121530), Color(0xFF1A1740)]
              : const [Color(0xFFEFEAFF), Color(0xFFE3DEFF), Color(0xFFD3D2F5)],
        ),
        _OnboardingPage(
          icon: Icons.palette_rounded,
          title: l10n.onboardingTitlePersonalize,
          description: l10n.onboardingDescPersonalize,
          gradient: isDark
              ? const [Color(0xFF0D1122), Color(0xFF141536), Color(0xFF1B1A4A)]
              : const [Color(0xFFECE9FF), Color(0xFFDFDCFF), Color(0xFFCFCEF2)],
        ),
      ];
    }

    if (isVioletTheme) {
      final surface = semantic?.card ?? colorScheme.surface;
      final elevated = semantic?.elevated ?? colorScheme.surface;
      final background = semantic?.background ?? colorScheme.surface;
      final accent = colorScheme.primary.withValues(alpha: isDark ? 0.42 : 0.3);
      final accentStrong = colorScheme.secondary.withValues(
        alpha: isDark ? 0.36 : 0.28,
      );
      return [
        _OnboardingPage(
          icon: Icons.book_rounded,
          title: l10n.onboardingTitleCaptureMemories,
          description: l10n.onboardingDescCaptureMemories,
          gradient: [surface, elevated, accent],
        ),
        _OnboardingPage(
          icon: Icons.group_rounded,
          title: l10n.onboardingTitleShareTogether,
          description: l10n.onboardingDescShareTogether,
          gradient: [elevated, background, accentStrong],
        ),
        _OnboardingPage(
          icon: Icons.palette_rounded,
          title: l10n.onboardingTitlePersonalize,
          description: l10n.onboardingDescPersonalize,
          gradient: [surface, background, colorScheme.primary],
        ),
      ];
    }

    return [
      _OnboardingPage(
        icon: Icons.book_rounded,
        title: l10n.onboardingTitleCaptureMemories,
        description: l10n.onboardingDescCaptureMemories,
        gradient: isDark
            ? const [Color(0xFF232735), Color(0xFF4A5570)]
            : const [Color(0xFFC6CDDB), Color(0xFFB1BBCD)],
      ),
      _OnboardingPage(
        icon: Icons.group_rounded,
        title: l10n.onboardingTitleShareTogether,
        description: l10n.onboardingDescShareTogether,
        gradient: isDark
            ? const [Color(0xFF2D2421), Color(0xFF5A4A40)]
            : const [Color(0xFFD9C4B2), Color(0xFFC9AB97)],
      ),
      _OnboardingPage(
        icon: Icons.palette_rounded,
        title: l10n.onboardingTitlePersonalize,
        description: l10n.onboardingDescPersonalize,
        gradient: isDark
            ? const [Color(0xFF1E2D29), Color(0xFF3C554D)]
            : const [Color(0xFFBED1C8), Color(0xFFA9BEB3)],
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleteKey, true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<JournalSemanticColors>();
    final isDark = theme.brightness == Brightness.dark;
    final activeVariant = ref.watch(themeProvider).effectiveVariant;
    final isTestedTheme = activeVariant == AppThemeVariant.testedTheme;
    final isVioletTheme =
        activeVariant == AppThemeVariant.violetNebulaJournal || isTestedTheme;
    final pages = _buildPages(
      l10n,
      isDark,
      isVioletTheme,
      isTestedTheme,
      colorScheme,
      semantic,
    );
    final isLastPage = _currentPage == pages.length - 1;
    final foreground = isVioletTheme
        ? colorScheme.onSurface
        : isDark
        ? const Color(0xFFF5F1E9)
        : BrandColors.primary900;
    final descriptionColor = isVioletTheme
        ? colorScheme.onSurfaceVariant
        : foreground.withValues(alpha: isDark ? 0.9 : 0.82);
    final buttonBackground = isVioletTheme
        ? colorScheme.primary
        : isDark
        ? const Color(0xFFEAE5D9)
        : const Color(0xFFF5F1E8);
    final buttonForeground = isVioletTheme
        ? colorScheme.onPrimary
        : BrandColors.primary900;
    final iconBubbleColor = isVioletTheme
        ? colorScheme.primaryContainer.withValues(alpha: isDark ? 0.32 : 0.24)
        : isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.28);
    final indicatorActive = isVioletTheme
        ? colorScheme.secondary
        : foreground.withValues(alpha: 0.9);
    final indicatorInactive = isVioletTheme
        ? colorScheme.onSurface.withValues(alpha: 0.28)
        : foreground.withValues(alpha: 0.32);

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = pages[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: iconBubbleColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page.icon,
                                size: 64,
                                color: foreground,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(delay: 200.ms),
                        const SizedBox(height: 48),
                        Text(
                              page.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: foreground,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),
                        Text(
                              page.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: descriptionColor,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? indicatorActive
                                : indicatorInactive,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _complete,
                          child: Text(
                            l10n.onboardingSkip,
                            style: TextStyle(
                              color: foreground.withValues(alpha: 0.84),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: isLastPage
                              ? _complete
                              : () {
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: buttonBackground,
                            foregroundColor: buttonForeground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            isLastPage
                                ? l10n.onboardingGetStarted
                                : l10n.onboardingNext,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
