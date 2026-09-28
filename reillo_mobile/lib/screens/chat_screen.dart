import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../utils/chat_format.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

// LAB ACT 6: Chat list, opened from the chat FloatingActionButton on Home.
// ENHANCEMENT 1: lists every registered user from the Firestore Users
// collection except the signed-in user.
// ENHANCEMENT 2: the search bar filters by name, username or email as you type.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _searchText = '';

  // Created once so rebuilds (e.g. typing in search) don't resubscribe.
  late final Stream<List<Map<String, dynamic>>> _usersStream = _chatService
      .getOtherUsersStream();
  late final Stream<Map<String, Map<String, dynamic>>> _roomsStream =
      _chatService.getMyChatRoomsStream();

  // Chat needs a Firebase account: DummyJSON users have no uid in Firestore.
  bool get _hasFirebaseSession => userService.value.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          currentUserEmail: _currentUserEmail ?? '',
          tappedUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202B62),
        foregroundColor: Colors.white,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _hasFirebaseSession ? _buildChatList() : _buildFirebaseRequired(),
    );
  }

  Widget _buildFirebaseRequired() {
    return _CenteredMessage(
      icon: Icons.local_fire_department_outlined,
      title: 'Chat uses Firebase',
      message:
          'You are signed in with DummyJSON. Log out and sign in with a '
          'Firebase account to message other users.',
      action: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF202B62)),
        onPressed: () async {
          await userService.value.logout();
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (_) => false);
        },
        child: const Text('Sign in with Firebase'),
      ),
    );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: TextField(
            controller: _searchChatController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _searchChatController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        setState(() {
                          _searchChatController.clear();
                          _searchText = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          // Users Stream
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasError) {
                return _CenteredMessage(
                  icon: Icons.error_outline,
                  title: 'Error loading users',
                  message: UserService.errorMessage(snapshot.error!),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const _CenteredMessage(
                  icon: Icons.group_outlined,
                  title: 'No users found',
                  message: 'Other people appear here once they sign up.',
                );
              }

              return StreamBuilder<Map<String, Map<String, dynamic>>>(
                stream: _roomsStream,
                builder: (context, roomSnapshot) {
                  final rooms = roomSnapshot.data ?? {};
                  final users = snapshot.data!
                      .where((user) => ChatFormat.matches(user, _searchText))
                      .toList();
                  _sortByRecentChat(users, rooms);

                  if (users.isEmpty) {
                    return _CenteredMessage(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'Nobody matches "${_searchText.trim()}".',
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserTile(
                        user: user,
                        room: rooms[user['uid']],
                        currentUid: userService.value.currentUser?.uid,
                        onTap: () => _openChat(user),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// People you've chatted with come first, most recent on top; everyone
  /// else follows alphabetically.
  void _sortByRecentChat(
    List<Map<String, dynamic>> users,
    Map<String, Map<String, dynamic>> rooms,
  ) {
    users.sort((a, b) {
      final aTime = rooms[a['uid']]?['lastTimestamp'] as Timestamp?;
      final bTime = rooms[b['uid']]?['lastTimestamp'] as Timestamp?;
      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return ChatFormat.displayName(
        a,
      ).toLowerCase().compareTo(ChatFormat.displayName(b).toLowerCase());
    });
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.room,
    required this.currentUid,
    required this.onTap,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic>? room;
  final String? currentUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = room?['lastMessage'] as String?;
    final lastTime = room?['lastTimestamp'] as Timestamp?;
    final sentByMe = room?['lastSenderId'] == currentUid;
    final preview = lastMessage == null
        ? (user['email'] ?? 'No email').toString()
        : '${sentByMe ? 'You: ' : ''}$lastMessage';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Hero(
                tag: "avatar-${user['uid']}",
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: ChatFormat.avatarColor(
                    (user['uid'] ?? '').toString(),
                  ),
                  child: CustomText(
                    text: ChatFormat.initial(user),
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: ChatFormat.displayName(user),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      text: preview,
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (lastTime != null) ...[
                const SizedBox(width: 8),
                CustomText(
                  text: ChatFormat.relativeDay(lastTime.toDate()),
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            CustomText(
              text: title,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            CustomText(
              text: message,
              fontSize: 13,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
