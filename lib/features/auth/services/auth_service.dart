//main backend authentication conf for the app
//the arch = firebase auth + firestore = allow signin by username password

//libraries
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// error. show message directly.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
//firebase auth conf
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // sign in with either an email or a username.
  Future<void> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      var email = identifier.trim();

      if (!email.contains('@')) {
        // Username -> look up the email it belongs to.
        final snap = await _db
            .collection('usernames')
            .doc(email.toLowerCase())
            .get();
        final found = snap.data()?['email'] as String?;
        // Same message as a wrong password, so usernames can't be probed.
        if (found == null || found.isEmpty) {
          throw const AuthFailure('Incorrect username or password.');
        }
        email = found;
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyMessage(e));
    } on FirebaseException {
      throw const AuthFailure('Could not reach the server. Check your connection.');
    }
  }

  // create an account with email + username + password.
  Future<void> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    final name = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();
    User? created;

    try {
      // Friendly early check. The Firestore rules enforce uniqueness anyway.
      final taken = await _db.collection('usernames').doc(name).get();
      if (taken.exists) throw const AuthFailure('That username is already taken.');

      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      created = cred.user;
      if (created == null) {
        throw const AuthFailure('Something went wrong. Please try again.');
      }

      await created.updateDisplayName(name);

      // Profile + username claim are written together, or not at all.
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(created.uid), {
        'uid': created.uid,
        'email': cleanEmail,
        'username': name,
        'displayName': name,
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection('usernames').doc(name), {
        'uid': created.uid,
        'email': cleanEmail,
      });
      await batch.commit();
    } on FirebaseAuthException catch (e) {
      await _rollback(created);
      throw AuthFailure(_friendlyMessage(e));
    } on FirebaseException {
      // e.g. someone grabbed the username a moment ago.
      await _rollback(created);
      throw const AuthFailure(
          'We could not finish creating your account. Try a different username.');
    }
  }

  // Google sign-in.
  // Returns false if the user closed the Google account picker.
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return false;

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw const AuthFailure('Google sign-in failed. Please try again.');
      }

      final ref = _db.collection('users').doc(user.uid);
      if (!(await ref.get()).exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email,
          'username': null,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } on PlatformException {
      throw const AuthFailure(
          'Google sign-in failed. Check your connection and try again.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendlyMessage(e));
    } on FirebaseException {
      throw const AuthFailure('Could not reach the server. Check your connection.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Pretend success for unknown emails so accounts can't be probed.
      if (e.code == 'user-not-found') return;
      throw AuthFailure(_friendlyMessage(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google - nothing to do.
    }
    await _auth.signOut();
  }

  //fallaback =  removes a half-created account so the user can retry cleanly.
  Future<void> _rollback(User? user) async {
    try {
      await user?.delete();
    } catch (_) {}
  }

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect username or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}