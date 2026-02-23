import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journal_app/core/auth/apple_sign_in_client.dart';
import 'package:journal_app/core/auth/auth_nonce.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/core/observability/app_logger.dart';

final firebaseErrorProvider = StateProvider<String?>((ref) => null);

final firebaseAvailableProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  final isAvailable = ref.watch(firebaseAvailableProvider);
  final logger = ref.watch(appLoggerProvider);
  return AuthService(isFirebaseAvailable: isAvailable, logger: logger);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthService {
  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final AppleSignInClient _appleSignInClient;
  final AppLogger? _logger;

  AuthService({
    bool isFirebaseAvailable = true,
    AppLogger? logger,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    AppleSignInClient? appleSignInClient,
  }) : _auth = isFirebaseAvailable ? (auth ?? FirebaseAuth.instance) : null,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _appleSignInClient = appleSignInClient ?? const AppleSignInClientImpl(),
       _logger = logger;

  Stream<User?> get authStateChanges {
    if (_auth != null) {
      return _auth.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Set<String> getCurrentProviderIds() {
    final user = _auth?.currentUser;
    if (user == null) return {};
    return user.providerData.map((provider) => provider.providerId).toSet();
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_auth == null) {
      throw const AuthError(
        code: 'auth/firebase_unavailable',
        message: 'Firebase baslatilamadi veya yapilandirma hatasi.',
      );
    }
    try {
      // Force account picker by clearing previous session.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      _logger?.error('google_sign_in_platform_failed', error: e);
      final details = '${e.message ?? ''} ${e.details ?? ''}';
      if (e.code == 'sign_in_failed' && details.contains('10')) {
        throw const AuthError(
          code: 'auth/google_sign_in_config_error',
          message:
              'Google Sign-In yapılandırma hatası (SHA-1/SHA-256 veya OAuth client).',
        );
      }
      throw AuthError(
        code: 'auth/google_sign_in_failed',
        message: 'Google Sign-In başarısız oldu.',
        cause: e,
      );
    } on FirebaseAuthException catch (e) {
      _logger?.error('google_firebase_auth_failed', error: e);
      throw AuthError(
        code: 'auth/firebase_sign_in_failed',
        message: 'Firebase kimlik doğrulama başarısız oldu: ${e.code}',
        cause: e,
      );
    } catch (e) {
      _logger?.error('google_sign_in_failed', error: e);
      throw AuthError(
        code: 'auth/google_sign_in_failed',
        message: 'Google Sign-In başarısız oldu.',
        cause: e,
      );
    }
  }

  Future<UserCredential?> signInWithApple() async {
    if (_auth == null) {
      throw const AuthError(
        code: 'auth/firebase_unavailable',
        message: 'Firebase baslatilamadi veya yapilandirma hatasi.',
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthError(
        code: 'auth/apple_sign_in_ios_only',
        message: 'Apple Sign-In sadece iOS platformunda desteklenir.',
      );
    }

    try {
      final bundle = await _buildAppleCredentialBundle().timeout(
        const Duration(seconds: 90),
      );
      if (bundle == null) {
        return null;
      }

      final userCredential = await _auth.signInWithCredential(
        bundle.credential,
      );
      await _updateDisplayNameIfMissing(
        userCredential: userCredential,
        credentialResult: bundle.result,
      );
      return userCredential;
    } on TimeoutException {
      throw const AuthError(
        code: 'auth/apple_flow_timeout',
        message: 'Apple giris ekrani yanit vermedi.',
      );
    } on FirebaseAuthException catch (e, st) {
      _logger?.error('apple_firebase_auth_failed', error: e, stackTrace: st);
      if (e.code == 'account-exists-with-different-credential') {
        throw const AuthError(
          code: 'auth/account_exists_with_different_credential_apple',
          message: 'Bu e-posta farkli bir giris saglayicisiyla kayitli.',
        );
      }
      if (e.code == 'operation-not-allowed') {
        throw const AuthError(
          code: 'auth/apple_provider_not_enabled',
          message: 'Firebase Apple giris saglayicisi aktif degil.',
        );
      }
      if (e.code == 'invalid-credential' ||
          e.code == 'invalid-identity-token') {
        throw const AuthError(
          code: 'auth/apple_invalid_credential',
          message: 'Apple kimlik bilgisi gecersiz.',
        );
      }
      throw AuthError(
        code: 'auth/apple_sign_in_failed',
        message: 'Apple Sign-In basarisiz oldu: ${e.code}',
        cause: e,
        stackTrace: st,
      );
    } on AuthError {
      rethrow;
    } catch (e, st) {
      _logger?.error('apple_sign_in_failed', error: e, stackTrace: st);
      throw AuthError(
        code: 'auth/apple_sign_in_failed',
        message: 'Apple Sign-In basarisiz oldu.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<UserCredential?> linkAppleToCurrentUser() async {
    if (_auth == null) {
      throw const AuthError(
        code: 'auth/firebase_unavailable',
        message: 'Firebase baslatilamadi veya yapilandirma hatasi.',
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthError(
        code: 'auth/apple_sign_in_ios_only',
        message: 'Apple Sign-In sadece iOS platformunda desteklenir.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthError(
        code: 'auth/no_current_user_for_link',
        message: 'Apple hesabini baglamak icin once giris yapin.',
      );
    }

    final providerIds = user.providerData.map(
      (provider) => provider.providerId,
    );
    if (providerIds.contains('apple.com')) {
      throw const AuthError(
        code: 'auth/provider_already_linked_apple',
        message: 'Apple hesabi zaten bagli.',
      );
    }

    try {
      final bundle = await _buildAppleCredentialBundle().timeout(
        const Duration(seconds: 90),
      );
      if (bundle == null) {
        return null;
      }

      final linkedCredential = await user.linkWithCredential(bundle.credential);
      await _updateDisplayNameIfMissing(
        userCredential: linkedCredential,
        credentialResult: bundle.result,
      );
      return linkedCredential;
    } on TimeoutException {
      throw const AuthError(
        code: 'auth/apple_flow_timeout',
        message: 'Apple baglama ekrani yanit vermedi.',
      );
    } on FirebaseAuthException catch (e, st) {
      _logger?.error('apple_link_failed', error: e, stackTrace: st);
      switch (e.code) {
        case 'provider-already-linked':
          throw const AuthError(
            code: 'auth/provider_already_linked_apple',
            message: 'Apple hesabi zaten bagli.',
          );
        case 'credential-already-in-use':
          throw const AuthError(
            code: 'auth/apple_credential_already_in_use',
            message: 'Bu Apple hesabi baska bir kullaniciya bagli.',
          );
        case 'requires-recent-login':
          throw const AuthError(
            code: 'auth/requires_recent_login_for_link',
            message: 'Apple baglamak icin yeniden kimlik dogrulayin.',
          );
        case 'invalid-credential':
        case 'invalid-identity-token':
          throw const AuthError(
            code: 'auth/apple_invalid_credential',
            message: 'Apple kimlik bilgisi gecersiz.',
          );
        default:
          throw AuthError(
            code: 'auth/apple_link_failed',
            message: 'Apple hesabi baglanamadi.',
            cause: e,
            stackTrace: st,
          );
      }
    } on AuthError {
      rethrow;
    } catch (e, st) {
      _logger?.error('apple_link_failed', error: e, stackTrace: st);
      throw AuthError(
        code: 'auth/apple_link_failed',
        message: 'Apple hesabi baglanamadi.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      // Google local session cleanup can fail on some devices.
      // Firebase sign-out should still proceed.
      _logger?.warn('google_sign_out_failed', error: e, stackTrace: st);
    }

    if (_auth != null) {
      await _auth.signOut();
    }
  }

  Future<_AppleCredentialBundle?> _buildAppleCredentialBundle() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256ofString(rawNonce);
    final result = await _appleSignInClient.requestCredential(
      nonce: hashedNonce,
      scopes: const [
        AppleAuthorizationScope.email,
        AppleAuthorizationScope.fullName,
      ],
    );
    if (result == null) {
      return null;
    }
    final identityToken = result.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const AuthError(
        code: 'auth/apple_missing_identity_token',
        message: 'Apple kimlik tokeni alinamadi.',
      );
    }
    final credential = OAuthProvider(
      'apple.com',
    ).credential(idToken: identityToken, rawNonce: rawNonce);
    return _AppleCredentialBundle(credential: credential, result: result);
  }

  Future<void> _updateDisplayNameIfMissing({
    required UserCredential userCredential,
    required AppleIdCredentialResult credentialResult,
  }) async {
    final user = userCredential.user;
    if (user == null) return;
    if ((user.displayName ?? '').trim().isNotEmpty) return;

    final nameParts = [credentialResult.givenName, credentialResult.familyName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();

    if (nameParts.isEmpty) return;

    try {
      await user.updateDisplayName(nameParts.join(' '));
    } catch (e, st) {
      _logger?.warn(
        'apple_display_name_update_failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}

class _AppleCredentialBundle {
  const _AppleCredentialBundle({
    required this.credential,
    required this.result,
  });

  final OAuthCredential credential;
  final AppleIdCredentialResult result;
}
