// import 'package:dacn3/screens/user/home_2.dart';
// import 'package:dacn3/screens/user/send_money.dart';
// import 'package:dacn3/screens/user/statistics.dart';
import 'package:flutter/material.dart';
import 'package:dacn3/screens/user/sign_in.dart';
import 'package:dacn3/router.dart';

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SafeArea(
        child: SignInScreen(),
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SignInScreen()),
    );
  }
}
