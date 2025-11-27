// Home Cubit
import 'package:equatable/equatable.dart';
import 'package:streaming_and_chat_app/data/models/stream_model.dart';
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<StreamModel> streams;
  HomeLoaded(this.streams);
  
  @override
  List<Object?> get props => [streams];
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
  
  @override
  List<Object?> get props => [message];
}

