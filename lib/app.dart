import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/app_router.dart';
import 'package:streaming_and_chat_app/core/injection.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
      child: MaterialApp.router(
        title: 'LiveStream App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}