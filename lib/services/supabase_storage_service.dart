import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/storage_service.dart';
import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import '../models/sintoma.dart';
import 'dio_client.dart';

class SupabaseStorageService implements StorageService {
  final Dio _dio = DioClient().dio;
  final _secureStorage = const FlutterSecureStorage();
  
  // Fallback em memória para quando a tabela correspondente não existir no Supabase
  final List<HistoricoIngestao> _localHistorico = [];

  @override
  bool get isPostgres => true;

  Future<String?> _getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  @override
  Future<void> init() async {
    // Inicialização não é necessária para REST, as requisições são on-demand
  }

  @override
  Future<List<Medicamento>> getMedicamentos() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return [];

      final response = await _dio.get(
        '/rest/v1/medicamentos',
        queryParameters: {
          'usuario_id': 'eq.$userId',
          'select': '*',
        },
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => Medicamento.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> insertMedicamento(String nome, String dosagem, String frequencia, String horarioProgramado) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception("Usuário não logado");

      await _dio.post(
        '/rest/v1/medicamentos',
        data: {
          'nome': nome,
          'dosagem': dosagem,
          'frequencia': frequencia,
          'horario_programado': horarioProgramado,
          'ativo': true,
          'usuario_id': userId,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateMedicamento(int id, String nome, String dosagem, String frequencia, String horarioProgramado, bool ativo) async {
    try {
      final userId = await _getUserId();
      await _dio.patch(
        '/rest/v1/medicamentos',
        queryParameters: {
          'id': 'eq.$id',
          'usuario_id': 'eq.$userId',
        },
        data: {
          'nome': nome,
          'dosagem': dosagem,
          'frequencia': frequencia,
          'horario_programado': horarioProgramado,
          'ativo': ativo,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateMedicamentoStatus(int id, bool ativo) async {
    try {
      final userId = await _getUserId();
      await _dio.patch(
        '/rest/v1/medicamentos',
        queryParameters: {
          'id': 'eq.$id',
          'usuario_id': 'eq.$userId',
        },
        data: {
          'ativo': ativo,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteMedicamento(int id) async {
    try {
      final userId = await _getUserId();
      await _dio.delete(
        '/rest/v1/medicamentos',
        queryParameters: {
          'id': 'eq.$id',
          'usuario_id': 'eq.$userId',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<HistoricoIngestao>> getHistorico() async {
    try {
      final response = await _dio.get(
        '/rest/v1/historico_ingestao',
        queryParameters: {
          'select': '*',
        },
      );
      final List<dynamic> data = response.data;
      final remoteList = data.map((json) => HistoricoIngestao.fromJson(json)).toList();
      return [...remoteList, ..._localHistorico];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return List.from(_localHistorico);
      }
      throw _handleError(e);
    }
  }

  @override
  Future<void> registrarIngestao(int medicamentoId, DateTime dataHoraTomado) async {
    try {
      await _dio.post(
        '/rest/v1/historico_ingestao',
        data: {
          'medicamento_id': medicamentoId,
          'data_hora_tomado': dataHoraTomado.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback local caso a tabela não exista no Supabase (para testes)
        _localHistorico.add(HistoricoIngestao(
          id: DateTime.now().millisecondsSinceEpoch,
          medicamentoId: medicamentoId,
          dataHoraTomado: dataHoraTomado,
        ));
        return;
      }
      throw _handleError(e);
    }
  }

  @override
  Future<List<Sintoma>> getSintomas() async {
    return [];
  }

  @override
  Future<void> registrarSintoma(String descricao, int intensidade, DateTime dataHoraRegistro) async {
    // Mock ou implementar
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo esgotado. Verifique sua conexão com a internet.';
    }
    if (e.response != null) {
      return 'Erro na requisição: ${e.response?.statusCode}';
    }
    return 'Sem conexão — verifique sua internet.';
  }
}
