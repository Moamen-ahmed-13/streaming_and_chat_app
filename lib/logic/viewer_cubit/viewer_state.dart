import 'package:equatable/equatable.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';

abstract class ViewerState extends Equatable {
  const ViewerState();
  
  @override
  List<Object?> get props => [];
}

class ViewerInitial extends ViewerState {}

class ViewerLoading extends ViewerState {}

class ViewerWatching extends ViewerState {
  final StreamModel stream;
  final int remoteUid;
  final int viewerCount;
  
  const ViewerWatching({
    required this.stream,
    required this.remoteUid,
    required this.viewerCount,
  });
  
  @override
  List<Object?> get props => [stream, remoteUid, viewerCount];
  
  ViewerWatching copyWith({
    StreamModel? stream,
    int? remoteUid,
    int? viewerCount,
  }) {
    return ViewerWatching(
      stream: stream ?? this.stream,
      remoteUid: remoteUid ?? this.remoteUid,
      viewerCount: viewerCount ?? this.viewerCount,
    );
  }
}

class ViewerError extends ViewerState {
  final String message;
  
  const ViewerError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ViewerLeft extends ViewerState {}