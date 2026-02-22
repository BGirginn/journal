import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class TestAuthService extends AuthService {
  TestAuthService({
    this.authStream = const Stream.empty(),
    this.onGoogleSignIn,
    this.onAppleSignIn,
  }) : super(isFirebaseAvailable: false);

  final Stream<User?> authStream;
  final Future<UserCredential?> Function()? onGoogleSignIn;
  final Future<UserCredential?> Function()? onAppleSignIn;

  @override
  Stream<User?> get authStateChanges => authStream;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    return onGoogleSignIn?.call();
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    return onAppleSignIn?.call();
  }
}

Widget _buildTestApp({required AuthService authService}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      firebaseAvailableProvider.overrideWith((ref) => true),
      firebaseErrorProvider.overrideWith((ref) => null),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: LoginScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'iOS renders Apple sign-in button',
    (tester) async {
      final service = TestAuthService(authStream: Stream<User?>.value(null));

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pumpAndSettle();

      expect(find.byType(SignInWithAppleButton), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'Apple cancel flow does not crash',
    (tester) async {
      final service = TestAuthService(
        authStream: Stream<User?>.value(null),
        onAppleSignIn: () async => null,
      );

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'shows account-exists dialog for Apple credential conflicts',
    (tester) async {
      final service = TestAuthService(
        authStream: Stream<User?>.value(null),
        onAppleSignIn: () async {
          throw const AuthError(
            code: 'auth/account_exists_with_different_credential_apple',
            message: 'conflict',
          );
        },
      );

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Use Google to Continue'), findsOneWidget);
      expect(find.text('Continue with Google'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}
