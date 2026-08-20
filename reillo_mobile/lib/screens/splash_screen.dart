// lib/screens/splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/user_service.dart';

// ENHANCEMENT 1: This custom splash screen restores the persistent session
// before showing the app. A saved token routes the user to /home; otherwise
// the user is sent to the sign-in screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();
  Timer? _authTimer;

  @override
  void initState() {
    super.initState();
    _authTimer = Timer(
      const Duration(milliseconds: 1500),
      _checkAuthentication,
    );
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202B62),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC857),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 58,
                color: Color(0xFF202B62),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NUBD Exchange',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your everyday essentials, made simple.',
              style: TextStyle(color: Color(0xFFD9DDF2), fontSize: 14),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Color(0xFFFFC857),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
