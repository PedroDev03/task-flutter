import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import '../database/storage_service.dart';
import '../models/medicamento.dart';

class CadastroScreen extends StatefulWidget {
  final StorageService storage;
  final Medicamento? medicamento;

  const CadastroScreen({super.key, required this.storage, this.medicamento});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  String _frequenciaSelecionada = 'Diário';
  TimeOfDay _horarioSelecionado = TimeOfDay.now();

  final List<String> _opcoesFrequencia = [
    'Diário',
    '8 em 8 horas',
    '12 em 12 horas',
    'Semanal',
    'Necessidade (SOS)'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      _nomeController.text = widget.medicamento!.nome;
      _dosagemController.text = widget.medicamento!.dosagem;
      _frequenciaSelecionada = widget.medicamento!.frequencia;
      try {
        final parts = widget.medicamento!.horarioProgramado.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          _horarioSelecionado = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (_) {
        // Use default
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
    );
    if (picked != null && picked != _horarioSelecionado) {
      setState(() {
        _horarioSelecionado = picked;
      });
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final horarioStr = '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}';
      
      int id;
      final isEditing = widget.medicamento != null;
      
      if (isEditing) {
        id = widget.medicamento!.id;
        await widget.storage.updateMedicamento(
          id,
          _nomeController.text,
          _dosagemController.text,
          _frequenciaSelecionada,
          horarioStr,
        );
      } else {
        id = await widget.storage.insertMedicamento(
          _nomeController.text,
          _dosagemController.text,
          _frequenciaSelecionada,
          horarioStr,
        );
      }

      if (!kIsWeb) {
        if (isEditing) {
          await AwesomeNotifications().cancel(id);
        }
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'alerts',
            title: 'Hora do Medicamento!',
            body: 'Está na hora de tomar ${_nomeController.text} (${_dosagemController.text}).',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Alarm,
            wakeUpScreen: true,
          ),
          schedule: NotificationCalendar(
            hour: _horarioSelecionado.hour,
            minute: _horarioSelecionado.minute,
            second: 0,
            millisecond: 0,
            repeats: true,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicamento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Medicamento' : 'Novo Medicamento'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Medicamento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosagemController,
                decoration: const InputDecoration(
                  labelText: 'Dosagem (ex: 1 comprimido, 50mg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a dosagem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequenciaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _opcoesFrequencia.map((String freq) {
                  return DropdownMenuItem<String>(
                    value: freq,
                    child: Text(freq),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _frequenciaSelecionada = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horário Programado'),
                subtitle: Text('${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selecionarHorario(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  isEditing ? 'Salvar Alterações' : 'Salvar Medicamento',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
