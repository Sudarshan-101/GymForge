import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentEmail => _auth.currentUser?.email;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new Gym Owner
  Future<Map<String, dynamic>> registerOwner({
    required String name,
    required String email,
    required String password,
    required String gymName,
    required String gymAddress,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final gymId = 'gym_${uid.substring(0, 8)}';

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'owner',
        'gymId': gymId,
        'gymName': gymName,
        'gymAddress': gymAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('gyms').doc(gymId).set({
        'gymId': gymId,
        'gymName': gymName,
        'gymAddress': gymAddress,
        'ownerUid': uid,
        'ownerName': name,
        'ownerEmail': email,
        'totalMembers': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'gymId': gymId};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: ${e.toString()}'};
    }
  }

  /// Sign in with email & password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return {'success': false, 'error': 'Account not found.'};
      }

      final data = doc.data()!;
      if (data['role'] != 'owner') {
        await _auth.signOut();
        return {'success': false, 'error': 'This login is for Gym Owners only.'};
      }

      return {'success': true, 'data': data};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _authErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'Sign in failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>?> getOwnerProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async => _auth.signOut();

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':       return 'Incorrect password.';
      case 'invalid-credential':   return 'Incorrect email or password.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Please enter a valid email address.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'too-many-requests':    return 'Too many attempts. Please try again later.';
      case 'network-request-failed': return 'Network error. Check your connection.';
      default:                     return 'Authentication failed ($code). Please try again.';
    }
  }
}
