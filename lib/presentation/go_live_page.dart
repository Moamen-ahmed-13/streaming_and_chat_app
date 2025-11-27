import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:streaming_and_chat_app/core/chat_widget.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/data/services/agora_service.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_cubit.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_state.dart';
import 'package:streaming_and_chat_app/logic/chat_cubit/chat_cubit.dart';
import 'package:streaming_and_chat_app/logic/streaming_cubit/broadcast_cubit.dart';
import 'package:streaming_and_chat_app/logic/streaming_cubit/broadcast_state.dart';

class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final _titleController = TextEditingController();
  bool _isLive = false;
  late BroadcasterCubit _broadcasterCubit;

  @override
  void initState() {
    super.initState();
    _broadcasterCubit = getIt<BroadcasterCubit>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _broadcasterCubit.close();
    super.dispose();
  }

  void _startStream(BuildContext context) {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a stream title')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _broadcasterCubit.startStream(
        title: _titleController.text.trim(),
        streamerId: authState.user.id,
        streamerName: authState.user.displayName,
        streamerPhoto: authState.user.photoUrl,
      );
      setState(() => _isLive = true);
    }
  }

  void _endStream(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Stream?'),
        content: const Text('Are you sure you want to end this stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _broadcasterCubit.endStream();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _broadcasterCubit,
      child: BlocListener<BroadcasterCubit, BroadcasterState>(
        listener: (context, state) {
          if (state is BroadcasterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BroadcasterEnded) {
            context.pop();
          }
        },
        child: Scaffold(
          appBar: _isLive ? null : AppBar(title: const Text('Go Live')),
          body: BlocBuilder<BroadcasterCubit, BroadcasterState>(
            builder: (context, state) {
              if (state is BroadcasterLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BroadcasterLive) {
                return _buildLiveView(context, state);
              }

              return _buildSetupView(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSetupView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.videocam, size: 80, color: Colors.purple),
          const SizedBox(height: 24),
          const Text(
            'Ready to Go Live?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Stream Title',
              border: OutlineInputBorder(),
              hintText: 'What are you streaming?',
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startStream(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Streaming'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLiveView(BuildContext context, BroadcasterLive state) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>(param1: state.stream.id)..loadMessages(),
      child: Stack(
        children: [
          // Camera preview
          Center(
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: getIt<AgoraService>().engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                            const Icon(Icons.visibility, size: 16),
                            const SizedBox(width: 4),
                            Text('${state.viewerCount}'),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _endStream(context),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Chat overlay
                const ChatWidget(),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: state.isCameraOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    onPressed: () => _broadcasterCubit.toggleCamera(),
                  ),
                  _buildControlButton(
                    icon: state.isMicOn ? Icons.mic : Icons.mic_off,
                    onPressed: () => _broadcasterCubit.toggleMic(),
                  ),
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    onPressed: () => _broadcasterCubit.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon), onPressed: onPressed, iconSize: 28),
    );
  }
}
