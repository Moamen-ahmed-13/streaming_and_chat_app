import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService(this._auth, this._firestore, this._googleSignIn);

  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> registerWithEmail(
    String email, 
    String password, 
    String displayName,
  ) async {
    try {
      AppLogger.info('Registering user: $email');
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(displayName);

      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
      
      AppLogger.info('User registered successfully: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Registration failed', e);
      throw _handleAuthException(e);
    }
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      AppLogger.info('Logging in user: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        throw Exception('User data not found');
      }

      AppLogger.info('User logged in successfully: ${user.uid}');
      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Login failed', e);
      throw _handleAuthException(e);
    }
  }

 Future<UserModel> signInWithGoogle() async {
  try {
    AppLogger.info('Signing in with Google');

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    UserModel userModel;
    if (!doc.exists) {
      userModel = UserModel(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
    } else {
      userModel = UserModel.fromJson(doc.data()!);
    }

    AppLogger.info('Google sign in successful: ${user.uid}');
    return userModel;

  } catch (e, stackTrace) {
    AppLogger.error('Google sign in failed', e, stackTrace);
    rethrow;
  }
}

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Password reset failed', e);
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('Logging out user');
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.info('User logged out successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Logout failed', e, stackTrace);
      rethrow;
    }
  }

  Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return UserModel.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user data', e, stackTrace);
      rethrow;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}