import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// guestMode removed

final firebaseErrorProvider = StateProvider<String?>((ref) => null);

final firebaseAvailableProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  final isAvailable = ref.watch(firebaseAvailableProvider);
  return AuthService(isFirebaseAvailable: isAvailable);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthService {
  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService({bool isFirebaseAvailable = true})
    : _auth = isFirebaseAvailable ? FirebaseAuth.instance : null;

  Stream<User?> get authStateChanges {
    // _auth is guaranteed to be non-null when initialized with isFirebaseAvailable=true
    if (_auth != null) {
      return _auth.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    if (_auth == null) {
      throw Exception('Firebase başlatılamadı veya yapılandırma hatası.');
    }
    try {
      // Force account picker by clearing previous session
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign In Failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    if (_auth != null) {
      await _auth.signOut();
    }
  }
}
