import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }

  /// LAB ACT 6 - ENHANCEMENT 1: every registered user except the one signed
  /// in, so you can't open a chat with yourself from the list.
  Stream<List<Map<String, dynamic>>> getOtherUsersStream() {
    final currentUid = _firebaseAuth.currentUser?.uid;
    return getUsersStream().map(
      (users) => users.where((user) => user['uid'] != currentUid).toList(),
    );
  }

  /// LAB ACT 6: the chat rooms the signed-in user belongs to, keyed by the
  /// other participant's uid, so the chat list can show the last message.
  Stream<Map<String, Map<String, dynamic>>> getMyChatRoomsStream() {
    final currentUid = _firebaseAuth.currentUser?.uid;
    if (currentUid == null) return Stream.value({});

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final rooms = <String, Map<String, dynamic>>{};
          for (final doc in snapshot.docs) {
            final room = doc.data();
            final participants = List<String>.from(room['participants'] ?? []);
            final otherUid = participants.firstWhere(
              (uid) => uid != currentUid,
              orElse: () => currentUid,
            );
            rooms[otherUid] = room;
          }
          return rooms;
        });
  }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join("_");

    final chatRoom = _firestore.collection("chat_rooms").doc(chatRoomID);

    // LAB ACT 6: one batch writes the chat room document (participants and a
    // last-message preview for the chat list) together with the message, so
    // both land or neither does. The message shows up locally right away as
    // a pending write, before the server confirms it.
    final batch = _firestore.batch();
    batch.set(chatRoom, {
      'participants': ids,
      'lastMessage': message,
      'lastSenderId': currentUserId,
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));

    // add new message to database
    batch.set(chatRoom.collection("messages").doc(), newMessage.toMap());
    await batch.commit();
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [userID, otherUserID];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join("_");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        // LAB ACT 6 - ENHANCEMENT 3: also emit when a pending local write is
        // confirmed by the server, which drives the "sending…" -> ✓ state.
        .snapshots(includeMetadataChanges: true);
  }

  /// LAB ACT 6 - ENHANCEMENT 3: mark the other user's messages as seen.
  Future<void> markAsSeen(List<DocumentReference> messages) async {
    if (messages.isEmpty) return;
    final batch = _firestore.batch();
    for (final message in messages) {
      batch.update(message, {'seen': true});
    }
    await batch.commit();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field `uid`
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
