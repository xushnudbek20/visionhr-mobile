import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String login, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'login': login,
        'password': password,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me', queryParameters: {
        'relations': 'role',
      });
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
