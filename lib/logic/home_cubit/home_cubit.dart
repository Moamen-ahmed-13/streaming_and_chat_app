import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/data/services/stream_service.dart';
import 'package:streaming_and_chat_app/logic/home_cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final StreamService _streamService;

  HomeCubit(this._streamService) : super(HomeInitial());

  void loadLiveStreams() {
    emit(HomeLoading());
    _streamService.getLiveStreams().listen(
      (streams) => emit(HomeLoaded(streams)),
      onError: (e) => emit(HomeError(e.toString())),
    );
  }
}