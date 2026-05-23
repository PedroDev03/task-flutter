import 'package:postgres/postgres.dart';

class PostgresConnectionHelper {
  // Singleton
  static final PostgresConnectionHelper _instance = PostgresConnectionHelper._internal();

  factory PostgresConnectionHelper() => _instance;

  PostgresConnectionHelper._internal();

  Connection? _connection;

  // Parâmetros fáceis de configurar (10.0.2.2 para emulador Android)
  String host = '10.0.2.2';
  int port = 5432;
  String databaseName = 'saude_db'; // Mude para o nome do seu banco de dados
  String username = 'postgres'; // Mude para o seu usuário
  String password = 'password'; // Mude para a sua senha

  Connection get connection {
    if (_connection == null || !_connection!.isOpen) {
      throw Exception("Conexão não está aberta. Chame open() primeiro.");
    }
    return _connection!;
  }

  Future<void> open() async {
    if (_connection != null && _connection!.isOpen) {
      return;
    }

    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: databaseName,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable, // Útil para desenvolvimento local
      ),
    );

    await _createTablesIfNotExists();
  }

  Future<void> close() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }
  }

  Future<void> _createTablesIfNotExists() async {
    final queries = [
      '''
      CREATE TABLE IF NOT EXISTS medicamentos (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(255) NOT NULL,
        dosagem VARCHAR(255) NOT NULL,
        horario_programado TIME NOT NULL,
        ativo BOOLEAN DEFAULT TRUE NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS historico_ingestao (
        id SERIAL PRIMARY KEY,
        medicamento_id INT NOT NULL,
        data_hora_tomado TIMESTAMP NOT NULL,
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS sintomas (
        id SERIAL PRIMARY KEY,
        descricao TEXT NOT NULL,
        intensidade INT NOT NULL,
        data_hora_registro TIMESTAMP NOT NULL
      );
      '''
    ];

    for (var query in queries) {
      await _connection!.execute(query);
    }
  }
}
