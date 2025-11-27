import 'package:equatable/equatable.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';

abstract class BroadcasterState extends Equatable {
  const BroadcasterState();
  
  @override
  List<Object?> get props => [];
}

class BroadcasterInitial extends BroadcasterState {}

class BroadcasterLoading extends BroadcasterState {}

class BroadcasterLive extends BroadcasterState {
  final StreamModel stream;
  final int viewerCount;
  final bool isCameraOn;
  final bool isMicOn;
  
  const BroadcasterLive({
    required this.stream,
    required this.viewerCount,
    this.isCameraOn = true,
    this.isMicOn = true,
  });
  
  @override
  List<Object?> get props => [stream, viewerCount, isCameraOn, isMicOn];
  
  BroadcasterLive copyWith({
    StreamModel? stream,
    int? viewerCount,
    bool? isCameraOn,
    bool? isMicOn,
  }) {
    return BroadcasterLive(
      stream: stream ?? this.stream,
      viewerCount: viewerCount ?? this.viewerCount,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isMicOn: isMicOn ?? this.isMicOn,
    );
  }
}

class BroadcasterError extends BroadcasterState {
  final String message;
  
  const BroadcasterError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class BroadcasterEnded extends BroadcasterState {}
