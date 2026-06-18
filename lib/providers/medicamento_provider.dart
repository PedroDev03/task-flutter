import 'package:flutter/material.dart';
import '../database/storage_service.dart';
import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';

class MedicamentoProvider extends ChangeNotifier {
  final StorageService storage;

  MedicamentoProvider({required this.storage});

  List<Medicamento> _medicamentos = [];
  List<HistoricoIngestao> _historico = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Medicamento> get medicamentos => _medicamentos;
  List<HistoricoIngestao> get historico => _historico;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtros
  String _filtroStatus = 'Todos'; // 'Todos', 'Pendentes', 'Tomados'
  String _filtroPesquisa = ''; // Vazio significa sem filtro de pesquisa
  DateTime? _filtroData; // null significa data atual / sem filtro estrito

  String get filtroStatus => _filtroStatus;
  String get filtroPesquisa => _filtroPesquisa;
  DateTime? get filtroData => _filtroData;

  void setFiltroStatus(String status) {
    _filtroStatus = status;
    notifyListeners();
  }

  void setFiltroPesquisa(String termo) {
    _filtroPesquisa = termo;
    notifyListeners();
  }

  void setFiltroData(DateTime? data) {
    _filtroData = data;
    notifyListeners();
  }

  List<Medicamento> get medicamentosFiltrados {
    return _medicamentos.where((med) {
      // 1. Filtro de Pesquisa por Nome
      if (_filtroPesquisa.isNotEmpty) {
        if (!med.nome.toLowerCase().contains(_filtroPesquisa.toLowerCase())) {
          return false;
        }
      }
      
      // 2. Filtro de Status
      if (_filtroStatus != 'Todos') {
        final targetDate = _filtroData ?? DateTime.now();
        final bool tomado = _historico.any((h) =>
            h.medicamentoId == med.id &&
            h.dataHoraTomado.year == targetDate.year &&
            h.dataHoraTomado.month == targetDate.month &&
            h.dataHoraTomado.day == targetDate.day);

        if (_filtroStatus == 'Pendentes' && tomado) return false;
        if (_filtroStatus == 'Tomados' && !tomado) return false;
      }

      return true;
    }).toList();
  }

  Future<void> loadDados() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        storage.getMedicamentos(),
        storage.getHistorico(),
      ]);

      _medicamentos = results[0] as List<Medicamento>;
      _historico = results[1] as List<HistoricoIngestao>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarTomado(int medicamentoId) async {
    try {
      await storage.registrarIngestao(medicamentoId, DateTime.now());
      await loadDados(); // Recarrega para atualizar a tela
    } catch (e) {
      rethrow;
    }
  }

  Future<void> excluirMedicamento(int id) async {
    try {
      await storage.deleteMedicamento(id);
      await loadDados();
    } catch (e) {
      rethrow;
    }
  }
}
