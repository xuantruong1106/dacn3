import 'package:flutter/material.dart';
import '../database_connect.dart';

class DashboardInterface extends StatefulWidget {
  DashboardInterface({super.key});

  final db = DatabaseConnection();

  @override
  State<StatefulWidget> createState() {
    return DashboardState();
  }
}

class DashboardState extends State<DashboardInterface> {
  late bool isLoading;
  late List<Map<String, dynamic>> data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    data = [];
    loadData();
  }

  Future<void> loadData() async {
    try {
      await widget.db.connect();
      final results = await widget.db
          .executeQuery('SELECT username, phone, address FROM accounts');
      setState(() {
        data = results
            .map((row) => {
                  'username': row[0],
                  'phone': row[1],
                  'address': row[2],
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      await widget.db.close();
      print('Connection closed');
    }
  }

  Future? onPressed() {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70.0,
        leading: Container(
          margin: const EdgeInsets.only(left: 20, top: 15),
          width: 60, // Specify the width of the container
          height: 60,
          child: ClipOval(
            child: Image.asset(
              "assets/avatar.png",
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 10.0, bottom: 5.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 140, 140, 138),
                      fontSize: 14,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      "${data[0]['username']}",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 37, 37, 37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(205, 220, 219, 219),
                      border: Border.all(
                        color: Color.fromARGB(205, 232, 231, 231),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.search,
                      ),
                      onPressed: () {
                        onPressed();
                      },
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ))
            ],
          ),
        ),
      ),
      
      body: SafeArea(
        child: Container(
          width: 375.0,
          height: 200.0,
          decoration: BoxDecoration(
             gradient: LinearGradient(
                colors: [Color.fromARGB(255, 18, 22, 37), const Color.fromARGB(255, 52, 25, 105)], // Adjust the colors as needed
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            borderRadius: BorderRadius.circular(20.0)
          ),
          margin: const EdgeInsets.only(top: 20.0, left: 20.0),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Icon(
                    Icons.contactless,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                Positioned(
                  top: 70,
                  left: 20,
                  child: Text(
                    '1234 5678 9012 3456', // Card number
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 20,
                  child: Text(
                    'CARDHOLDER NAME', // Cardholder name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  left: 20,
                  child: Text(
                    'Expire day', // Expiration date
                    style: TextStyle(
                      color: const Color.fromARGB(255, 205, 203, 203),
                      fontSize: 14,
                    ),
                  ),
                ),
                 Positioned(
                  bottom: 10,
                  left: 20,
                  child: Text(
                    '12/24', // Expiration date
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 35,
                  left: 130,
                  child: Text(
                    'CVV', // Expiration date
                    style: TextStyle(
                      color: const Color.fromARGB(255, 205, 203, 203),
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 130,
                  child: Text(
                    '123', // CVV
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg',
                    width: 20,
                    height: 10,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 40,
                      );
                    },
                  ),
                ),
              ],              
            ), 
        ),
      ),
    );
  }
}
