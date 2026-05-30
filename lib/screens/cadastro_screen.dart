import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/storage_service.dart';

class CadastroScreen extends StatefulWidget {
  final StorageService storage;

  const CadastroScreen({super.key, required this.storage});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  String _frequenciaSelecionada = 'Diário';
  
  // Feature Individual B: Integração com o relógio do sistema
  late TimeOfDay _horarioSelecionado;

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
    // Integração: capturar relógio exato do computador/dispositivo ao abrir
    _horarioSelecionado = TimeOfDay.now();
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
      // Regras de negócio implícitas validadas pelo Form
      final horarioStr = '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}';
      
      showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      try {
        await widget.storage.insertMedicamento(
          _nomeController.text,
          _dosagemController.text,
          _frequenciaSelecionada,
          horarioStr,
        );

        final int h = _horarioSelecionado.hour;
        final int m = _horarioSelecionado.minute;
        final String nome = _nomeController.text;
        final String dosagem = _dosagemController.text;

        Future<void> agendar(int id, int hour) async {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: id,
              channelKey: 'alerts',
              title: 'Hora do Remédio!',
              body: 'Está na hora de tomar $nome ($dosagem)',
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar(
              hour: hour,
              minute: m,
              second: 0,
              millisecond: 0,
              repeats: true,
            ),
          );
        }

        if (!kIsWeb) {
          final baseId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
          if (_frequenciaSelecionada == 'Semanal') {
            await AwesomeNotifications().createNotification(
              content: NotificationContent(id: baseId, channelKey: 'alerts', title: 'Hora do Remédio!', body: 'Está na hora de tomar $nome ($dosagem)'),
              schedule: NotificationCalendar(weekday: DateTime.now().weekday, hour: h, minute: m, second: 0, millisecond: 0, repeats: true),
            );
          } else if (_frequenciaSelecionada == 'Diário') {
            await agendar(baseId, h);
          } else if (_frequenciaSelecionada == '8 em 8 horas') {
            await agendar(baseId, h);
            await agendar(baseId + 1, (h + 8) % 24);
            await agendar(baseId + 2, (h + 16) % 24);
          } else if (_frequenciaSelecionada == '12 em 12 horas') {
            await agendar(baseId, h);
            await agendar(baseId + 1, (h + 12) % 24);
          }
        }

        if (mounted) {
          Navigator.pop(context); // close loader
          Navigator.pop(context, true); // Retorna true para indicar sucesso
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e', style: GoogleFonts.inter())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Novo Medicamento', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Cadastre os detalhes do seu medicamento e o horário para ser lembrado.',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.teal.shade100)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        style: GoogleFonts.inter(),
                        decoration: InputDecoration(
                          labelText: 'Nome do Medicamento',
                          labelStyle: GoogleFonts.inter(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.medical_services, color: Colors.teal.shade700),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'O nome é obrigatório.';
                          }
                          if (value.length < 3) {
                            return 'Deve ter no mínimo 3 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dosagemController,
                        style: GoogleFonts.inter(),
                        decoration: InputDecoration(
                          labelText: 'Dosagem (ex: 1 comp, 50mg)',
                          labelStyle: GoogleFonts.inter(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.medication, color: Colors.teal.shade700),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'A dosagem é obrigatória.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _frequenciaSelecionada,
                        style: GoogleFonts.inter(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Frequência',
                          labelStyle: GoogleFonts.inter(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.repeat, color: Colors.teal.shade700),
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
                        title: Text('Horário Inicial (Relógio do Sistema)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: Text('${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 18, color: Colors.teal.shade900)),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.access_time, color: Colors.teal.shade700),
                        ),
                        onTap: () => _selecionarHorario(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text('Salvar Medicamento', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

