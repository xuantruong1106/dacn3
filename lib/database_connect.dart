import 'package:postgres/postgres.dart';

class DatabaseConnection {
  PostgreSQLConnection? connection;

  DatabaseConnection() {
    // khi chạy trên windows app: dùng host: localhost
    // khi chạy trên giả lập: dùng host: 10.0.2.2
    connection = PostgreSQLConnection(
      'localhost',
      5433,
      'dacn3',
      username: 'postgres',
      password: '12345',
    );
  }

  Future<void> connect() async {
    if (connection == null || connection!.isClosed) {
      connection = PostgreSQLConnection(
        'localhost',
        5433,
        'dacn3',
        username: 'postgres',
        password: '12345',
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
