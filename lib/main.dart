
import '/user/dashboard.dart';
import 'package:flutter/material.dart';

void main(List<String> arguments) async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // Đặt màu nền trắng cho toàn bộ ứng dụng
      ),
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          // appBar: AppBar(
          //   backgroundColor: Colors.white,
          //   title: Text('Dashboard'),
          // ),
          body: Center(
            child: DashboardInterface()
            ),
          ),
        )
      )
  );
}
