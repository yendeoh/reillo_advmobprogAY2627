import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reillo_mobile/widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../utils/chat_format.dart';

final ChatService chatService = ChatService();

const _navy = Color(0xFF202B62);
const _gold = Color(0xFFFFC857);

// LAB ACT 6 - ENHANCEMENT 3: Redesigned chat detail screen.
// - Sender bubbles are navy on the right, receiver bubbles white on the left,
//   with a flattened "tail" corner and grouping of consecutive messages.
// - Each of my messages shows its state: "sending…" while the write is only
//   local (Firestore's pending write), ✓ once the server has it, and ✓✓ in
//   gold once the other person has opened the chat (the `seen` field).
// - New messages fade and slide in; the send button animates in and out.
class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  Stream<QuerySnapshot>? _messagesStream;
  bool _hasText = false;

  // Message ids already on screen. Only ids that arrive after the first
  // snapshot animate in, so opening a long chat doesn't replay every bubble.
  final Set<String> _knownIds = {};
  bool _initialLoadDone = false;
  // Seen updates already requested, so each message is written only once.
  final Set<String> _seenRequested = {};

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Clear right away; the bubble appears instantly as a pending write and
    // its status icon tracks delivery, so the composer never has to wait.
    _msgCtrl.clear();
    _msgFocus.requestFocus();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (!mounted) return;
      // Put the text back so nothing typed is lost.
      if (_msgCtrl.text.isEmpty) _msgCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: ${UserService.errorMessage(e)}'),
        ),
      );
    }
  }

  /// Mark the other person's unseen messages as seen while this chat is open.
  void _markSeen(List<QueryDocumentSnapshot> docs, String currentUserId) {
    final unseen = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['senderId'] != currentUserId &&
          data['seen'] != true &&
          !_seenRequested.contains(doc.id);
    }).toList();
    if (unseen.isEmpty) return;

    _seenRequested.addAll(unseen.map((doc) => doc.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatService.markAsSeen(unseen.map((doc) => doc.reference).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = ChatFormat.displayName(widget.tappedUser);

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;
        _messagesStream ??= chatService.getMessage(currentUserId, tappedUserId);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F3F9),
          appBar: AppBar(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            titleSpacing: 0,
            title: Row(
              children: [
                Hero(
                  tag: 'avatar-$tappedUserId',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: ChatFormat.avatarColor(tappedUserId),
                    child: CustomText(
                      text: ChatFormat.initial(widget.tappedUser),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: tappedUserName,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CustomText(
                        text: (widget.tappedUser['email'] ?? '').toString(),
                        fontSize: 11.sp,
                        color: Colors.white70,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Error loading messages: '
                            '${UserService.errorMessage(snapshot.error!)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    _markSeen(docs, currentUserId);

                    if (!_initialLoadDone) {
                      _knownIds.addAll(docs.map((doc) => doc.id));
                      _initialLoadDone = true;
                    }

                    if (docs.isEmpty) {
                      return _EmptyChat(name: tappedUserName);
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final time =
                            (data['timestamp'] as Timestamp?)?.toDate() ??
                            DateTime.now();

                        // The list is reversed: index + 1 is the older message.
                        final older = index + 1 < docs.length
                            ? docs[index + 1].data() as Map<String, dynamic>
                            : null;
                        final olderTime = (older?['timestamp'] as Timestamp?)
                            ?.toDate();
                        final startsDay =
                            olderTime == null ||
                            !DateUtils.isSameDay(olderTime, time);
                        final groupedWithOlder =
                            !startsDay && older?['senderId'] == senderId;

                        final animate = _knownIds.add(doc.id);

                        return Column(
                          children: [
                            if (startsDay) _DaySeparator(date: time),
                            _AnimatedEntry(
                              key: ValueKey(doc.id),
                              animate: animate,
                              fromRight: isMe,
                              child: _MessageBubble(
                                text: (data['message'] ?? '').toString(),
                                time: time,
                                isMe: isMe,
                                status: isMe
                                    ? _statusOf(doc, data)
                                    : _MessageStatus.none,
                                groupedWithOlder: groupedWithOlder,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              _Composer(
                controller: _msgCtrl,
                focusNode: _msgFocus,
                canSend: _hasText,
                onSend: () => _send(currentUserId, tappedUserId),
              ),
            ],
          ),
        );
      },
    );
  }

  _MessageStatus _statusOf(DocumentSnapshot doc, Map<String, dynamic> data) {
    if (doc.metadata.hasPendingWrites) return _MessageStatus.sending;
    if (data['seen'] == true) return _MessageStatus.seen;
    return _MessageStatus.delivered;
  }
}

enum _MessageStatus { none, sending, delivered, seen }

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.status,
    required this.groupedWithOlder,
  });

  final String text;
  final DateTime time;
  final bool isMe;
  final _MessageStatus status;
  final bool groupedWithOlder;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    // The corner nearest the sender flattens into a tail on the last bubble
    // of a group; grouped bubbles share flattened inner corners.
    final radius = BorderRadius.only(
      topLeft: !isMe && groupedWithOlder ? tail : round,
      topRight: isMe && groupedWithOlder ? tail : round,
      bottomLeft: !isMe ? tail : round,
      bottomRight: isMe ? tail : round,
    );
    final foreground = isMe ? Colors.white : const Color(0xFF1C1F2E);
    final meta = isMe ? Colors.white70 : Colors.black45;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: groupedWithOlder ? 2 : 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? _navy : Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: CustomText(
                text: text.isNotEmpty ? text : "[empty]",
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
                textAlign: TextAlign.left,
                color: foreground,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: status == _MessageStatus.sending
                      ? 'sending…'
                      : ChatFormat.time(time),
                  fontSize: 10.5,
                  color: meta,
                  fontStyle: status == _MessageStatus.sending
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                if (status != _MessageStatus.none) ...[
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: _StatusIcon(status: status, key: ValueKey(status)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({super.key, required this.status});

  final _MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _MessageStatus.sending:
        return const Icon(Icons.schedule, size: 13, color: Colors.white70);
      case _MessageStatus.delivered:
        return const Tooltip(
          message: 'Delivered',
          child: Icon(Icons.done, size: 15, color: Colors.white70),
        );
      case _MessageStatus.seen:
        return const Tooltip(
          message: 'Seen',
          child: Icon(Icons.done_all, size: 15, color: _gold),
        );
      case _MessageStatus.none:
        return const SizedBox.shrink();
    }
  }
}

/// Fades and slides a new message in from its sender's side.
class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({
    super.key,
    required this.animate,
    required this.fromRight,
    required this.child,
  });

  final bool animate;
  final bool fromRight;
  final Widget child;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.fromRight ? 0.15 : -0.15, 0.35),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x14202B62),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomText(
            text: ChatFormat.dayLabel(date),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.waving_hand_outlined, color: _navy),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'No messages yet',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 4),
            CustomText(text: 'Say hi to $name!', fontSize: 13),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => canSend ? onSend() : null,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: const TextStyle(fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F9),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: canSend ? 1 : 0.85,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: canSend ? _navy : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Send',
                    icon: const Icon(Icons.send_rounded),
                    color: canSend ? Colors.white : Colors.black38,
                    onPressed: canSend ? onSend : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
