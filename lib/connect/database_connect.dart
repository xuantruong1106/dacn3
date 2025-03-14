import 'package:postgres/postgres.dart';
import 'package:flutter/widgets.dart';

class DatabaseConnection with WidgetsBindingObserver {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  PostgreSQLConnection? _connection;

  final String _host = '10.0.2.2'; // Dùng 'localhost' khi chạy trên Windows app
  final int _port = 5433;
  final String _databaseName = 'dacn3';
  final String _username = 'postgres';
  final String _password = 'andubadao123';

  // Private constructor
  DatabaseConnection._internal() {
    _connection = PostgreSQLConnection(
      _host,
      _port,
      _databaseName,
      username: _username,
      password: _password,
    );
  }

  factory DatabaseConnection() => _instance;

  // Kết nối database (chỉ mở kết nối khi cần)
  Future<void> connect() async {
    if (_connection == null || _connection!.isClosed) {
      _connection = PostgreSQLConnection(
        _host,
        _port,
        _databaseName,
        username: _username,
        password: _password,
      );
    }
    if (_connection!.isClosed) {
      await _connection!.open();
      print("✅ Database Connected");
    }
  }

  // Thực hiện truy vấn
  Future<List<List<dynamic>>> executeQuery(String query, {Map<String, dynamic>? substitutionValues}) async {
    if (_connection == null || _connection!.isClosed) {
      print("⚠️ Reconnecting to Database...");
      await connect();
    }
    return await _connection!.query(query, substitutionValues: substitutionValues);
  }

  // Đóng kết nối khi không dùng nữa
  Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      print("🔌 Database Disconnected");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      close();
    }
  }
}

