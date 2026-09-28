import 'package:flutter/material.dart';

// LAB ACT 6: Small display helpers shared by the chat list and chat detail.
class ChatFormat {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "9:41 AM" — the time shown on a chat bubble.
  static String time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Time today, "Yesterday", or "Sep 27" — the chat list timestamp.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    final difference = today.difference(day).inDays;
    if (difference == 0) return time(date);
    if (difference == 1) return 'Yesterday';
    return '${_months[date.month - 1]} ${date.day}';
  }

  /// "Today", "Yesterday", or "September 27" style day separator label.
  static String dayLabel(DateTime date, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final difference = today.difference(DateUtils.dateOnly(date)).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    final label = '${_months[date.month - 1]} ${date.day}';
    return date.year == today.year ? label : '$label, ${date.year}';
  }

  /// Full name, falling back to the username, then the email.
  static String displayName(Map<String, dynamic> user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    final username = (user['username'] ?? '').toString();
    if (username.isNotEmpty) return username;
    return (user['email'] ?? 'Unknown').toString();
  }

  static String initial(Map<String, dynamic> user) {
    final name = displayName(user);
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  static const _avatarColors = [
    Color(0xFF202B62),
    Color(0xFF2E7D6B),
    Color(0xFF8E4B9E),
    Color(0xFFC0562F),
    Color(0xFF3867B5),
    Color(0xFF9A7B12),
  ];

  /// A stable avatar color per user, so each person keeps their color.
  static Color avatarColor(String uid) {
    final hash = uid.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _avatarColors[hash % _avatarColors.length];
  }

  /// LAB ACT 6 - ENHANCEMENT 2: true when the search text appears in the
  /// user's name, username or email (case-insensitive).
  static bool matches(Map<String, dynamic> user, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final haystack = [
      user['firstName'],
      user['lastName'],
      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
      user['username'],
      user['email'],
    ].whereType<String>().map((value) => value.toLowerCase());
    return haystack.any((value) => value.contains(needle));
  }
}
