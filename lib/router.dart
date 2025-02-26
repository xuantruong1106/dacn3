import 'package:flutter/material.dart';
import 'package:dacn3/screens/user/my_card.dart';
import 'package:dacn3/screens/user/sign_in.dart';
import 'package:dacn3/screens/user/sign_up.dart';
import 'package:dacn3/screens/user/user.dart';
import 'package:dacn3/screens/user/send_money.dart';
import 'package:dacn3/screens/user/request_money.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => CheckLoginScreen());
      case '/main':
        final userId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => UserScreen(userId: userId));
      case '/sign_in':
        return MaterialPageRoute(builder: (_) => SignInScreen());
      case '/sign_up':
        return MaterialPageRoute(builder: (_) => SignUpScreen());
      case '/my_card':
        final int userId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => MyCardsScreen(userId: userId));
      // case '/sent':
      //   return MaterialPageRoute(builder: (_) => SendMoneyScreen());
      // case '/loan':
      //   return MaterialPageRoute(builder: (_) => SendMoneyScreen());
      // case 'moneylimit':
      //   return MaterialPageRoute(builder: (_) => SendMoneyScreen());
      case '/requestmoney':
        return MaterialPageRoute(builder: (_) => RequestMoneyScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class CheckLoginScreen extends StatelessWidget {
  const CheckLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check login state here
    // bool isLoggedIn = false; // Replace with your login state check

    Future.microtask(() => Navigator.pushReplacementNamed(context, '/welcome'));

    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
