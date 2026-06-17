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
