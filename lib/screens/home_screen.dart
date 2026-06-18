import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../database/storage_service.dart';
import '../models/medicamento.dart';
import '../models/historico_ingestao.dart';
import '../services/auth_service.dart';
import '../providers/medicamento_provider.dart';
import 'cadastro_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentoProvider>().loadDados();
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
    try {
      await context.read<MedicamentoProvider>().marcarTomado(medicamentoId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar dose: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
      
      final model = GenerativeModel(
        model: 'gemini-3.5-flash', 
        apiKey: apiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

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

  void _verificarInteracoesIA() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final medicamentos = context.read<MedicamentoProvider>().medicamentos;
      if (medicamentos.isEmpty || medicamentos.length == 1) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicione pelo menos dois medicamentos para verificar interações.')),
          );
        }
        return;
      }

      final nomesMedicamentos = medicamentos.map((m) => m.nome).join(', ');

      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('Chave da API do Gemini não configurada.');

      final prompt = '''
Analise os seguintes medicamentos: $nomesMedicamentos.
Retorne um JSON estrito contendo possíveis interações medicamentosas.
O JSON deve ter EXATAMENTE este formato:
{
  "interacoes": [
    {
      "medicamentos": ["Nome1", "Nome2"],
      "gravidade": "Alta" ou "Média" ou "Baixa",
      "descricao": "Explicação da interação"
    }
  ],
  "recomendacao_geral": "Texto da recomendação"
}
Se não houver interações conhecidas, retorne a lista "interacoes" vazia. NÃO ADICIONE NENHUM TEXTO FORA DO JSON.
''';

      final model = GenerativeModel(
        model: 'gemini-3.5-flash', 
        apiKey: apiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      
      String responseText = response.text ?? '';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic> jsonResponse = jsonDecode(responseText);
      final List<dynamic> interacoes = jsonResponse['interacoes'] ?? [];
      final String recomendacao = jsonResponse['recomendacao_geral'] ?? '';

      if (mounted) {
        Navigator.pop(context); // Fechar loading
        _mostrarResultadoInteracoes(interacoes, recomendacao);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar interações: $e')),
        );
      }
    }
  }

  void _mostrarResultadoInteracoes(List<dynamic> interacoes, String recomendacao) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text('Análise de Interações', style: GoogleFonts.outfit())),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (interacoes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Nenhuma interação perigosa detectada.', style: GoogleFonts.inter())),
                        ],
                      ),
                    )
                  else
                    ...interacoes.map((interacao) {
                      final gravidade = interacao['gravidade'] ?? 'Baixa';
                      Color corGravidade = Colors.blue;
                      IconData iconeGravidade = Icons.info;
                      
                      if (gravidade.toString().toLowerCase().contains('alta')) {
                        corGravidade = Colors.red;
                        iconeGravidade = Icons.error;
                      } else if (gravidade.toString().toLowerCase().contains('média') || gravidade.toString().toLowerCase().contains('media')) {
                        corGravidade = Colors.orange;
                        iconeGravidade = Icons.warning;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: corGravidade.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: corGravidade.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(iconeGravidade, color: corGravidade, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${interacao['medicamentos']?.join(' + ')}',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: corGravidade),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${interacao['descricao']}', style: GoogleFonts.inter()),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text('Recomendação:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recomendacao, style: GoogleFonts.inter()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))
          ],
        );
      },
    );
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
      if (mounted) context.read<MedicamentoProvider>().loadDados();
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
                final provider = context.read<MedicamentoProvider>();
                Navigator.pop(context);
                
                try {
                  await provider.excluirMedicamento(med.id);
                  if (!kIsWeb) {
                    await AwesomeNotifications().cancel(med.id);
                  }
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('"${med.nome}" foi excluído.')),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Erro ao excluir: $e')),
                  );
                }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Medicamentos do Dia', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colorScheme.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analisar Interações',
            onPressed: _verificarInteracoesIA,
          ),
        ],
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
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
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
      body: Consumer<MedicamentoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadDados(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              )
            );
          }

          final medicamentos = provider.medicamentos;
          final historico = provider.historico;

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
              final tomado = _foiTomadoHoje(med.id, historico);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tomado ? Colors.green.shade100 : Colors.teal.shade50,
                        radius: 28,
                        child: Icon(
                          tomado ? Icons.check_circle : Icons.medication,
                          color: tomado ? Colors.green : Colors.teal.shade700,
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
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text('${med.dosagem} • ${med.frequencia}', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Horário: ${med.horarioProgramado}', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colorScheme.primary)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!tomado)
                            ElevatedButton(
                              onPressed: () => _marcarTomado(med.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Tomar'),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text('Tomado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                                onPressed: () => _perguntarIA(med.nome),
                                tooltip: 'Perguntar à IA',
                              ),
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
            if (mounted) context.read<MedicamentoProvider>().loadDados();
          }
        },
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Adicionar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
