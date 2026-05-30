import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';

class AuthService {
  final Dio _dio = DioClient().dio;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/v1/signup',
        data: {'email': email, 'password': password},
      );
      await _saveTokens(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/v1/token?grant_type=password',
        data: {'email': email, 'password': password},
      );
      await _saveTokens(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/v1/logout');
    } catch (_) {
      // Ignora erro no servidor se já estiver inválido, mas remove local.
    } finally {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_id');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final userId = data['user']?['id'];

    if (accessToken != null) await _secureStorage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    if (userId != null) await _secureStorage.write(key: 'user_id', value: userId);
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return e.response?.data['error_description'] ?? e.response?.data['msg'] ?? 'Erro desconhecido';
    }
    return 'Erro de conexão. Verifique sua internet.';
  }
}
