import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:streaming_and_chat_app/data/services/agora_service.dart';
import 'package:streaming_and_chat_app/data/services/auth_service.dart';
import 'package:streaming_and_chat_app/data/services/chat_service.dart';
import 'package:streaming_and_chat_app/data/services/notification_service.dart';
import 'package:streaming_and_chat_app/data/services/profile_service.dart';
import 'package:streaming_and_chat_app/data/services/stream_service.dart';
import 'package:streaming_and_chat_app/data/services/supabase_storage_service.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_cubit.dart';
import 'package:streaming_and_chat_app/logic/chat_cubit/chat_cubit.dart';
import 'package:streaming_and_chat_app/logic/home_cubit/home_cubit.dart';
import 'package:streaming_and_chat_app/logic/profile_cubit/profile_cubit.dart';
import 'package:streaming_and_chat_app/logic/streaming_cubit/broadcast_cubit.dart';
import 'package:streaming_and_chat_app/logic/viewer_cubit/viewer_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  
  getIt.registerLazySingleton<AuthService>(() => AuthService(
    getIt<FirebaseAuth>(),
    getIt<FirebaseFirestore>(),
    getIt<GoogleSignIn>(),
  ));
  
  getIt.registerLazySingleton<SupabaseStorageService>(() => SupabaseStorageService(
    getIt<SupabaseClient>(),
  ));
  
  getIt.registerLazySingleton<ProfileService>(() => ProfileService(
    getIt<FirebaseFirestore>(),
    getIt<SupabaseStorageService>(),
  ));
  
  getIt.registerLazySingleton<StreamService>(() => StreamService(
    getIt<FirebaseFirestore>(),
  ));
  
  getIt.registerLazySingleton<AgoraService>(() => AgoraService());
  
  getIt.registerLazySingleton<ChatService>(() => ChatService(
    getIt<FirebaseFirestore>(),
  ));
  
  getIt.registerLazySingleton<NotificationService>(() => NotificationService(
    getIt<FirebaseMessaging>(),
    getIt<FirebaseFirestore>(),
  ));
  
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthService>()));
  
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt<ProfileService>()));
  
  getIt.registerFactory<HomeCubit>(() => HomeCubit(getIt<StreamService>()));
  
  getIt.registerFactory<BroadcasterCubit>(() => BroadcasterCubit(
    getIt<AgoraService>(),
    getIt<StreamService>(),
  ));
  
  getIt.registerFactory<ViewerCubit>(() => ViewerCubit(
    getIt<AgoraService>(),
    getIt<StreamService>(),
  ));
  
  getIt.registerFactoryParam<ChatCubit, String, void>(
    (streamId, _) => ChatCubit(getIt<ChatService>(), streamId),
  );
}