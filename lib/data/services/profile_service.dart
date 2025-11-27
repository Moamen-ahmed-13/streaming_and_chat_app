// features/profile/services/profile_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileService(this._firestore, this._storage);

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw Exception('User not found');
      return UserModel.fromJson(doc.data()!);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    File? photoFile,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;

      if (photoFile != null) {
        final photoUrl = await _uploadProfilePhoto(userId, photoFile);
        updates['photoUrl'] = photoUrl;
      }

      await _firestore.collection('users').doc(userId).update(updates);
      AppLogger.info('Profile updated for user: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _uploadProfilePhoto(String userId, File file) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload photo', e, stackTrace);
      rethrow;
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Add to current user's following
        transaction.update(
          _firestore.collection('users').doc(currentUserId),
          {
            'following': FieldValue.arrayUnion([targetUserId])
          },
        );
        // Add to target user's followers
        transaction.update(
          _firestore.collection('users').doc(targetUserId),
          {
            'followers': FieldValue.arrayUnion([currentUserId])
          },
        );
      });
      AppLogger.info('User followed: $targetUserId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to follow user', e, stackTrace);
      rethrow;
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.update(
          _firestore.collection('users').doc(currentUserId),
          {
            'following': FieldValue.arrayRemove([targetUserId])
          },
        );
        transaction.update(
          _firestore.collection('users').doc(targetUserId),
          {
            'followers': FieldValue.arrayRemove([currentUserId])
          },
        );
      });
      AppLogger.info('User unfollowed: $targetUserId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to unfollow user', e, stackTrace);
      rethrow;
    }
  }
}