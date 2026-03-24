import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId; // Store this to verify OTP later
  int? _resendToken; // For resending OTP (Android only)

  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // e.g., '+911234567890' (include country code)
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification on Android (rarely on iOS)
        await _auth.signInWithCredential(credential);
        print('Auto signed in');
      },

      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.message}');
        // Handle errors (invalid number, quota exceeded, etc.)
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        print('OTP sent! Enter code on next screen.');
        // Navigate to OTP input screen
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        print('Auto retrieval timeout');
      },

      forceResendingToken: _resendToken, // For manual resend
    );
  }
}
