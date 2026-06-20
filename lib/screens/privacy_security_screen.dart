import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacidade e Segurança',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Documentação Técnica e Configurações (Avaliação 2 - VA2)', colorScheme),
            const SizedBox(height: 16),
            
            _buildSectionTitle('1. Visão Geral e Arquitetura', colorScheme),
            _buildBodyText('Esta aplicação foi desenvolvida com foco em alta disponibilidade e segurança, utilizando os seguintes componentes:\n\n'
                '• Frontend/Mobile: Desenvolvido em Flutter com suporte para Web.\n\n'
                '• Backend as a Service (BaaS): Supabase (PostgreSQL + REST API) para autenticação e persistência de dados.\n\n'
                '• Inteligência Artificial: Integração com a API do Google Gemini para processamento inteligente de lembretes.\n\n'
                '• Infraestrutura e Deploy: Hospedado na nuvem (AWS EC2) utilizando o Dokploy como gerenciador de contêineres e Nginx como servidor web de alta performance.', colorScheme),
            const SizedBox(height: 24),

            _buildSectionTitle('2. Pré-requisitos de Instalação', colorScheme),
            _buildBodyText('Para executar este projeto em ambiente de desenvolvimento local, é necessário:\n\n'
                '• Flutter SDK (versão 3.19.0 ou superior).\n\n'
                '• Dart SDK compatível com a versão do Flutter.\n\n'
                '• Navegador web (Google Chrome, Edge ou Opera) para depuração.\n\n'
                '• Git para controle de versão.', colorScheme),
            const SizedBox(height: 24),

            _buildSectionTitle('3. Configuração de Variáveis de Ambiente', colorScheme),
            _buildBodyText('A segurança das credenciais é mantida fora do código-fonte. Na raiz do projeto, é obrigatório criar um arquivo .env contendo as seguintes chaves:\n\n'
                '• SUPABASE_URL: A URL da API REST do projeto no Supabase.\n\n'
                '• SUPABASE_ANON_KEY: A chave pública anônima para requisições seguras ao banco de dados.\n\n'
                '• GEMINI_API_KEY: A chave de autenticação para uso do serviço de Inteligência Artificial do Google.\n\n'
                'Nota de Segurança: Para o funcionamento do pacote flutter_secure_storage no ambiente Web, a inicialização do armazenamento foi configurada com WebOptions específicas, garantindo o funcionamento do JWT de sessão mesmo em contextos de roteamento direto.', colorScheme),
            const SizedBox(height: 24),

            _buildSectionTitle('4. Deploy e Configuração no Servidor (Produção)', colorScheme),
            _buildBodyText('A publicação do sistema atende aos requisitos de infraestrutura em nuvem seguindo este fluxo:\n\n'
                '• Containerização: O código-fonte contém um Dockerfile que utiliza a imagem ubuntu para instalar dependências, compilar o Flutter para Web e servir os arquivos estáticos compilados através do servidor Nginx na porta 80.\n\n'
                '• Hospedagem: O repositório está vinculado ao servidor Dokploy na AWS.\n\n'
                '• Roteamento e Rede: A porta interna 80 do Nginx é mapeada e exposta para acesso externo. Foi configurado um domínio seguro (utilizando sslip.io associado ao IP elástico da AWS) com certificado SSL Let\'s Encrypt gerado automaticamente, permitindo o tráfego via protocolo HTTPS (porta 443).', colorScheme),
            const SizedBox(height: 24),

            _buildSectionTitle('5. Como Executar (Localmente)', colorScheme),
            _buildBodyText('• Clone o repositório: git clone [link-do-repositorio]\n\n'
                '• Acesse a pasta: cd [nome-da-pasta]\n\n'
                '• Baixe as dependências: flutter pub get\n\n'
                '• Crie o arquivo .env com as credenciais.\n\n'
                '• Execute o projeto no Chrome: flutter run -d chrome', colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildBodyText(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }
}
