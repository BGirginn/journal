import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum AppleAuthorizationScope { email, fullName }

class AppleIdCredentialResult {
  const AppleIdCredentialResult({
    required this.identityToken,
    required this.authorizationCode,
    required this.givenName,
    required this.familyName,
    required this.email,
  });

  final String? identityToken;
  final String? authorizationCode;
  final String? givenName;
  final String? familyName;
  final String? email;
}

abstract class AppleSignInClient {
  Future<AppleIdCredentialResult?> requestCredential({
    required String nonce,
    required List<AppleAuthorizationScope> scopes,
  });
}

class AppleSignInClientImpl implements AppleSignInClient {
  const AppleSignInClientImpl();

  @override
  Future<AppleIdCredentialResult?> requestCredential({
    required String nonce,
    required List<AppleAuthorizationScope> scopes,
  }) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: scopes.map(_mapScope).toList(),
        nonce: nonce,
      );
      return AppleIdCredentialResult(
        identityToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
        email: credential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  AppleIDAuthorizationScopes _mapScope(AppleAuthorizationScope scope) {
    switch (scope) {
      case AppleAuthorizationScope.email:
        return AppleIDAuthorizationScopes.email;
      case AppleAuthorizationScope.fullName:
        return AppleIDAuthorizationScopes.fullName;
    }
  }
}
