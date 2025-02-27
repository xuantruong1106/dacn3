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
      case '/sent':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => RequestMoneyScreen( userId: args['userId'] as int,
                                                                      username: args['username'] as String,));
      case '/loan':
        final int userId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => SendMoneyScreen(userId: userId));
      case 'moneylimit':
        final int userId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => SendMoneyScreen(userId: userId));
      case '/requestmoney':
       final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => RequestMoneyScreen( userId: args['userId'] as int,
                                                                      username: args['username'] as String,));
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
    Future.microtask(() => Navigator.pushReplacementNamed(context, '/welcome'));
    

    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
