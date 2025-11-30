import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/core/cached_avatar.dart';
import 'package:streaming_and_chat_app/logic/home_cubit/home_cubit.dart';
import 'package:streaming_and_chat_app/logic/home_cubit/home_state.dart';
import 'package:streaming_and_chat_app/presentation/profile_page.dart';
import 'package:streaming_and_chat_app/presentation/go_live_page.dart';
import 'package:streaming_and_chat_app/presentation/watch_stream_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadLiveStreams(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LiveStream'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeError) {
              return Center(child: Text(state.message));
            }

            if (state is HomeLoaded) {
              if (state.streams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No one is live right now',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GoLivePage()),
                          );
                        },
                        icon: const Icon(Icons.videocam),
                        label: const Text('Start Your Stream'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeCubit>().loadLiveStreams();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.streams.length,
                  itemBuilder: (context, index) {
                    final stream = state.streams[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WatchStreamPage(stream: stream),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: Colors.grey[900],
                                child: Stack(
                                  children: [
                                    if (stream.thumbnailUrl != null)
                                      CachedImageBox(
                                        imageUrl: stream.thumbnailUrl!,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    Center(
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.visibility, size: 14),
                                            const SizedBox(width: 4),
                                            Text('${stream.viewerCount}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CachedAvatar(
                                    imageUrl: stream.streamerPhoto,
                                    fallbackText: stream.streamerName,
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stream.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stream.streamerName,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoLivePage()),
            );
          },
          icon: const Icon(Icons.videocam),
          label: const Text('Go Live'),
        ),
      ),
    );
  }
}