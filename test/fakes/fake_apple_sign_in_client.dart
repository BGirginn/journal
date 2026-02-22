import 'package:journal_app/core/auth/apple_sign_in_client.dart';

class FakeAppleSignInClient implements AppleSignInClient {
  FakeAppleSignInClient({this.result, this.error});

  final AppleIdCredentialResult? result;
  final Object? error;

  @override
  Future<AppleIdCredentialResult?> requestCredential({
    required String nonce,
    required List<AppleAuthorizationScope> scopes,
  }) async {
    if (error != null) throw error!;
    return result;
  }
}
