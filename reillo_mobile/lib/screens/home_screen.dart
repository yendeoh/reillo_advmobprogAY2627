import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: Image.asset(
            'assets/images/nubdexchange_logo.png',
            scale: 11.sp,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: const ProductScreen(),
        // LAB ACT 6: the chat FloatingActionButton opens the Chat List UI.
        floatingActionButton: FloatingActionButton(
          tooltip: 'Messages',
          backgroundColor: const Color(0xFF202B62),
          foregroundColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}
