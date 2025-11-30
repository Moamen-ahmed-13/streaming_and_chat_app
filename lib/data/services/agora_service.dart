import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:streaming_and_chat_app/core/logger.dart';

class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  String get appId => dotenv.env['AGORA_APP_ID'] ?? '';

  Future<void> initialize() async {
    if (_isInitialized && _engine != null) {
      AppLogger.info('Agora Engine already initialized');
      return;
    }

    try {
      AppLogger.info('Initializing Agora Engine...');
      
      await [Permission.camera, Permission.microphone].request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _isInitialized = true;
      AppLogger.info('Agora Engine initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Agora', e, stackTrace);
      _isInitialized = false;
      _engine = null;
      rethrow;
    }
  }

  Future<void> startBroadcasting(String channelName) async {
    try {
      if (!_isInitialized || _engine == null) {
        await initialize();
      }

      AppLogger.info('Starting broadcast on channel: $channelName');

      await _engine!.enableVideo();
      
      await _engine!.enableLocalVideo(true);
      
      await _engine!.startPreview();

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await _engine!.joinChannel(
        token: dotenv.env['AGORA_TEMP_TOKEN'] ?? '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );

      AppLogger.info('Broadcast started successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start broadcast', e, stackTrace);
      rethrow;
    }
  }

  Future<void> joinAsViewer(String channelName) async {
    try {
      if (!_isInitialized || _engine == null) {
        await initialize();
      }

      AppLogger.info('Joining as viewer on channel: $channelName');

      await _engine!.enableVideo();

      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      await _engine!.joinChannel(
        token: dotenv.env['AGORA_TEMP_TOKEN'] ?? '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
        ),
      );

      AppLogger.info('Joined as viewer successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to join as viewer', e, stackTrace);
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    try {
      if (_engine == null) return;
      
      AppLogger.info('Leaving channel...');
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
      AppLogger.info('Left channel successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to leave channel', e, stackTrace);
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    try {
      if (_engine == null) return;
      await _engine!.switchCamera();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to switch camera', e, stackTrace);
    }
  }

  Future<void> muteLocalAudio(bool mute) async {
    try {
      if (_engine == null) return;
      await _engine!.muteLocalAudioStream(mute);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mute audio', e, stackTrace);
    }
  }

  Future<void> muteLocalVideo(bool mute) async {
    try {
      if (_engine == null) return;
      await _engine!.muteLocalVideoStream(mute);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mute video', e, stackTrace);
    }
  }

  void registerEventHandler({
    required Function(RtcConnection connection, int remoteUid, int elapsed) onUserJoined,
    required Function(RtcConnection connection, int remoteUid, UserOfflineReasonType reason) onUserOffline,
    required Function(RtcConnection connection, RtcStats stats) onRtcStats,
  }) {
    if (!_isInitialized || _engine == null) {
      AppLogger.warning('Cannot register event handler - engine not initialized');
      return;
    }
    
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          AppLogger.info('Join channel success: ${connection.channelId}, localUid: ${connection.localUid}');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          AppLogger.info('User joined - Channel: ${connection.channelId}, RemoteUID: $remoteUid');
          onUserJoined(connection, remoteUid, elapsed);
        },
        onUserOffline: (connection, remoteUid, reason) {
          AppLogger.info('User offline - RemoteUID: $remoteUid, Reason: $reason');
          onUserOffline(connection, remoteUid, reason);
        },
        onRtcStats: onRtcStats,
        onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
          AppLogger.info('Remote video state changed - UID: $remoteUid, State: $state, Reason: $reason');
        },
        onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
          AppLogger.info('First remote video frame - UID: $remoteUid, Size: ${width}x$height');
        },
        onError: (err, msg) {
          AppLogger.error('Agora error: $msg', err);
        },
        onConnectionStateChanged: (connection, state, reason) {
          AppLogger.info('Connection state changed - State: $state, Reason: $reason');
        },
      ),
    );
  }

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    try {
      if (_engine == null) return;
      
      AppLogger.info('Disposing Agora Engine...');
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      AppLogger.info('Agora Engine disposed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to dispose Agora', e, stackTrace);
    }
  }
}