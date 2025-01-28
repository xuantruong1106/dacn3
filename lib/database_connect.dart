import 'package:postgres/postgres.dart';

class DatabaseConnection {
  PostgreSQLConnection? connection;

  // khi chạy trên windows app: dùng host: localhost
  // khi chạy trên giả lập: dùng host: 10.0.2.2
  final String localhost = '10.0.2.2';
  final int port = 5433;
  final String databaseName = 'dacn3';
  final String username = 'postgres';
  final String password = '12345';

  DatabaseConnection() {
    connection = PostgreSQLConnection(
      localhost,
      port,
      databaseName,
      username: username,
      password: password,
    );
  }

  Future<void> connect() async {
    if (connection == null || connection!.isClosed) {
      connection = PostgreSQLConnection(
        localhost,
        port,
        databaseName,
        username: username,
        password: password,
      );
    }
    await connection?.open();
  }

  Future<List<List<dynamic>>> executeQuery(String query, {Map<String, dynamic>? substitutionValues}) async {
    if (connection == null) {
      throw Exception('Database connection is not initialized.');
    }
    return await connection!.query(query, substitutionValues: substitutionValues);
  }
}
