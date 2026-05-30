import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  final _secureStorage = const FlutterSecureStorage();

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    final baseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _secureStorage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Tratar 401 (Token Expirado)
          if (e.response?.statusCode == 401) {
            // Tentar refresh token (simplificado para VA2)
            // Em uma app real de produção faríamos refresh aqui antes de falhar
          }
          return handler.next(e);
        },
      ),
    );
  }
}
