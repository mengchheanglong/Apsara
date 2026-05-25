import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image;

  static MessageType fromValue(String? value) {
    return value == 'image' ? MessageType.image : MessageType.text;
  }

  String get value => name;
}

enum LocalMessageStatus {
  sending,
  sent,
  failed,
}

class ChatPeer {
  const ChatPeer({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? avatarUrl;
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.deliveredTo = const {},
    this.readBy = const {},
    this.localStatus = LocalMessageStatus.sent,
    this.clientNonce,
  });

  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String text;
  final String imageUrl;
  final DateTime? timestamp;
  final bool isRead;
  final MessageType type;
  final Map<String, bool> deliveredTo;
  final Map<String, bool> readBy;
  final LocalMessageStatus localStatus;
  final String? clientNonce;

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: _stringValue(map['senderId']),
      senderEmail: _stringValue(map['senderEmail']),
      receiverId: _stringValue(map['receiverId']),
      text: _stringValue(map['text']),
      imageUrl: _stringValue(map['imageUrl']),
      timestamp: _dateValue(map['timestamp']),
      isRead: map['isRead'] == true,
      type: MessageType.fromValue(_stringValue(map['type'])),
      deliveredTo: _boolMap(map['deliveredTo']),
      readBy: _boolMap(map['readBy']),
      clientNonce: _nullableStringValue(map['clientNonce']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'type': type.value,
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      if (clientNonce != null && clientNonce!.isNotEmpty)
        'clientNonce': clientNonce,
    };
  }

  bool isFrom(String userId) => senderId == userId;

  bool wasDeliveredTo(String userId) => deliveredTo[userId] == true;

  bool wasReadBy(String userId) => readBy[userId] == true || isRead;

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? receiverId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    Map<String, bool>? deliveredTo,
    Map<String, bool>? readBy,
    LocalMessageStatus? localStatus,
    String? clientNonce,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      readBy: readBy ?? this.readBy,
      localStatus: localStatus ?? this.localStatus,
      clientNonce: clientNonce ?? this.clientNonce,
    );
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String? _nullableStringValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static Map<String, bool> _boolMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), item == true),
    );
  }
}

class ChatRoomPreview {
  const ChatRoomPreview({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastSenderId,
    required this.updatedAt,
    required this.unreadCounts,
    required this.typingUsers,
    required this.hiddenFor,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String lastMessage;
  final MessageType lastMessageType;
  final String lastSenderId;
  final DateTime? updatedAt;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typingUsers;
  final Map<String, DateTime> hiddenFor;

  factory ChatRoomPreview.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoomPreview(
      id: id,
      participantIds: (map['participantIds'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      participantNames: _stringMap(map['participantNames']),
      participantAvatars: _stringMap(map['participantAvatars']),
      lastMessage: MessageModel._stringValue(map['lastMessage']),
      lastMessageType: MessageType.fromValue(
          MessageModel._stringValue(map['lastMessageType'])),
      lastSenderId: MessageModel._stringValue(map['lastSenderId']),
      updatedAt: MessageModel._dateValue(map['updatedAt']),
      unreadCounts: _intMap(map['unreadCounts']),
      typingUsers: MessageModel._boolMap(map['typingUsers']),
      hiddenFor: _dateMap(map['hiddenFor']),
    );
  }

  ChatPeer otherParticipant(String currentUserId) {
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    return ChatPeer(
      uid: otherId,
      displayName: participantNames[otherId] ??
          participantNames[currentUserId] ??
          'Apsara user',
      email: '',
      avatarUrl:
          participantAvatars[otherId] ?? participantAvatars[currentUserId],
    );
  }

  int unreadCountFor(String userId) => unreadCounts[userId] ?? 0;

  bool isTyping(String userId) => typingUsers[userId] == true;

  DateTime? hiddenAtFor(String userId) => hiddenFor[userId];

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map(
      (key, item) => MapEntry(
        key.toString(),
        item is num ? item.toInt() : int.tryParse(item.toString()) ?? 0,
      ),
    );
  }

  static Map<String, DateTime> _dateMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    final result = <String, DateTime>{};
    for (final entry in value.entries) {
      final date = MessageModel._dateValue(entry.value);
      if (date != null) {
        result[entry.key.toString()] = date;
      }
    }
    return result;
  }
}
