import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import '../models/sintoma.dart';

abstract class StorageService {
  Future<void> init();

  Future<List<Medicamento>> getMedicamentos();
  Future<int> insertMedicamento(String nome, String dosagem, String frequencia, String horarioProgramado);
  Future<void> updateMedicamento(int id, String nome, String dosagem, String frequencia, String horarioProgramado);
  Future<void> updateMedicamentoStatus(int id, bool ativo);
  Future<void> deleteMedicamento(int id);

  Future<List<HistoricoIngestao>> getHistorico();
  Future<void> registrarIngestao(int medicamentoId, DateTime dataHoraTomado);

  Future<List<Sintoma>> getSintomas();
  Future<void> registrarSintoma(String descricao, int intensidade, DateTime dataHoraRegistro);

  bool get isPostgres;
}
