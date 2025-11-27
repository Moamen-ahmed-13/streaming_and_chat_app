// features/home/services/stream_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';

class StreamService {
  final FirebaseFirestore _firestore;

  StreamService(this._firestore);

  // Create a new stream
  Future<void> createStream(StreamModel stream) async {
    try {
      await _firestore.collection('streams').doc(stream.id).set(stream.toJson());
      AppLogger.info('Stream created: ${stream.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create stream', e, stackTrace);
      rethrow;
    }
  }

  // Get all live streams
  Stream<List<StreamModel>> getLiveStreams() {
    return _firestore
        .collection('streams')
        .where('isLive', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StreamModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // Update viewer count
  Future<void> updateViewerCount(String streamId, int count) async {
    try {
      await _firestore.collection('streams').doc(streamId).update({
        'viewerCount': count,
      });
    } catch (e) {
      AppLogger.error('Failed to update viewer count', e);
    }
  }

  // End stream
  Future<void> endStream(String streamId) async {
    try {
      await _firestore.collection('streams').doc(streamId).update({
        'isLive': false,
      });
      AppLogger.info('Stream ended: $streamId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to end stream', e, stackTrace);
      rethrow;
    }
  }
}