import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:streaming_and_chat_app/core/logger.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase;

  SupabaseStorageService(this._supabase);

  Future<String> uploadProfilePhoto(String userId, File file) async {
    try {
      AppLogger.info('Uploading profile photo for user: $userId');

      final fileName = '$userId.jpg';
      final filePath = 'profile_photos/$fileName';

      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      AppLogger.info('Profile photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload profile photo', e, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadStreamThumbnail(String streamId, File file) async {
    try {
      AppLogger.info('Uploading stream thumbnail for stream: $streamId');

      final fileName = '$streamId.jpg';
      final filePath = 'stream_thumbnails/$fileName';

      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('user-uploads')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      AppLogger.info('Stream thumbnail uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload stream thumbnail', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      AppLogger.info('Deleting file: $filePath');

      await _supabase.storage
          .from('user-uploads')
          .remove([filePath]);

      AppLogger.info('File deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file', e, stackTrace);
    }
  }

  Future<void> deleteProfilePhoto(String userId) async {
    final filePath = 'profile_photos/$userId.jpg';
    await deleteFile(filePath);
  }

  Future<void> deleteStreamThumbnail(String streamId) async {
    final filePath = 'stream_thumbnails/$streamId.jpg';
    await deleteFile(filePath);
  }
  String getPublicUrl(String filePath) {
    return _supabase.storage
        .from('user-uploads')
        .getPublicUrl(filePath);
  }
}