# MedTracker IA - Gerenciador de Medicamentos

Uma aplicação Flutter moderna para o controle de ingestão de medicamentos, lembretes de horários e análise de interações medicamentosas com Inteligência Artificial (Google Gemini). Desenvolvido para a disciplina de Programação para Dispositivos Móveis (VA2).

## 🚀 Funcionalidades

- **Autenticação Segura:** Login persistente utilizando JWT e `flutter_secure_storage`.
- **CRUD de Medicamentos:** Gerenciamento completo sem armazenamento local (Consumo direto de API REST).
- **Lembretes e Localização (Features Individuais):** Integração com relógio nativo para notificações e botão rápido para localizar farmácias no Google Maps.
- **Dark Mode Dinâmico:** Tema escuro ou claro customizável na aba de configurações.
- **Integração Nativa com IA (Gemini):** Resumo automático de bula de remédios e análise de interações e riscos ao misturar vários medicamentos da lista.

## 🛠 Stack Tecnológico

- **Frontend:** Flutter & Dart
- **Arquitetura:** Clean Architecture com Padrão MVVM simplificado
- **Gerenciamento de Estado:** Provider
- **Requisições de Rede:** Dio (com Interceptors para autenticação)
- **Segurança:** flutter_secure_storage (Armazenamento seguro de Tokens)
- **Inteligência Artificial:** `google_generative_ai` (Gemini 3.5 Flash)
- **Backend/API:** Supabase (REST API)

## 📦 Instruções de Instalação e Execução

**Pré-requisitos:**
- Flutter SDK (versão 3.x+)
- Um Emulador (Android/iOS) configurado ou Google Chrome para testes Web.
- Chaves do Supabase e Gemini.

1. **Clone o repositório:**
   ```bash
   git clone <url-do-repositorio>
   cd task-flutter
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configuração de Variáveis de Ambiente:**
   Renomeie o arquivo `.env.example` para `.env` (ou crie um arquivo `.env` na raiz) e insira as suas chaves:
   ```env
   SUPABASE_URL=sua_url_supabase
   SUPABASE_ANON_KEY=sua_chave_anonima
   GEMINI_API_KEY=sua_chave_do_google_gemini
   ```

4. **Executando o App:**
   ```bash
   # Para executar no emulador/dispositivo conectado
   flutter run

   # Para executar diretamente no Google Chrome
   flutter run -d chrome
   ```

## 🔑 Credenciais de Teste

Utilize as seguintes credenciais de teste configuradas no banco:

- **E-mail:** `[teste@gmail.com]`
- **Senha:** `[123456]`

> **Nota:** Caso queira testar do zero, pode utilizar o botão "Registrar-se" na tela de login para criar uma nova conta.
