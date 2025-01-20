import 'package:postgres/postgres.dart';

class DatabaseConnection {

  PostgreSQLConnection? _connection;

  DatabaseConnection() {
    _connection = PostgreSQLConnection(
      'localhost',
      5433,
      'dacn3',
      username: 'postgres',
      password: '12345',
    );
  }

  Future<void> connect() async {
    try {
      if (_connection != null && _connection!.isClosed) {
        await _connection!.open();

        //ignore: avoid_print
        print("Kết nối cơ sở dữ liệu thành công.");
      }
    } catch (e) {
      //ignore: avoid_print
      print("Lỗi kết nối cơ sở dữ liệu: $e");
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      if (_connection != null && !_connection!.isClosed) {
        await _connection!.close();
        //ignore: avoid_print
        print("Kết nối đã được đóng.");
      }
    } catch (e) {
      //ignore: avoid_print
      print("Lỗi khi đóng kết nối: $e");
    }
  }

  Future<List<List<dynamic>>> executeQuery(String query) async {
    if (_connection == null || _connection!.isClosed) {
      throw Exception("Kết nối chưa được mở.");
    }
    try {
      return await _connection!.query(query);
    } catch (e) {
      //ignore: avoid_print
      print("Lỗi khi thực hiện truy vấn: $e");
      rethrow;
    }
  }
}
