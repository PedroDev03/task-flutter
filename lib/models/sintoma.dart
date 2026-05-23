import 'package:postgres/postgres.dart';

class Sintoma {
  final int id;
  final String descricao;
  final int intensidade;
  final DateTime dataHoraRegistro;

  Sintoma({
    required this.id,
    required this.descricao,
    required this.intensidade,
    required this.dataHoraRegistro,
  });

  factory Sintoma.fromPostgresRow(ResultRow row) {
    // Usando toColumnMap() para mapear os dados corretamente pelo nome da coluna
    final map = row.toColumnMap();
    return Sintoma(
      id: map['id'] as int,
      descricao: map['descricao'] as String,
      intensidade: map['intensidade'] as int,
      dataHoraRegistro: map['data_hora_registro'] as DateTime,
    );
  }
}
