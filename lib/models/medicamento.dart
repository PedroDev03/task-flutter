class Medicamento {
  final int id;
  final String nome;
  final String dosagem;
  final String frequencia;
  final String horarioProgramado;
  final bool ativo;
  final String? usuarioId;
  final DateTime dataCriacao;

  Medicamento({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.frequencia,
    required this.horarioProgramado,
    required this.ativo,
    this.usuarioId,
    required this.dataCriacao,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      id: json['id'] as int,
      nome: json['nome'] as String,
      dosagem: json['dosagem'] as String,
      frequencia: json['frequencia'] as String? ?? 'Diário',
      horarioProgramado: json['horario_programado'].toString(),
      ativo: json['ativo'] as bool? ?? false,
      usuarioId: json['usuario_id'] as String?,
      dataCriacao: json['data_criacao'] != null 
          ? DateTime.parse(json['data_criacao']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'dosagem': dosagem,
      'frequencia': frequencia,
      'horario_programado': horarioProgramado,
      'ativo': ativo,
      if (usuarioId != null) 'usuario_id': usuarioId,
      // Não enviamos data_criacao se for automático no BD, ou podemos enviar.
    };
  }
}
