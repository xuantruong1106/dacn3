import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Home extends StatefulWidget {
  final int userId;
  Home({super.key, required this.userId});

  final db = DatabaseConnection();

  @override
  State<StatefulWidget> createState() {
    return Home2State();
  }
}

class Home2State extends State<Home> {
  // late bool isLoading;
  late List<Map<String, dynamic>> dataUser;
  late List<Map<String, dynamic>> dataTransaction;

  @override
  void initState() {
    super.initState();
    // isLoading = true;
    dataUser = [];
    dataTransaction = [];
    getInfoUser().then((_) {
      getInfoTransaction();
    });
  }

  Future<void> getInfoUser() async {
    try {
      if (widget.db.connection?.isClosed ?? true) {
        await widget.db.connect();
      }

      print('Fetching user info for ID: ${widget.userId}');

      final results = await widget.db.executeQuery(
          'SELECT * FROM get_user_and_card_info(@id);',
          substitutionValues: {
            'id': widget.userId,
          });
      // ignore: avoid_print
      print('Query Results: $results');

      if (results.isNotEmpty) {
        setState(() {
          dataUser = results
              .map((row) => {
                    'username': row[0],
                    'phone': row[1],
                    'address': row[2],
                    'card_number': row[3],
                    'cvv': row[4],
                    'expiration_date': row[5]
                        .toString()
                        .substring(0, 10)
                        .split('-')
                        .reversed
                        .join('/'),
                    'total_amount': row[6],
                  })
              .toList();
        });
      } else {
        print('No user data found for ID: ${widget.userId}');
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Error fetching user info: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (widget.db.connection?.isClosed == false) {
        await widget.db.connection?.close();
        print('Database connection closed');
      }
    }
  }

  Future? getInfoTransaction() async {
    try {
      if (widget.db.connection?.isClosed ?? true) {
        await widget.db.connect();
      }

      print('Fetching transaction info for user ID: ${widget.userId}');

      final results = await widget.db.executeQuery(
          'SELECT * FROM get_basic_transaction_info(@id);',
          substitutionValues: {
            'id': widget.userId,
          });

      if (results.isNotEmpty) {
        setState(() {
          if (dataTransaction.isEmpty) {
            dataTransaction = results
                .map((row) => {
                      'type_transaction': row[1],
                      'transaction_amount': row[2],
                      'category_name': row[3],
                      'icon': row[4],
                    })
                .toList();
          }
        });
      } else {
        print("No transaction data found for user ID: ${widget.userId}");
      }
      // ignore: avoid_print
      print('Transaction Data: $dataTransaction');
    } catch (e, stackTrace) {
      print('Error fetching transaction data: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (widget.db.connection?.isClosed == false) {
        await widget.db.connection?.close();
        print('Database connection closed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70.0,
        leading: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(left: 20, top: 15),
            width: 60,
            height: 60,
            child: CircleAvatar(
              radius: 30,
              child: Image.asset(
                "assets/user.png",
              ),
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
                    style: GoogleFonts.roboto(
                        textStyle: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                  Text(
                    dataUser.isNotEmpty
                        ? "${dataUser[0]['username']}"
                        : "Guest",
                    style: GoogleFonts.roboto(
                        textStyle:
                            TextStyle(fontSize: 20, color: Colors.black)),
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
                      dataUser.isNotEmpty
                          ? '\$${dataUser[0]['total_amount']}'
                          : '\$0.00', // Card number
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
                      dataUser.isNotEmpty
                          ? "${dataUser[0]['phone']}"
                          : '0000 0000 0000 0000', // Cardholder name
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
                      dataUser.isNotEmpty
                          ? "${dataUser[0]['expiration_date']}"
                          : '0000 0000 0000 0000', // Expiration date
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
                      dataUser.isNotEmpty
                          ? "${dataUser[0]['cvv']}"
                          : '000', // Expiration date, // CVV
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
            // Action Buttons
            Padding(
              padding:
                  const EdgeInsets.only(top: 20.0, left: 80.0, right: 80.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      try {
                        Navigator.pushReplacementNamed(context, '/sent');
                      } catch (e) {
                        // ignore: avoid_print
                        print(
                            'Error sign in -  Navigator.pushNamed(context, /sent): $e');
                      }
                    },
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Sent'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.attach_money),
                    label: Text('Loan'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add),
                    label: Text('Money Limit'),
                  ),
                ],
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
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Text(
                      'Sell All',
                      style: GoogleFonts.roboto(
                        textStyle:
                            TextStyle(fontSize: 16, color: Color(0xFF0066FF)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Transactions List
            Expanded(
              // ignore: unnecessary_null_comparison
              child: dataTransaction.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: dataTransaction.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0, left: 20.0),
                          child: Row(
                            children: [
                              // display category name
                              Text(
                                '${dataTransaction[index]['icon']}',
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                      fontSize: 40, color: Colors.black),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, left: 10.0),
                                  child: Row(
                                    children: [
                                      dataTransaction.isNotEmpty
                                          ? Text(
                                              '${dataTransaction[index]['category_name']}',
                                              style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.black),
                                              ),
                                            )
                                          : Text(
                                              "No Data",
                                              style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.red),
                                              ),
                                            ),
                                    ],
                                  )),
                              Spacer(),
                              // 0: income, 1: expense
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    dataTransaction[index]
                                                ['type_transaction'] ==
                                            0
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                right: 20.0, left: 2.0),
                                            child: Text(
                                              '\$${dataTransaction[index]['transaction_amount']}',
                                              style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                                  fontSize: 18,
                                                  color: dataTransaction[0][
                                                              'type_transaction'] ==
                                                          0
                                                      ? Colors.black
                                                      : Color(0xFF0066FF),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                                right: 20.0, left: 2.0),
                                            child: Text(
                                              '-\$${dataTransaction[index]['transaction_amount']}',
                                              style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                                  fontSize: 18,
                                                  color: dataTransaction[index][
                                                              'type_transaction'] ==
                                                          0
                                                      ? Colors.black
                                                      : Color(0xFF0066FF),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        "No Data",
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap, // Gán sự kiện click
          borderRadius: BorderRadius.circular(50), // Bo góc khi click
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
