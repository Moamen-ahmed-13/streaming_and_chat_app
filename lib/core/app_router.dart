// import 'package:go_router/go_router.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:streaming_and_chat_app/data/models/stream_model.dart';
// import 'package:streaming_and_chat_app/logic/auth_cubit/auth_cubit.dart';
// import 'package:streaming_and_chat_app/logic/auth_cubit/auth_state.dart';
// import 'package:streaming_and_chat_app/presentation/edit_profile_page.dart';
// import 'package:streaming_and_chat_app/presentation/forgot_password_page.dart';
// import 'package:streaming_and_chat_app/presentation/go_live_page.dart';
// import 'package:streaming_and_chat_app/presentation/home_page.dart';
// import 'package:streaming_and_chat_app/presentation/login_page.dart';
// import 'package:streaming_and_chat_app/presentation/profile_page.dart';
// import 'package:streaming_and_chat_app/presentation/register_page.dart';
// import 'package:streaming_and_chat_app/presentation/watch_stream_page.dart';

// class AppRouter {
//   static final GoRouter router = GoRouter(
//     initialLocation: '/login',
//     redirect: (context, state) {
//       final authState = context.read<AuthCubit>().state;
//       final isAuthenticated = authState is AuthAuthenticated;
//       final isAuthRoute =
//           state.matchedLocation.startsWith('/login') ||
//           state.matchedLocation.startsWith('/register') ||
//           state.matchedLocation.startsWith('/forgot-password');

//       if (isAuthenticated && isAuthRoute) {
//         return '/home';
//       }

//       // If not authenticated and trying to access protected routes, redirect to login
//       if (!isAuthenticated && !isAuthRoute) {
//         return '/login';
//       }

//       return null;
//     },
//     routes: [
//       // Auth routes
//       GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
//       GoRoute(
//         path: '/register',
//         builder: (context, state) => const RegisterPage(),
//       ),
//       GoRoute(
//         path: '/forgot-password',
//         builder: (context, state) => const ForgotPasswordPage(),
//       ),

//       // Main routes
//       GoRoute(path: '/home', builder: (context, state) => const HomePage()),
//       GoRoute(
//         path: '/profile',
//         builder: (context, state) => const ProfilePage(),
//       ),
//       GoRoute(
//         path: '/edit-profile',
//         builder: (context, state) => const EditProfilePage(),
//       ),

//       // Streaming routes
//       GoRoute(
//         path: '/go-live',
//         builder: (context, state) => const GoLivePage(),
//       ),
//       GoRoute(
//         path: '/watch-stream',
//         builder: (context, state) {
//           final stream = state.extra as StreamModel;
//           return WatchStreamPage(stream: stream);
//         },
//       ),
//     ],
//   );
// }
