import 'package:postgres/postgres.dart';

class Medicamento {
  final int id;
  final String nome;
  final String dosagem;
  final String frequencia;
  final String horarioProgramado;
  final bool ativo;

  Medicamento({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    required this.horarioProgramado,
    required this.ativo,
  });

  factory Medicamento.fromPostgresRow(ResultRow row) {
    // Usando toColumnMap() para mapear os dados corretamente pelo nome da coluna
    final map = row.toColumnMap();
    return Medicamento(
      id: map['id'] as int,
      nome: map['nome'] as String,
      dosagem: map['dosagem'] as String,
      frequencia: map['frequencia'] as String? ?? 'Diário',
      horarioProgramado: map['horario_programado'].toString(),
      ativo: map['ativo'] as bool? ?? false,
    );
  }
}
