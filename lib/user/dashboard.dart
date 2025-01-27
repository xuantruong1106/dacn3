import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database_connect.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardInterface extends StatefulWidget {
  DashboardInterface({super.key});

  final db = DatabaseConnection();

  @override
  State<StatefulWidget> createState() {
    return DashboardState();
  }
}

class DashboardState extends State<DashboardInterface> {
  // late bool isLoading;
  late List<Map<String, dynamic>> dataUser;
  late List<Map<String, dynamic>> dataTrancsaction;

  @override
  void initState() {
    super.initState();
    // isLoading = true;
    dataUser = [];
    dataTrancsaction = [];
    getInfoUser().then((_) {
      getInfoTransaction();
    });
  }

  Future<void> getInfoUser() async {
    try {
      await widget.db.connect();
      final results = await widget.db.executeQuery('SELECT * FROM getUserAndCardInfo(@id);',
        substitutionValues: {
            'id': 1,
        });

      setState(() {
        dataUser = results
            .map((row) => {
                  'username': row[0],
                  'phone': row[1],
                  'address': row[2],
                  'card_number': row[3],
                  'card_holder_name': row[4],
                  'total_amount': row[5],
                })
            .toList();
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
    } finally {
      await widget.db.connection?.close();
      print('Connection closed for getInfoUser');
    }
  }

  Future? getInfoTransaction() async {
    try {
      await widget.db.connect();

      // ignore: avoid_print
      print('Connected to the database');

      final results = await widget.db.executeQuery('SELECT * FROM gettransactions(@id);',
        substitutionValues: {
         'id': 1,
        });
      
      setState(() {

        if (dataTrancsaction.isEmpty) {
          dataTrancsaction = results.map((row) => {
                  'type_transaction': row[1],
                  'transaction_hash': row[2],
                  'card_holder_name': row[13],
                  'account_owner': row[14],
          }).toList();
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
    } finally {
      await widget.db.connection?.close();
      // ignore: avoid_print
      print('Connection closed for getInfoTransaction');
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
                    'Welcome,',
                    style: GoogleFonts.roboto(textStyle: TextStyle(fontSize: 16,color: Colors.grey)),
                  ),
                  Text(
                    "${dataUser[0]['username']}",
                    style: GoogleFonts.roboto(textStyle: TextStyle(fontSize: 20,color: Colors.black)),
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
                      // Implement search functionality here
                    },
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ATM Card Section
            Container(
              width: 375.0,
              height: 200.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4B5B98), Color.fromARGB(255, 52, 25, 105)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
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
                      "${dataUser[0]['card_number']}", // Card number
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
                      "${dataUser[0]['card_holder_name']}", // Cardholder name
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
                    bottom: 10,
                    right: 30,
                    child: SvgPicture.asset(
                      "assets/mastercard.svg",
                      width: 70,
                      height: 60,
                      placeholderBuilder: (context) => Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Options Section
            Padding(
              padding: const EdgeInsets.only(
                  top: 20.0), // Space between the sections
              child: Container(
                width: 375.0,
                height: 100.0,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color.fromARGB(205, 232, 231, 231), width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.attach_money,
                              size: 40, color: Colors.black),
                        ),
                        Text('Sent', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color.fromARGB(205, 232, 231, 231), width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.money_off,
                              size: 40, color: Colors.black),
                        ),
                        Text('Receive', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color.fromARGB(205, 232, 231, 231), width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.account_balance,
                              size: 40, color: Colors.black),
                        ),
                        Text('Loan', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 20.0),
              child: Row(
                children: [
                  Text(
                    'Transaction',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(fontSize: 20),
                    ),
                  ),
                  Spacer(),
                  Padding(padding: const EdgeInsets.only(right: 20.0),
                  child: Text(
                    'Sell All',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(fontSize: 16, color:  Color(0xFF0066FF)),
                    ),
                  ),
                  )
                  
                ],
              ),     
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 20.0),
              child: Row(
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: dataTrancsaction.isNotEmpty
                        ? Text(
                            '${dataTrancsaction[0]['account_owner']}',
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(fontSize: 16, color: Color(0xFF0066FF)),
                            ),
                          )
                        : Text(
                            "No Data",
                            style: GoogleFonts.roboto(
                              textStyle: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ),
                  ),
                ],
              ),
            )
            ,
          ],
        ),
      ),
    );
  }
}
