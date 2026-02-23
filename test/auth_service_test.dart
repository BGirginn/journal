import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journal_app/core/auth/apple_sign_in_client.dart';
import 'package:journal_app/core/auth/auth_service.dart';
import 'package:journal_app/core/errors/app_error.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes/fake_apple_sign_in_client.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserInfo extends Mock implements UserInfo {}

class FakeAuthCredential extends Fake implements AuthCredential {}

Matcher _authErrorCode(String code) =>
    isA<AuthError>().having((error) => error.code, 'code', code);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('signInWithApple throws when firebase is unavailable', () async {
    final authService = AuthService(
      isFirebaseAvailable: false,
      appleSignInClient: FakeAppleSignInClient(),
    );

    expect(
      authService.signInWithApple,
      throwsA(_authErrorCode('auth/firebase_unavailable')),
    );
  });

  test('signInWithApple throws on non-iOS platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final firebaseAuth = MockFirebaseAuth();
    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(),
    );

    expect(
      authService.signInWithApple,
      throwsA(_authErrorCode('auth/apple_sign_in_ios_only')),
    );
  });

  test('signInWithApple returns null when user cancels', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final firebaseAuth = MockFirebaseAuth();
    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(result: null),
    );

    final result = await authService.signInWithApple();

    expect(result, isNull);
    verifyNever(() => firebaseAuth.signInWithCredential(any()));
  });

  test('signInWithApple throws when identity token is missing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final firebaseAuth = MockFirebaseAuth();
    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(
        result: const AppleIdCredentialResult(
          identityToken: null,
          authorizationCode: null,
          givenName: 'Ada',
          familyName: 'Lovelace',
          email: 'ada@example.com',
        ),
      ),
    );

    expect(
      authService.signInWithApple,
      throwsA(_authErrorCode('auth/apple_missing_identity_token')),
    );
  });

  test(
    'signInWithApple maps account-exists-with-different-credential error',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final firebaseAuth = MockFirebaseAuth();
      when(() => firebaseAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'account-exists-with-different-credential'),
      );

      final authService = AuthService(
        isFirebaseAvailable: true,
        auth: firebaseAuth,
        appleSignInClient: FakeAppleSignInClient(
          result: const AppleIdCredentialResult(
            identityToken: 'token',
            authorizationCode: 'code',
            givenName: null,
            familyName: null,
            email: null,
          ),
        ),
      );

      expect(
        authService.signInWithApple,
        throwsA(
          _authErrorCode('auth/account_exists_with_different_credential_apple'),
        ),
      );
    },
  );

  test('getCurrentProviderIds returns active provider ids', () {
    final firebaseAuth = MockFirebaseAuth();
    final user = MockUser();
    final googleInfo = MockUserInfo();
    final appleInfo = MockUserInfo();

    when(() => googleInfo.providerId).thenReturn('google.com');
    when(() => appleInfo.providerId).thenReturn('apple.com');
    when(() => user.providerData).thenReturn([googleInfo, appleInfo]);
    when(() => firebaseAuth.currentUser).thenReturn(user);

    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(),
    );

    expect(authService.getCurrentProviderIds(), {'google.com', 'apple.com'});
  });

  test('linkAppleToCurrentUser rejects when provider already linked', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final firebaseAuth = MockFirebaseAuth();
    final user = MockUser();
    final appleInfo = MockUserInfo();

    when(() => appleInfo.providerId).thenReturn('apple.com');
    when(() => user.providerData).thenReturn([appleInfo]);
    when(() => firebaseAuth.currentUser).thenReturn(user);

    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(),
    );

    expect(
      authService.linkAppleToCurrentUser,
      throwsA(_authErrorCode('auth/provider_already_linked_apple')),
    );
  });

  test('linkAppleToCurrentUser maps requires-recent-login error', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final firebaseAuth = MockFirebaseAuth();
    final user = MockUser();
    final googleInfo = MockUserInfo();

    when(() => googleInfo.providerId).thenReturn('google.com');
    when(() => user.providerData).thenReturn([googleInfo]);
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(
      () => user.linkWithCredential(any()),
    ).thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(
        result: const AppleIdCredentialResult(
          identityToken: 'token',
          authorizationCode: 'code',
          givenName: null,
          familyName: null,
          email: null,
        ),
      ),
    );

    expect(
      authService.linkAppleToCurrentUser,
      throwsA(_authErrorCode('auth/requires_recent_login_for_link')),
    );
  });

  test('signInWithApple updates display name when missing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final firebaseAuth = MockFirebaseAuth();
    final userCredential = MockUserCredential();
    final user = MockUser();

    when(() => userCredential.user).thenReturn(user);
    when(() => user.displayName).thenReturn('');
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(
      () => firebaseAuth.signInWithCredential(any()),
    ).thenAnswer((_) async => userCredential);

    final authService = AuthService(
      isFirebaseAvailable: true,
      auth: firebaseAuth,
      appleSignInClient: FakeAppleSignInClient(
        result: const AppleIdCredentialResult(
          identityToken: 'token',
          authorizationCode: 'code',
          givenName: 'Ada',
          familyName: 'Lovelace',
          email: 'ada@example.com',
        ),
      ),
    );

    await authService.signInWithApple();

    verify(() => user.updateDisplayName('Ada Lovelace')).called(1);
  });

  test(
    'signOut continues with Firebase signOut when Google signOut fails',
    () async {
      final firebaseAuth = MockFirebaseAuth();
      final googleSignIn = MockGoogleSignIn();

      when(
        () => googleSignIn.signOut(),
      ).thenThrow(Exception('google sign-out failed'));
      when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

      final authService = AuthService(
        isFirebaseAvailable: true,
        auth: firebaseAuth,
        googleSignIn: googleSignIn,
        appleSignInClient: FakeAppleSignInClient(),
      );

      await authService.signOut();

      verify(() => googleSignIn.signOut()).called(1);
      verify(() => firebaseAuth.signOut()).called(1);
    },
  );
}
