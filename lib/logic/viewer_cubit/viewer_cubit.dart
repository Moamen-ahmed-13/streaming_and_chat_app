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

      await _agoraService.initialize();

      _agoraService.registerEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          AppLogger.info('Broadcaster joined with UID: $remoteUid');
          _remoteUid = remoteUid;
          if (!isClosed) {
            if (state is ViewerWatching) {
              emit((state as ViewerWatching).copyWith(remoteUid: remoteUid));
            } else {
              emit(ViewerWatching(
                stream: stream,
                remoteUid: remoteUid,
                viewerCount: _viewerCount,
              ));
            }
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          AppLogger.info('Broadcaster left with UID: $remoteUid, reason: $reason');
          if (_remoteUid == remoteUid && !isClosed) {
            _remoteUid = 0;
            emit(const ViewerError('Stream ended'));
          }
        },
        onRtcStats: (connection, stats) {
          final newCount = stats.userCount ?? 0;
          if (_viewerCount != newCount) {
            _viewerCount = newCount;
            AppLogger.info('Viewer count updated: $_viewerCount');
            if (state is ViewerWatching && !isClosed) {
              emit((state as ViewerWatching).copyWith(viewerCount: _viewerCount));
            }
          }
        },
      );

      await _agoraService.joinAsViewer(stream.channelName);

      _streamService.getLiveStreams().listen((streams) {
        final currentStream = streams.firstWhere(
          (s) => s.id == stream.id,
          orElse: () => stream,
        );
        
        if (!currentStream.isLive && state is ViewerWatching && !isClosed) {
          emit(const ViewerError('Stream has ended'));
        }
      });

      if (!isClosed) {
        emit(ViewerWatching(
          stream: stream,
          remoteUid: _remoteUid,
          viewerCount: _viewerCount,
        ));
      }

      AppLogger.info('Joined stream successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to join stream', e, stackTrace);
      if (!isClosed) {
        emit(ViewerError('Failed to join stream: ${e.toString()}'));
      }
    }
  }

  Future<void> leaveStream() async {
    try {
      AppLogger.info('Leaving stream...');
      await _agoraService.leaveChannel();
      if (!isClosed) {
        emit(ViewerLeft());
      }
      AppLogger.info('Left stream successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to leave stream', e, stackTrace);
      if (!isClosed) {
        emit(ViewerError('Failed to leave stream: ${e.toString()}'));
      }
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