import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:streaming_and_chat_app/core/chat_widget.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';
import 'package:streaming_and_chat_app/data/services/agora_service.dart';
import 'package:streaming_and_chat_app/logic/chat_cubit/chat_cubit.dart';
import 'package:streaming_and_chat_app/logic/viewer_cubit/viewer_cubit.dart';
import 'package:streaming_and_chat_app/logic/viewer_cubit/viewer_state.dart';

class WatchStreamPage extends StatefulWidget {
  final StreamModel stream;

  const WatchStreamPage({
    super.key,
    required this.stream,
  });

  @override
  State<WatchStreamPage> createState() => _WatchStreamPageState();
}

class _WatchStreamPageState extends State<WatchStreamPage> {
  late ViewerCubit _viewerCubit;

  @override
  void initState() {
    super.initState();
    _viewerCubit = getIt<ViewerCubit>()..joinStream(widget.stream);
  }

  @override
  void dispose() {
    _viewerCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _viewerCubit,
      child: BlocListener<ViewerCubit, ViewerState>(
        listener: (context, state) {
          if (state is ViewerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          } else if (state is ViewerLeft) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          body: BlocBuilder<ViewerCubit, ViewerState>(
            builder: (context, state) {
              if (state is ViewerLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ViewerWatching) {
                return _buildStreamView(context, state);
              }

              if (state is ViewerError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStreamView(BuildContext context, ViewerWatching state) {
    final agoraEngine = getIt<AgoraService>().engine;
    
    if (agoraEngine == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing stream...'),
          ],
        ),
      );
    }

    return BlocProvider(
      create: (_) => getIt<ChatCubit>(param1: state.stream.id)..loadMessages(),
      child: Stack(
        children: [
          Center(
            child: state.remoteUid != 0
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: agoraEngine,
                      canvas: VideoCanvas(uid: state.remoteUid),
                      connection: RtcConnection(
                        channelId: state.stream.channelName,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Waiting for stream...'),
                        ],
                      ),
                    ),
                  ),
          ),

          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              _viewerCubit.leaveStream();
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.stream.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state.stream.streamerName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
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
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.visibility, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.viewerCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  height: 300,
                  child: ChatWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}