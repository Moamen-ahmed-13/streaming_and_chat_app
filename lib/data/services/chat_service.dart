import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/message_model.dart';
class ChatService {
  final FirebaseFirestore _firestore;

  ChatService(this._firestore);

  Future<void> sendMessage({
    required String streamId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      AppLogger.info('Sending message to stream: $streamId');
      
      final messageData = MessageModel(
        id: '',
        userId: userId,
        userName: userName,
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('messages')
          .doc(streamId)
          .collection('messages')
          .add(messageData.toJson());

      AppLogger.info('Message sent successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send message', e, stackTrace);
      rethrow;
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String streamId) {
    try {
      AppLogger.info('Subscribing to messages for stream: $streamId');
      
      return _firestore
          .collection('messages')
          .doc(streamId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(100)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
            .toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get messages stream', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteStreamMessages(String streamId) async {
    try {
      AppLogger.info('Deleting messages for stream: $streamId');
      
      final messagesRef = _firestore
          .collection('messages')
          .doc(streamId)
          .collection('messages');
      
      final snapshot = await messagesRef.get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      AppLogger.info('Messages deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete messages', e, stackTrace);
    }
  }
}