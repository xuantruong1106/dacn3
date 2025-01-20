
import '/user/dashboard.dart';
import 'package:flutter/material.dart';

void main(List<String> arguments) async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text('Dashboard'),
          ),
          body: Center(
            child: MainApp()
            ),
          ),
        )
      )
  );
}
