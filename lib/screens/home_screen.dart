import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import '../database/storage_service.dart';
import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import 'cadastro_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Medicamento>> _medicamentosFuture;
  late Future<List<HistoricoIngestao>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  void _loadDados() {
    setState(() {
      _medicamentosFuture = widget.storage.getMedicamentos();
      _historicoFuture = widget.storage.getHistorico();
    });
  }

  bool _foiTomadoHoje(int medicamentoId, List<HistoricoIngestao> historico) {
    final hoje = DateTime.now();
    return historico.any((h) =>
        h.medicamentoId == medicamentoId &&
        h.dataHoraTomado.year == hoje.year &&
        h.dataHoraTomado.month == hoje.month &&
        h.dataHoraTomado.day == hoje.day);
  }

  void _marcarTomado(int medicamentoId) async {
    await widget.storage.registrarIngestao(medicamentoId, DateTime.now());
    _loadDados();
  }

  void _editarMedicamento(Medicamento med) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroScreen(
          storage: widget.storage,
          medicamento: med,
        ),
      ),
    );
    if (result == true) {
      _loadDados();
    }
  }

  void _confirmarExclusao(Medicamento med) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza de que deseja excluir o medicamento "${med.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await widget.storage.deleteMedicamento(med.id);
                if (!kIsWeb) {
                  await AwesomeNotifications().cancel(med.id);
                }
                _loadDados();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('"${med.nome}" foi excluído.')),
                );
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos do Dia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder(
        future: Future.wait([_medicamentosFuture, _historicoFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final medicamentos = snapshot.data![0] as List<Medicamento>;
          final historico = snapshot.data![1] as List<HistoricoIngestao>;

          if (medicamentos.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum medicamento cadastrado.\nToque no botão + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: medicamentos.length,
            itemBuilder: (context, index) {
              final med = medicamentos[index];
              final tomado = _foiTomadoHoje(med.id, historico);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tomado ? Colors.green.shade100 : Colors.orange.shade100,
                        radius: 28,
                        child: Icon(
                          tomado ? Icons.check_circle : Icons.schedule,
                          color: tomado ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.nome,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('${med.dosagem} • ${med.frequencia}', style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 4),
                            Text('Horário: ${med.horarioProgramado}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      if (!tomado)
                        ElevatedButton(
                          onPressed: () => _marcarTomado(med.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Tomar'),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text('Tomado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                        onSelected: (value) {
                          if (value == 'editar') {
                            _editarMedicamento(med);
                          } else if (value == 'excluir') {
                            _confirmarExclusao(med);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CadastroScreen(storage: widget.storage)),
          );
          if (result == true) {
            _loadDados(); // Recarrega os dados caso um novo seja adicionado
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}
