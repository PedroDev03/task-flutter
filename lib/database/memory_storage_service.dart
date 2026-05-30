import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import '../models/sintoma.dart';
import 'storage_service.dart';

class MemoryStorageService implements StorageService {
  final List<Medicamento> _medicamentos = [];
  final List<HistoricoIngestao> _historico = [];
  final List<Sintoma> _sintomas = [];

  int _nextMedicamentoId = 1;
  int _nextHistoricoId = 1;
  int _nextSintomaId = 1;

  @override
  bool get isPostgres => false;

  @override
  Future<void> init() async {
    if (_medicamentos.isNotEmpty) return;

    // Popula com dados simulados
    _addMedicamento('Paracetamol 750mg', '1 comprimido', 'Diário', '08:00');
    _addMedicamento('Ibuprofeno 600mg', '1 cápsula', '8 em 8 horas', '14:00');
    _addMedicamento('Losartana Potássica 50mg', '1 comprimido', 'Diário', '20:00');

    // Popula histórico
    _addHistorico(1, DateTime.now().subtract(const Duration(hours: 12)));
    _addHistorico(2, DateTime.now().subtract(const Duration(hours: 6)));

    // Popula sintomas
    _addSintoma('Dor de cabeça moderada', 5, DateTime.now().subtract(const Duration(hours: 4)));
    _addSintoma('Febre leve e calafrios', 3, DateTime.now().subtract(const Duration(days: 1)));
  }

  void _addMedicamento(String nome, String dosagem, String frequencia, String horario) {
    _medicamentos.add(Medicamento(
      id: _nextMedicamentoId++,
      nome: nome,
      dosagem: dosagem,
      frequencia: frequencia,
      horarioProgramado: horario,
      ativo: true,
    ));
  }

  void _addHistorico(int medicamentoId, DateTime dataHora) {
    _historico.add(HistoricoIngestao(
      id: _nextHistoricoId++,
      medicamentoId: medicamentoId,
      dataHoraTomado: dataHora,
    ));
  }

  void _addSintoma(String descricao, int intensidade, DateTime dataHora) {
    _sintomas.add(Sintoma(
      id: _nextSintomaId++,
      descricao: descricao,
      intensidade: intensidade,
      dataHoraRegistro: dataHora,
    ));
  }

  @override
  Future<List<Medicamento>> getMedicamentos() async {
    return List.from(_medicamentos);
  }

  @override
  Future<int> insertMedicamento(String nome, String dosagem, String frequencia, String horarioProgramado) async {
    final id = _nextMedicamentoId++;
    _medicamentos.add(Medicamento(
      id: id,
      nome: nome,
      dosagem: dosagem,
      frequencia: frequencia,
      horarioProgramado: horarioProgramado,
      ativo: true,
    ));
    return id;
  }

  @override
  Future<void> updateMedicamento(int id, String nome, String dosagem, String frequencia, String horarioProgramado) async {
    final index = _medicamentos.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _medicamentos[index];
      _medicamentos[index] = Medicamento(
        id: old.id,
        nome: nome,
        dosagem: dosagem,
        frequencia: frequencia,
        horarioProgramado: horarioProgramado,
        ativo: old.ativo,
      );
    }
  }

  @override
  Future<void> updateMedicamentoStatus(int id, bool ativo) async {
    final index = _medicamentos.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _medicamentos[index];
      _medicamentos[index] = Medicamento(
        id: old.id,
        nome: old.nome,
        dosagem: old.dosagem,
        frequencia: old.frequencia,
        horarioProgramado: old.horarioProgramado,
        ativo: ativo,
      );
    }
  }

  @override
  Future<void> deleteMedicamento(int id) async {
    _medicamentos.removeWhere((m) => m.id == id);
    _historico.removeWhere((h) => h.medicamentoId == id);
  }

  @override
  Future<List<HistoricoIngestao>> getHistorico() async {
    return List.from(_historico);
  }

  @override
  Future<void> registrarIngestao(int medicamentoId, DateTime dataHoraTomado) async {
    _addHistorico(medicamentoId, dataHoraTomado);
  }

  @override
  Future<List<Sintoma>> getSintomas() async {
    return List.from(_sintomas);
  }

  @override
  Future<void> registrarSintoma(String descricao, int intensidade, DateTime dataHoraRegistro) async {
    _addSintoma(descricao, intensidade, dataHoraRegistro);
  }
}
