import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:journal_app/core/theme/tokens/brand_colors.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _kOnboardingCompleteKey = 'onboarding_complete';

  List<_OnboardingPage> _buildPages(AppLocalizations l10n, bool isDark) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _buildPages(l10n, isDark);
    final isLastPage = _currentPage == pages.length - 1;
    final foreground = isDark
        ? const Color(0xFFF5F1E9)
        : BrandColors.primary900;
    final descriptionColor = foreground.withValues(alpha: isDark ? 0.9 : 0.82);
    final buttonBackground = isDark
        ? const Color(0xFFEAE5D9)
        : const Color(0xFFF5F1E8);
    const buttonForeground = BrandColors.primary900;
    final iconBubbleColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.28);
    final indicatorActive = foreground.withValues(alpha: 0.9);
    final indicatorInactive = foreground.withValues(alpha: 0.32);

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
