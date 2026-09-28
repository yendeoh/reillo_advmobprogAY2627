// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Prefixed because firebase_auth also exports a class named User.
import '../models/user.dart' as app;

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  // Keys that belong to the signed-in session; logout removes only these.
  static const _sessionKeys = [
    'id',
    'uid',
    'username',
    'email',
    'firstName',
    'lastName',
    'gender',
    'image',
    'age',
    'phone',
    'accessToken',
    'refreshToken',
    'token',
    'loginType',
  ];

  // ENHANCEMENT 2: Authenticate against DummyJSON and persist the response so
  // the session can be restored by SplashScreen on a later app launch.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = app.LoginType.dummyJson.name;
      await saveUserData(data);
      return data;
    } else {
      throw Exception(_dummyJsonMessage(response));
    }
  }

  /// LAB ACT 5: DummyJSON sign up. /users/add only *simulates* the insert —
  /// it echoes the new user back with an id, but that account cannot log in.
  Future<Map<String, dynamic>> signUpDummyJson(
    Map<String, dynamic> profile,
  ) async {
    final response = await http.post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_dummyJsonMessage(response));
    }
  }

  /// LAB ACT 5: DummyJSON update (simulated). Used for username and password.
  Future<Map<String, dynamic>> updateDummyJsonUser(
    int id,
    Map<String, dynamic> changes,
  ) async {
    final response = await http.put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(changes),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_dummyJsonMessage(response));
    }
  }

  /// LAB ACT 5: DummyJSON delete (simulated), then clear the local session.
  Future<void> deleteDummyJsonUser(int id) async {
    final response = await http.delete(Uri.parse('$host/users/$id'));

    if (response.statusCode != 200) {
      throw Exception(_dummyJsonMessage(response));
    }
    await logout();
  }

  String _dummyJsonMessage(http.Response response) {
    try {
      return jsonDecode(response.body)['message'] ?? response.body;
    } catch (_) {
      return response.body;
    }
  }

  /// **Save User Data to SharedPreferences**
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = app.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('uid', user.uid);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', user.loginType.name);

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? app.LoginType.dummyJson.name,
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<app.User> getUser() async {
    final userData = await getUserData();
    return app.User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  /// DummyJSON sessions are a saved token; Firebase sessions are restored by
  /// the SDK itself, so we wait for its first auth state before deciding.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = app.LoginType.fromName(prefs.getString('loginType'));

    if (loginType == app.LoginType.firebase) {
      final user = await firebaseAuth.authStateChanges().first;
      return user != null;
    }

    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// **Logout and Clear User Data**
  /// Signs out of Firebase (a no-op for DummyJSON sessions) and removes the
  /// saved session, so the next launch lands on the sign-in screen.
  Future<void> logout() async {
    try {
      if (currentUser != null) await signOut();
      final prefs = await SharedPreferences.getInstance();
      for (final key in _sessionKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // Your previous code here
  // Just add this code under the previous code

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // LAB ACT 5: Firebase helpers built on the functions above.
  // LAB ACT 6: Firebase Auth only stores email, password and display name,
  // so each account also gets a Firestore document at Users/{uid} holding the
  // sign-up profile. The chat list reads this collection to show every
  // registered user.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      firestore.collection('Users').doc(uid);

  /// Create a Firebase account, set its display name to the username, save
  /// the profile to Firestore, and start the session.
  Future<app.User> firebaseSignUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
    required String phone,
  }) async {
    final credential = await createAccount(email: email, password: password);
    await updateUsername(username: username);

    await _userDoc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return _saveFirebaseSession(credential.user!);
  }

  /// Sign in with Firebase and save the session in the same shape as the
  /// DummyJSON one, so every screen reads it through getUserData().
  Future<app.User> firebaseSignIn({
    required String email,
    required String password,
  }) async {
    final credential = await signIn(email: email, password: password);
    return _saveFirebaseSession(credential.user!);
  }

  Future<app.User> _saveFirebaseSession(User firebaseUser) async {
    // reload() so a display name set during sign up is visible immediately.
    await firebaseUser.reload();
    final user = currentUser ?? firebaseUser;

    // Accounts made before Lab 6 have no Users document yet; merge creates
    // one with what Auth knows, so they still show up in the chat list.
    final doc = _userDoc(user.uid);
    await doc.set({
      'uid': user.uid,
      'email': user.email ?? '',
      if ((user.displayName ?? '').isNotEmpty) 'username': user.displayName,
    }, SetOptions(merge: true));
    final profile = (await doc.get()).data() ?? {};

    // The SDK refreshes the ID token on its own; this just caches the latest.
    final idToken = await user.getIdToken() ?? '';
    final sessionData = {
      'firstName': profile['firstName'] ?? '',
      'lastName': profile['lastName'] ?? '',
      'age': profile['age'] ?? 0,
      'phone': profile['phone'] ?? '',
      'uid': user.uid,
      'username': user.displayName ?? profile['username'] ?? '',
      'email': user.email ?? '',
      'image': user.photoURL ?? '',
      'accessToken': idToken,
      'refreshToken': user.refreshToken ?? '',
      'loginType': app.LoginType.firebase.name,
    };
    await saveUserData(sessionData);
    return app.User.fromJson(sessionData);
  }

  /// Update the username on whichever backend owns the session.
  Future<void> changeUsername(app.User user, String username) async {
    if (user.loginType == app.LoginType.firebase) {
      await updateUsername(username: username);
      await _userDoc(user.uid).update({'username': username});
    } else {
      await updateDummyJsonUser(user.id, {'username': username});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  /// Change the password on whichever backend owns the session. Firebase
  /// re-authenticates with the current password first.
  Future<void> changePassword(
    app.User user, {
    required String currentPassword,
    required String newPassword,
  }) async {
    if (user.loginType == app.LoginType.firebase) {
      await resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: user.email,
      );
    } else {
      await updateDummyJsonUser(user.id, {'password': newPassword});
    }
  }

  /// Delete the account on whichever backend owns the session, then clear it.
  Future<void> removeAccount(app.User user, {required String password}) async {
    if (user.loginType == app.LoginType.firebase) {
      // Check the password before touching data, then remove the Users
      // document while still signed in (the rules need an authenticated user).
      await currentUser!.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email, password: password),
      );
      await _userDoc(user.uid).delete();
      await deleteAccount(email: user.email, password: password);
      await logout();
    } else {
      await deleteDummyJsonUser(user.id);
    }
  }

  /// Readable messages for the Firebase Auth error codes users actually hit.
  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'That password is too weak.';
        case 'requires-recent-login':
          return 'Please sign in again before doing that.';
        case 'too-many-requests':
          return 'Too many attempts. Try again in a few minutes.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase.';
      }
      return error.message ?? error.code;
    }
    // Firestore errors (FirebaseAuthException is handled above).
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore rules blocked this request.';
      }
      if (error.code == 'unavailable') return 'No internet connection.';
      return error.message ?? error.code;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
