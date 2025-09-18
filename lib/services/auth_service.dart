import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  // Email + password sign in
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Email + password register
  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Save user data in Firestore
  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Send password reset
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  // Phone: verify phone number
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onFailed,
    required Function(UserCredential user) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await _auth.signInWithCredential(credential);
        onAutoVerified(userCred);
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? e.code);
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Sign in with SMS code
  Future<UserCredential> signInWithSmsCode(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return (userDoc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() => _auth.signOut();

  // Logout (alias for signOut)
  Future<void> logout() => signOut();
}
