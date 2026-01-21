import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:journal_app/core/theme/app_theme.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    final authService = ref.read(authServiceProvider);
    setState(() => _isLoading = true);
    try {
      await authService.signInWithGoogle();
      // Auth state stream will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),

          // Pattern Overlay (optional)
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'), // Placeholder
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.book,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                  ).animate().scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),

                  const SizedBox(height: 40),

                  // Welcome Text
                  Text(
                    'Journal V2',
                    style: AppTheme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Anılarını Modern Yolla Sakla',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 60),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassDecoration(),
                    child: Column(
                      children: [
                        _LoginButton(
                          label: 'Google ile Giriş Yap',
                          icon: Icons.g_mobiledata, // Placeholder
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () async {
                            // Update the provider state
                            ref.read(guestModeProvider.notifier).state = true;
                          },
                          child: Text(
                            'Misafir Olarak Devam Et',
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 50, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _LoginButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
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
                    style: AppTheme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
