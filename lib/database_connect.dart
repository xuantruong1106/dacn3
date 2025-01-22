import 'package:postgres/postgres.dart';

class DatabaseConnection {

  PostgreSQLConnection? connection;

  DatabaseConnection() {
    // khi chạy trên windows app: dùng host: localhost
    // khi chạy trên giả lập: dùng host: 10.0.2.2
    connection = PostgreSQLConnection(
      '10.0.2.2',
      5433,
      'dacn3',
      username: 'postgres',
      password: '12345',
    );
  }

  Future<void> connect() async {
    try {
      if (connection != null && connection!.isClosed) {
        await connection!.open();

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
      if (connection != null && !connection!.isClosed) {
        await connection!.close();
        //ignore: avoid_print
        print("Kết nối đã được đóng.");
      }
    } catch (e) {
      //ignore: avoid_print
      print("Lỗi khi đóng kết nối: $e");
    }
  }

  Future<List<List<dynamic>>> executeQuery(String query) async {
    if (connection == null || connection!.isClosed) {
      throw Exception("Kết nối chưa được mở.");
    }
    try {
      return await connection!.query(query);
    } catch (e) {
      //ignore: avoid_print
      print("Lỗi khi thực hiện truy vấn: $e");
      rethrow;
    }
  }
}
