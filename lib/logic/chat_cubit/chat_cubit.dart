import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/services/chat_service.dart';
import 'package:streaming_and_chat_app/logic/chat_cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  final String streamId;

  ChatCubit(this._chatService, this.streamId) : super(ChatInitial());

  void loadMessages() {
    try {
      emit(ChatLoading());
      AppLogger.info('Loading messages for stream: $streamId');
      
      _chatService.getMessagesStream(streamId).listen(
        (messages) {
          emit(ChatLoaded(messages));
        },
        onError: (error) {
          AppLogger.error('Error loading messages', error);
          emit(ChatError('Failed to load messages: ${error.toString()}'));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load messages', e, stackTrace);
      emit(ChatError('Failed to load messages: ${e.toString()}'));
    }
  }

  Future<void> sendMessage({
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      if (message.trim().isEmpty) return;
      
      AppLogger.info('Sending message to stream: $streamId');
      
      await _chatService.sendMessage(
        streamId: streamId,
        userId: userId,
        userName: userName,
        message: message.trim(),
      );
      
      AppLogger.info('Message sent successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send message', e, stackTrace);
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> clearMessages() async {
    try {
      await _chatService.deleteStreamMessages(streamId);
      emit(const ChatLoaded([]));
    } catch (e) {
      AppLogger.error('Failed to clear messages', e);
    }
  }
}