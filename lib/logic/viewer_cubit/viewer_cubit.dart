import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';
import 'package:streaming_and_chat_app/data/services/agora_service.dart';
import 'package:streaming_and_chat_app/data/services/stream_service.dart';
import 'package:streaming_and_chat_app/logic/viewer_cubit/viewer_state.dart';

class ViewerCubit extends Cubit<ViewerState> {
  final AgoraService _agoraService;
  final StreamService _streamService;
  
  int _remoteUid = 0;
  int _viewerCount = 0;

  ViewerCubit(this._agoraService, this._streamService) : super(ViewerInitial());

  Future<void> joinStream(StreamModel stream) async {
    try {
      emit(ViewerLoading());
      AppLogger.info('Joining stream: ${stream.id}');

      // Setup Agora event handlers
      _agoraService.registerEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          AppLogger.info('Remote user joined: $remoteUid');
          _remoteUid = remoteUid;
          if (state is ViewerWatching) {
            emit((state as ViewerWatching).copyWith(remoteUid: remoteUid));
          } else {
            emit(ViewerWatching(
              stream: stream,
              remoteUid: remoteUid,
              viewerCount: _viewerCount,
            ));
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          AppLogger.info('Remote user left: $remoteUid');
          if (_remoteUid == remoteUid) {
            emit(const ViewerError('Stream ended'));
          }
        },
        onRtcStats: (connection, stats) {
          _viewerCount = stats.userCount ?? 0;
          if (state is ViewerWatching) {
            emit((state as ViewerWatching).copyWith(viewerCount: _viewerCount));
          }
        },
      );

      // Join Agora channel as viewer
      await _agoraService.joinAsViewer(stream.channelName);

      // Listen to stream updates
      _streamService.getLiveStreams().listen((streams) {
        final currentStream = streams.firstWhere(
          (s) => s.id == stream.id,
          orElse: () => stream,
        );
        
        if (!currentStream.isLive && state is ViewerWatching) {
          emit(const ViewerError('Stream has ended'));
        }
      });

      emit(ViewerWatching(
        stream: stream,
        remoteUid: _remoteUid,
        viewerCount: _viewerCount,
      ));

      AppLogger.info('Joined stream successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to join stream', e, stackTrace);
      emit(ViewerError('Failed to join stream: ${e.toString()}'));
    }
  }

  Future<void> leaveStream() async {
    try {
      AppLogger.info('Leaving stream...');
      await _agoraService.leaveChannel();
      emit(ViewerLeft());
      AppLogger.info('Left stream successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to leave stream', e, stackTrace);
      emit(ViewerError('Failed to leave stream: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    if (state is ViewerWatching) {
      leaveStream();
    }
    return super.close();
  }
}