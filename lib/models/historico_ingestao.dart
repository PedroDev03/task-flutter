import 'package:postgres/postgres.dart';

class HistoricoIngestao {
  final int id;
  final int medicamentoId;
  final DateTime dataHoraTomado;

  HistoricoIngestao({
    required this.id,
    required this.medicamentoId,
    required this.dataHoraTomado,
  });

  factory HistoricoIngestao.fromPostgresRow(ResultRow row) {
    // Usando toColumnMap() para mapear os dados corretamente pelo nome da coluna
    final map = row.toColumnMap();
    return HistoricoIngestao(
      id: map['id'] as int,
      medicamentoId: map['medicamento_id'] as int,
      dataHoraTomado: map['data_hora_tomado'] as DateTime,
    );
  }

  factory HistoricoIngestao.fromJson(Map<String, dynamic> json) {
    return HistoricoIngestao(
      id: json['id'] as int,
      medicamentoId: json['medicamento_id'] as int,
      dataHoraTomado: DateTime.parse(json['data_hora_tomado'] as String),
    );
  }
}
