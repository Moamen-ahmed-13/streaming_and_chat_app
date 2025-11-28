import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';
import 'package:streaming_and_chat_app/data/services/agora_service.dart';
import 'package:streaming_and_chat_app/data/services/stream_service.dart';
import 'package:streaming_and_chat_app/logic/streaming_cubit/broadcast_state.dart';
import 'package:uuid/uuid.dart';

class BroadcasterCubit extends Cubit<BroadcasterState> {
  final AgoraService _agoraService;
  final StreamService _streamService;
  
  StreamModel? _currentStream;
  int _viewerCount = 0;

  BroadcasterCubit(this._agoraService, this._streamService) 
      : super(BroadcasterInitial());

  Future<void> startStream({
    required String title,
    required String streamerId,
    required String streamerName,
    String? streamerPhoto,
  }) async {
    try {
      emit(BroadcasterLoading());
      AppLogger.info('Starting stream: $title');

      await _agoraService.initialize();

      final channelName = 'stream_${const Uuid().v4().substring(0, 8)}';

      final stream = StreamModel(
        id: channelName,
        streamerId: streamerId,
        streamerName: streamerName,
        streamerPhoto: streamerPhoto,
        title: title,
        channelName: channelName,
        isLive: true,
        viewerCount: 0,
        startedAt: DateTime.now(),
      );

      await _streamService.createStream(stream);
      
      _agoraService.registerEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          _viewerCount++;
          _updateViewerCount();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _viewerCount--;
          if (_viewerCount < 0) _viewerCount = 0;
          _updateViewerCount();
        },
        onRtcStats: (connection, stats) {
        },
      );

      await _agoraService.startBroadcasting(channelName);

      _currentStream = stream;
      emit(BroadcasterLive(
        stream: stream,
        viewerCount: _viewerCount,
      ));

      AppLogger.info('Stream started successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start stream', e, stackTrace);
      emit(BroadcasterError('Failed to start stream: ${e.toString()}'));
    }
  }

  void _updateViewerCount() {
    if (state is BroadcasterLive && _currentStream != null) {
      _streamService.updateViewerCount(_currentStream!.id, _viewerCount);
      emit((state as BroadcasterLive).copyWith(viewerCount: _viewerCount));
    }
  }

  Future<void> toggleCamera() async {
    if (state is BroadcasterLive) {
      final currentState = state as BroadcasterLive;
      final newState = !currentState.isCameraOn;
      
      await _agoraService.muteLocalVideo(newState);
      emit(currentState.copyWith(isCameraOn: newState));
    }
  }

  Future<void> toggleMic() async {
    if (state is BroadcasterLive) {
      final currentState = state as BroadcasterLive;
      final newState = !currentState.isMicOn;
      
      await _agoraService.muteLocalAudio(newState);
      emit(currentState.copyWith(isMicOn: newState));
    }
  }

  Future<void> switchCamera() async {
    try {
      await _agoraService.switchCamera();
    } catch (e) {
      AppLogger.error('Failed to switch camera', e);
    }
  }

  Future<void> endStream() async {
    try {
      AppLogger.info('Ending stream...');

      if (_currentStream != null) {
        await _agoraService.leaveChannel();

        await _streamService.endStream(_currentStream!.id);

        _currentStream = null;
        _viewerCount = 0;
        emit(BroadcasterEnded());

        AppLogger.info('Stream ended successfully');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to end stream', e, stackTrace);
      emit(BroadcasterError('Failed to end stream: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    if (_currentStream != null) {
      endStream();
    }
    return super.close();
  }
}