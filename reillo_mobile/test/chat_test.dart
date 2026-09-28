import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reillo_mobile/models/message.dart';
import 'package:reillo_mobile/utils/chat_format.dart';

void main() {
  final juan = {
    'uid': 'u1',
    'firstName': 'Juan',
    'lastName': 'Dela Cruz',
    'username': 'juandc',
    'email': 'juan@example.com',
  };

  group('ChatFormat.matches (search)', () {
    test('matches first, last and full name, case-insensitively', () {
      expect(ChatFormat.matches(juan, 'juan'), isTrue);
      expect(ChatFormat.matches(juan, 'CRUZ'), isTrue);
      expect(ChatFormat.matches(juan, 'juan dela'), isTrue);
    });

    test('matches username and email', () {
      expect(ChatFormat.matches(juan, 'juandc'), isTrue);
      expect(ChatFormat.matches(juan, '@example'), isTrue);
    });

    test('empty query matches everyone, unrelated text matches nobody', () {
      expect(ChatFormat.matches(juan, '  '), isTrue);
      expect(ChatFormat.matches(juan, 'maria'), isFalse);
    });

    test('tolerates users missing profile fields', () {
      expect(
        ChatFormat.matches({'uid': 'u2', 'email': 'a@b.co'}, 'a@b'),
        isTrue,
      );
    });
  });

  group('ChatFormat display', () {
    test('displayName falls back from full name to username to email', () {
      expect(ChatFormat.displayName(juan), 'Juan Dela Cruz');
      expect(ChatFormat.displayName({'username': 'juandc'}), 'juandc');
      expect(ChatFormat.displayName({'email': 'a@b.co'}), 'a@b.co');
      expect(ChatFormat.initial({'email': 'a@b.co'}), 'A');
    });

    test('time uses 12-hour clock', () {
      expect(ChatFormat.time(DateTime(2026, 9, 29, 0, 5)), '12:05 AM');
      expect(ChatFormat.time(DateTime(2026, 9, 29, 13, 30)), '1:30 PM');
    });

    test('relativeDay and dayLabel', () {
      final now = DateTime(2026, 9, 29, 10);
      expect(
        ChatFormat.relativeDay(DateTime(2026, 9, 29, 9), now: now),
        '9:00 AM',
      );
      expect(
        ChatFormat.relativeDay(DateTime(2026, 9, 28, 9), now: now),
        'Yesterday',
      );
      expect(ChatFormat.relativeDay(DateTime(2026, 9, 2), now: now), 'Sep 2');
      expect(ChatFormat.dayLabel(DateTime(2026, 9, 29), now: now), 'Today');
      expect(
        ChatFormat.dayLabel(DateTime(2025, 12, 31), now: now),
        'Dec 31, 2025',
      );
    });

    test('avatar color is stable per uid', () {
      expect(ChatFormat.avatarColor('u1'), ChatFormat.avatarColor('u1'));
    });
  });

  group('MessageModel', () {
    test('round-trips through a Firestore map and defaults seen to false', () {
      final message = MessageModel(
        senderId: 'u1',
        senderEmail: 'juan@example.com',
        receiverId: 'u2',
        message: 'Hi!',
        timestamp: Timestamp.fromMillisecondsSinceEpoch(1000),
      );

      final map = message.toMap();
      expect(map['seen'], isFalse);

      final copy = MessageModel.fromMap(map);
      expect(copy.message, 'Hi!');
      expect(copy.receiverId, 'u2');
      expect(copy.timestamp.millisecondsSinceEpoch, 1000);
    });

    test('reads older messages that have no seen field', () {
      final copy = MessageModel.fromMap({
        'senderId': 'u1',
        'senderEmail': '',
        'receiverId': 'u2',
        'message': 'old',
        'timestamp': Timestamp.now(),
      });
      expect(copy.seen, isFalse);
    });
  });
}
