import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_cubit.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_state.dart';
import 'package:streaming_and_chat_app/logic/profile_cubit/profile_cubit.dart';
import 'package:streaming_and_chat_app/logic/profile_cubit/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..loadProfile(authState.user.id),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileCubit>().loadProfile(authState.user.id);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded || state is ProfileUpdateSuccess) {
              final user = state is ProfileLoaded 
                  ? state.user 
                  : (state as ProfileUpdateSuccess).user;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Profile Picture
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.displayName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Display Name
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Followers',
                          user.followers.length.toString(),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[700],
                        ),
                        _buildStatItem(
                          'Following',
                          user.following.length.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Edit Profile Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}