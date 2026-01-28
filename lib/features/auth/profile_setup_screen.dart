import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:journal_app/core/auth/user_service.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/navigation/app_router.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = 'En az 3 karakter gerekli';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await ref
          .read(userServiceProvider)
          .isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _usernameError = isAvailable ? null : 'Bu kullanıcı adı alınmış';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Remove "Exception: " prefix for cleaner display
          final msg = e.toString().replaceAll('Exception: ', '');
          _usernameError = msg;
          _isCheckingUsername = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUsernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir kullanıcı adı seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userServiceProvider)
          .completeProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            username: _usernameController.text,
          );

      // Update the provider state to notify router that profile is complete
      ref.read(needsProfileSetupProvider.notifier).state = false;

      if (mounted) {
        context.go('/');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Text(
                    'Profilini Oluştur',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Arkadaşların seni bulabilmesi için\nbilgilerini gir',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

                  const SizedBox(height: 48),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // First Name
                          _buildTextField(
                            controller: _firstNameController,
                            label: 'Ad',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Last Name
                          _buildTextField(
                            controller: _lastNameController,
                            label: 'Soyad',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Username
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Kullanıcı Adı',
                            icon: Icons.alternate_email,
                            suffix: _isCheckingUsername
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _isUsernameAvailable == true
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : _isUsernameAvailable == false
                                ? const Icon(Icons.cancel, color: Colors.red)
                                : null,
                            errorText: _usernameError,
                            onChanged: (value) {
                              // Debounce the check
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  if (_usernameController.text == value &&
                                      value.isNotEmpty) {
                                    _checkUsername(value);
                                  }
                                },
                              );
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Kullanıcı adı gerekli';
                              }
                              if (value.trim().length < 3) {
                                return 'En az 3 karakter';
                              }
                              // Allow Turkish characters: a-zA-Z, ığüşöçİĞÜŞÖÇ, 0-9, _
                              if (!RegExp(
                                r'^[a-zA-ZığüşöçİĞÜŞÖÇ0-9_]+$',
                              ).hasMatch(value)) {
                                return 'Sadece harf, rakam ve _ kullanın';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Kullanıcı adın, arkadaşlarının seni bulması için kullanılır',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          FilledButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Devam Et',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 24),

                  // Sign out button for using different account
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      ref.read(needsProfileSetupProvider.notifier).state = null;
                      // Router will automatically redirect due to auth state change
                    },
                    icon: const Icon(Icons.swap_horiz, color: Colors.white70),
                    label: const Text(
                      'Farklı Hesap Kullan',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? suffix,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.all(12), child: suffix)
            : null,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
