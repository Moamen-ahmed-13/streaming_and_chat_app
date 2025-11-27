import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streaming_and_chat_app/core/logger.dart';
import 'package:streaming_and_chat_app/data/services/auth_service.dart';
import 'package:streaming_and_chat_app/logic/auth_cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial()) {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      AppLogger.error('Error checking auth status', e);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _authService.getUserData(userId);
      emit(AuthAuthenticated(userData));
    } catch (e) {
      AppLogger.error('Error loading user data', e);
      emit(const AuthError('Failed to load user data'));
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    try {
      emit(AuthLoading());
      AppLogger.info('Registering user...');
      
      final user = await _authService.registerWithEmail(email, password, displayName);
      emit(AuthAuthenticated(user));
    } catch (e) {
      AppLogger.error('Registration error', e);
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      AppLogger.info('Logging in user...');
      
      final user = await _authService.loginWithEmail(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      AppLogger.error('Login error', e);
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      AppLogger.info('Signing in with Google...');
      
      final user = await _authService.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      AppLogger.error('Google sign in error', e);
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      emit(AuthLoading());
      AppLogger.info('Sending password reset email...');
      
      await _authService.sendPasswordResetEmail(email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      AppLogger.error('Password reset error', e);
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('Logging out...');
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      AppLogger.error('Logout error', e);
      emit(AuthError(e.toString()));
    }
  }
}
