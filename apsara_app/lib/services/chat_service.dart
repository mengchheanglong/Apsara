import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message_model.dart';
import '../models/user_profile.dart';
import 'cloudinary_media_service.dart';

typedef UploadProgress = void Function(double progress);

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const pageSize = 40;

  String roomIdFor(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatRoomPreview>> watchChatRooms(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomPreview.fromMap(doc.id, doc.data()))
          .where((room) {
        final hiddenAt = room.hiddenAtFor(userId);
        final updatedAt = room.updatedAt;
        return hiddenAt == null ||
            updatedAt == null ||
            updatedAt.isAfter(hiddenAt);
      }).toList();
      rooms.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return rooms;
    });
  }

  Stream<List<MessageModel>> getMessagesStream(
    String roomId, {
    int limit = pageSize,
  }) {
    return _messagesRef(roomId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
          .toList();
      return messages.reversed.toList();
    });
  }

  Future<List<MessageModel>> getOlderMessages({
    required String roomId,
    required DateTime before,
    int limit = pageSize,
  }) async {
    final snapshot = await _messagesRef(roomId)
        .orderBy('timestamp', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();

    final messages = snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
        .toList();
    return messages.reversed.toList();
  }

  Future<void> ensureRoom({
    required UserProfile currentUser,
    required ChatPeer peer,
  }) {
    final roomId = roomIdFor(currentUser.uid, peer.uid);
    return _roomRef(roomId).set(
      _roomBaseData(
        currentUser: currentUser,
        peer: peer,
        includeCreatedAt: true,
        clearHiddenForUserId: currentUser.uid,
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> sendMessage({
    required UserProfile currentUser,
    required ChatPeer peer,
    required String text,
    String? clientNonce,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final roomId = roomIdFor(currentUser.uid, peer.uid);
    final messageRef = _messagesRef(roomId).doc();
    final batch = _db.batch();

    batch.set(
        _roomRef(roomId),
        {
          ..._roomBaseData(currentUser: currentUser, peer: peer),
          'lastMessage': trimmed,
          'lastMessageType': MessageType.text.value,
          'lastSenderId': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'typingUsers.${currentUser.uid}': false,
          'unreadCounts.${peer.uid}': FieldValue.increment(1),
          'hiddenFor.${currentUser.uid}': FieldValue.delete(),
        },
        SetOptions(merge: true));

    batch.set(
      messageRef,
      MessageModel(
        id: messageRef.id,
        senderId: currentUser.uid,
        senderEmail: currentUser.email,
        receiverId: peer.uid,
        text: trimmed,
        imageUrl: '',
        timestamp: null,
        isRead: false,
        type: MessageType.text,
        deliveredTo: {currentUser.uid: true},
        readBy: {currentUser.uid: true},
        clientNonce: clientNonce,
      ).toMap(),
    );

    await batch.commit();
  }

  Future<void> sendImage({
    required UserProfile currentUser,
    required ChatPeer peer,
    required File imageFile,
    String? clientNonce,
    UploadProgress? onProgress,
  }) async {
    final roomId = roomIdFor(currentUser.uid, peer.uid);
    final messageRef = _messagesRef(roomId).doc();
    onProgress?.call(0);
    final imageUrl =
        await CloudinaryMediaService.instance.uploadChatImage(imageFile);

    final batch = _db.batch();
    batch.set(
        _roomRef(roomId),
        {
          ..._roomBaseData(currentUser: currentUser, peer: peer),
          'lastMessage': 'Photo',
          'lastMessageType': MessageType.image.value,
          'lastSenderId': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'typingUsers.${currentUser.uid}': false,
          'unreadCounts.${peer.uid}': FieldValue.increment(1),
          'hiddenFor.${currentUser.uid}': FieldValue.delete(),
        },
        SetOptions(merge: true));

    batch.set(
      messageRef,
      MessageModel(
        id: messageRef.id,
        senderId: currentUser.uid,
        senderEmail: currentUser.email,
        receiverId: peer.uid,
        text: '',
        imageUrl: imageUrl,
        timestamp: null,
        isRead: false,
        type: MessageType.image,
        deliveredTo: {currentUser.uid: true},
        readBy: {currentUser.uid: true},
        clientNonce: clientNonce,
      ).toMap(),
    );

    await batch.commit();
    onProgress?.call(1);
  }

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) {
    return _roomRef(roomId).set({
      'typingUsers.$userId': isTyping,
    }, SetOptions(merge: true));
  }

  Stream<bool> watchTyping({
    required String roomId,
    required String peerId,
  }) {
    return _roomRef(roomId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return false;
      }
      final typingUsers = data['typingUsers'];
      return typingUsers is Map && typingUsers[peerId] == true;
    });
  }

  Future<void> markMessagesRead({
    required String roomId,
    required String currentUserId,
  }) async {
    final snapshot = await _messagesRef(roomId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) {
      await _roomRef(roomId).set({
        'unreadCounts.$currentUserId': 0,
      }, SetOptions(merge: true));
      return;
    }

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'deliveredTo.$currentUserId': true,
        'readBy.$currentUserId': true,
      });
    }
    batch.set(
        _roomRef(roomId),
        {
          'unreadCounts.$currentUserId': 0,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> hideChatForUser({
    required String roomId,
    required String userId,
  }) {
    return _roomRef(roomId).set({
      'hiddenFor.$userId': FieldValue.serverTimestamp(),
      'unreadCounts.$userId': 0,
      'typingUsers.$userId': false,
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _roomRef(String roomId) {
    return _db.collection('chat_rooms').doc(roomId);
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String roomId) {
    return _roomRef(roomId).collection('messages');
  }

  Map<String, Object?> _roomBaseData({
    required UserProfile currentUser,
    required ChatPeer peer,
    bool includeCreatedAt = false,
    String? clearHiddenForUserId,
  }) {
    final participantIds = {currentUser.uid, peer.uid}.toList()..sort();
    final data = <String, Object?>{
      'participantIds': participantIds,
      'participantNames.${currentUser.uid}': currentUser.displayName,
      'participantNames.${peer.uid}': peer.displayName,
      'participantAvatars.${currentUser.uid}': currentUser.avatarUrl ?? '',
      'participantAvatars.${peer.uid}': peer.avatarUrl ?? '',
      'participantEmails.${currentUser.uid}': currentUser.email,
      'participantEmails.${peer.uid}': peer.email,
      if (clearHiddenForUserId != null && clearHiddenForUserId.isNotEmpty)
        'hiddenFor.$clearHiddenForUserId': FieldValue.delete(),
    };
    if (includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return data;
  }
}
