import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  final _secureStorage = const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'secure_storage', publicKey: 'secret_key'),
  );

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    final baseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'apikey': anonKey, 'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

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
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/auth/v1/token')) {
            final refreshTokenStr = await _secureStorage.read(
              key: 'refresh_token',
            );
            if (refreshTokenStr != null && refreshTokenStr.isNotEmpty) {
              try {
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: dotenv.env['SUPABASE_URL'] ?? '',
                    headers: {
                      'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
                      'Content-Type': 'application/json',
                    },
                  ),
                );
                final refreshResponse = await refreshDio.post(
                  '/auth/v1/token?grant_type=refresh_token',
                  data: {'refresh_token': refreshTokenStr},
                );

                final newAccess = refreshResponse.data['access_token'];
                final newRefresh = refreshResponse.data['refresh_token'];

                if (newAccess != null) {
                  await _secureStorage.write(
                    key: 'access_token',
                    value: newAccess,
                  );
                  await _secureStorage.write(
                    key: 'refresh_token',
                    value: newRefresh,
                  );

                  // Refazer a request original
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newAccess';
                  final cloneReq = await dio.request(
                    e.requestOptions.path,
                    options: Options(
                      method: e.requestOptions.method,
                      headers: e.requestOptions.headers,
                    ),
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                // Falhou o refresh token, limpar local
                await _secureStorage.delete(key: 'access_token');
                await _secureStorage.delete(key: 'refresh_token');
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}
