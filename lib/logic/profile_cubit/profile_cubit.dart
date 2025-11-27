import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/services/profile_service.dart';
import 'package:streaming_and_chat_app/logic/profile_cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _profileService;

  ProfileCubit(this._profileService) : super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    try {
      emit(ProfileLoading());
      AppLogger.info('Loading profile for user: $userId');
      
      final user = await _profileService.getUserProfile(userId);
      emit(ProfileLoaded(user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load profile', e, stackTrace);
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    File? photoFile,
  }) async {
    try {
      if (state is ProfileLoaded) {
        emit(ProfileUpdating((state as ProfileLoaded).user));
      }
      
      AppLogger.info('Updating profile for user: $userId');
      
      await _profileService.updateProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        photoFile: photoFile,
      );
      
      // Reload profile to get updated data
      final updatedUser = await _profileService.getUserProfile(userId);
      emit(ProfileUpdateSuccess(updatedUser));
      
      // After a brief moment, change to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ProfileLoaded(updatedUser));
      
      AppLogger.info('Profile updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
      
      // Reload the current profile after error
      if (state is ProfileUpdating) {
        emit(ProfileLoaded((state as ProfileUpdating).currentUser));
      }
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      AppLogger.info('Following user: $targetUserId');
      await _profileService.followUser(currentUserId, targetUserId);
      
      // Reload profile to update followers list
      await loadProfile(currentUserId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to follow user', e, stackTrace);
      emit(ProfileError('Failed to follow user: ${e.toString()}'));
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      AppLogger.info('Unfollowing user: $targetUserId');
      await _profileService.unfollowUser(currentUserId, targetUserId);
      
      // Reload profile to update followers list
      await loadProfile(currentUserId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to unfollow user', e, stackTrace);
      emit(ProfileError('Failed to unfollow user: ${e.toString()}'));
    }
  }
}