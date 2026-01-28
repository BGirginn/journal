import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/navigation/app_router.dart';
import 'package:journal_app/core/auth/user_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check profile on startup (e.g. after hot restart) if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authStateProvider).value != null) {
        _forceProfileCheck();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    debugPrint('Hot reload detected: Forcing profile check...');
    _forceProfileCheck();
  }

  Future<void> _forceProfileCheck() async {
    try {
      final profile = await ref.read(userServiceProvider).ensureProfileExists();
      if (mounted && profile != null) {
        final needsSetup = !profile.isProfileComplete;
        ref.read(needsProfileSetupProvider.notifier).state = needsSetup;
      }
    } catch (e) {
      debugPrint('Force profile check failed: $e');
    }
  }

  void _handleGoogleSignIn() async {
    final authService = ref.read(authServiceProvider);
    setState(() => _isLoading = true);
    try {
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        // Force profile fetch immediately to trigger router update
        await _forceProfileCheck();
      }
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
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
                    child: Center(
                      child: Icon(
                        Icons.book,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(color: Colors.white),
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Anılarını Modern Yolla Sakla',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 60),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (ref.watch(authStateProvider).value != null) ...[
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Profil kontrol ediliyor...',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                              // Reset provider states
                              ref
                                      .read(needsProfileSetupProvider.notifier)
                                      .state =
                                  null;
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white70,
                            ),
                            label: const Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ] else ...[
                          _LoginButton(
                            label: 'Google ile Giriş Yap',
                            icon: Icons.g_mobiledata, // Placeholder
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            isLoading: _isLoading,
                          ),
                          if (!ref.watch(firebaseAvailableProvider)) ...[
                            const SizedBox(height: 8),
                            Text(
                              ref.watch(firebaseErrorProvider) ??
                                  'Firebase başlatılamadı.',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
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
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}
