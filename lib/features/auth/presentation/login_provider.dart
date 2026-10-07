import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hr_mobile/core/network/api_error.dart';
import 'package:hr_mobile/core/network/dio_client.dart';
import 'package:hr_mobile/features/auth/repository/auth_repository.dart';
import 'package:hr_mobile/features/auth/models/user_model.dart';

final dioProvider = Provider((ref) => DioClient().dio);

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

final storageProvider = Provider((ref) => const FlutterSecureStorage());

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._repository, this._storage) : super(AuthState()) {
    checkToken();
  }

  Future<void> checkToken() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      try {
        final user = await _repository.getMe();
        state = state.copyWith(user: user, isAuthenticated: true);
      } catch (e) {
        await logout();
      }
    }
  }

  Future<bool> login(String login, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(login, password);
      final token = response['data']['token'];
      final userJson = response['data']['user'];
      
      await _storage.write(key: 'token', value: token);
      final user = UserModel.fromJson(userJson);
      
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
      );
      return true;
    } on DioException catch (e) {
      // 401/422 — noto'g'ri hisob ma'lumotlari; qolgan holatlarda tarmoq xatosi.
      final statusCode = e.response?.statusCode;
      final isCredentialError = statusCode == 401 || statusCode == 422;
      state = state.copyWith(
        isLoading: false,
        error: isCredentialError ? "Login yoki parol xato" : apiErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Kutilmagan xatolik yuz berdi",
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    state = AuthState();
  }

  /// Update user model (e.g. after on_work_status changes)
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageProvider);
  return AuthNotifier(repository, storage);
});
