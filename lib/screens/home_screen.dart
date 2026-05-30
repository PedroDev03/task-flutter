import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../database/storage_service.dart';
import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import '../services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cadastro_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Medicamento>> _medicamentosFuture;
  late Future<List<HistoricoIngestao>> _historicoFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          AwesomeNotifications().requestPermissionToSendNotifications();
        }
      });
    }
    _loadDados();
  }

  void _loadDados() {
    setState(() {
      _medicamentosFuture = widget.storage.getMedicamentos();
      _historicoFuture = widget.storage.getHistorico();
    });
  }

  void _marcarTomado(int medicamentoId) async {
    await widget.storage.registrarIngestao(medicamentoId, DateTime.now());
    _loadDados();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(storage: widget.storage)),
      );
    }
  }

  Future<void> _abrirMapas() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=farmácias+próximas');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
        );
      }
    }
  }

  void _perguntarIA(String nomeMedicamento) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Chave da API do Gemini não configurada.');

      final prompt = 'Gere um resumo curto e objetivo, em português, sobre os efeitos e cuidados ao tomar $nomeMedicamento.';
      
      final dio = Dio();
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      final responseText = response.data['candidates']?[0]['content']['parts']?[0]['text'];

      if (mounted) {
        Navigator.pop(context); // Fechar loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Resumo com IA', style: GoogleFonts.outfit()),
              ],
            ),
            content: SingleChildScrollView(child: MarkdownBody(data: responseText ?? 'Nenhuma resposta.', styleSheet: MarkdownStyleSheet(p: GoogleFonts.inter()))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao contactar IA: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Medicamentos do Dia', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.health_and_safety, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text('Saúde & Lembretes', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.teal),
              title: const Text('Farmácias Próximas'),
              onTap: () {
                Navigator.pop(context);
                _abrirMapas();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([_medicamentosFuture, _historicoFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro de Rede: ${snapshot.error}', textAlign: TextAlign.center));
          }

          final medicamentos = snapshot.data![0] as List<Medicamento>;

          if (medicamentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid_outlined, size: 80, color: Colors.teal.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum medicamento\ncadastrado.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: medicamentos.length,
            itemBuilder: (context, index) {
              final med = medicamentos[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.teal.shade100, width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.medication, color: Colors.teal.shade700, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.nome,
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.teal.shade900),
                            ),
                            const SizedBox(height: 4),
                            Text('${med.dosagem} • ${med.frequencia}', style: GoogleFonts.inter(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Horário: ${med.horarioProgramado}', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.teal.shade800)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                            onPressed: () => _perguntarIA(med.nome),
                            tooltip: 'Perguntar à IA',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              await widget.storage.deleteMedicamento(med.id);
                              _loadDados();
                            },
                          ),
                        ],
                      )
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
            _loadDados();
          }
        },
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Adicionar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
