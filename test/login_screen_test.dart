import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:journal_app/features/auth/login_screen.dart';
import 'package:journal_app/l10n/app_localizations.dart';

class TestAuthService extends AuthService {
  TestAuthService({this.authStream = const Stream.empty(), this.onGoogleSignIn})
    : super(isFirebaseAvailable: false);

  final Stream<User?> authStream;
  final Future<UserCredential?> Function()? onGoogleSignIn;

  @override
  Stream<User?> get authStateChanges => authStream;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    return onGoogleSignIn?.call();
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    return null;
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
    'iOS renders Gmail sign-in button',
    (tester) async {
      final service = TestAuthService(authStream: Stream<User?>.value(null));

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Gmail'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'Android renders Gmail sign-in button',
    (tester) async {
      final service = TestAuthService(authStream: Stream<User?>.value(null));

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Gmail'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'Gmail cancel flow does not crash',
    (tester) async {
      final service = TestAuthService(
        authStream: Stream<User?>.value(null),
        onGoogleSignIn: () async => null,
      );

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue with Gmail'));
      await tester.tap(find.text('Continue with Gmail'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'shows account-exists message for sign-in conflicts',
    (tester) async {
      final service = TestAuthService(
        authStream: Stream<User?>.value(null),
        onGoogleSignIn: () async {
          throw const AuthError(
            code: 'auth/account_exists_with_different_credential_apple',
            message: 'conflict',
          );
        },
      );

      await tester.pumpWidget(_buildTestApp(authService: service));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('Continue with Gmail'));
      await tester.tap(find.text('Continue with Gmail'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('This email is already registered with your Google account.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}
