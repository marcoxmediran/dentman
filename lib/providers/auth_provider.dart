import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'database_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final String? email;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.errorMessage,
    this.email,
  });

  factory AuthState.initial() =>
      AuthState(isAuthenticated: false, isLoading: false);

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // We reset error on update if null
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    // Listen to Firebase auth changes if we are in live mode
    _ref.listen(useMockDatabaseProvider, (previous, next) {
      _checkCurrentAuthState();
    });
    _checkCurrentAuthState();
  }

  void _checkCurrentAuthState() {
    final useMock = _ref.read(useMockDatabaseProvider);
    if (useMock) {
      // In mock mode, keep current state or default to authenticated for easier testing
      // Actually, let's default to NOT authenticated in mock too, so the login page can be demonstrated,
      // but allow immediate login with preset credentials.
      state = AuthState(isAuthenticated: false, isLoading: false);
    } else {
      // Listen to Firebase Auth state
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      state = AuthState(
        isAuthenticated: user != null,
        isLoading: false,
        email: user?.email,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final useMock = _ref.read(useMockDatabaseProvider);

    if (useMock) {
      await Future.delayed(const Duration(seconds: 1)); // Mock latency
      if (email.trim() == 'mock@email.com' && password == 'mock123') {
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          email: 'mock@email.com',
        );
        return true;
      } else {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage:
              'Invalid clinic email or password. Use: mock@email.com / mock123',
        );
        return false;
      }
    } else {
      try {
        await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          email: email.trim(),
        );
        return true;
      } on firebase_auth.FirebaseAuthException catch (e) {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: e.message ?? 'Authentication failed',
        );
        return false;
      } catch (e) {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'An unexpected error occurred',
        );
        return false;
      }
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final useMock = _ref.read(useMockDatabaseProvider);

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      state = AuthState.initial();
    } else {
      await firebase_auth.FirebaseAuth.instance.signOut();
      state = AuthState.initial();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
