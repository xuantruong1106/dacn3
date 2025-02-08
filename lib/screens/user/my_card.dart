import 'package:flutter/material.dart';
import 'package:dacn3/database_connect.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyCardsScreen extends StatefulWidget {
  final int userId;
  MyCardsScreen({super.key, required this.userId});

  final db = DatabaseConnection();
  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  double _sliderValue = 4600;
  late List<Map<String, dynamic>> dataUser;
   @override
  void initState() {
    super.initState();
    dataUser = [];
    getInfoUser();
  }

    Future<void> getInfoUser() async {
    try {
      await widget.db.connect();
      final results = await widget.db.executeQuery(
          'SELECT * FROM get_user_and_card_info(@id);',
          substitutionValues: {
            'id': widget.userId,
          });

      setState(() {
        dataUser = results
            .map((row) => {
                  'username': row[0],
                  'phone': row[1],
                  'address': row[2],
                  'card_number': row[3],
                  'card_holder_name': row[4],
                  'cvv': row[5],
                  'expiration_date': row[6].toString().substring(0, 10).split('-').reversed.join('/'),
                  'total_amount': row[7],
                })
            .toList();
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
    } finally {
      await widget.db.connection?.close();
      // ignore: avoid_print
      print('Connection closed for getInfoUser');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'My Cards',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Credit Card
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
                      "${dataUser[0]['expiration_date']}", // Expiration date
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
                      "${dataUser[0]['cvv']}", // CVV
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
          const SizedBox(height: 24),

          // Transactions
          ...[
            _buildTransactionItem(
              icon: Icons.apple,
              title: 'Apple Store',
              subtitle: 'Entertainment',
              amount: '-\$5.99',
            ),
            _buildTransactionItem(
              icon: Icons.music_note,
              title: 'Spotify',
              subtitle: 'Music',
              amount: '-\$12.99',
            ),
            _buildTransactionItem(
              icon: Icons.shopping_cart,
              title: 'Grocery',
              subtitle: 'Shopping',
              amount: '-\$88',
            ),
          ],
          const SizedBox(height: 24),

          // Monthly spending limit
          const Text(
            'Monthly spending limit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: \$${_sliderValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: Colors.blue,
                    // ignore: deprecated_member_use
                    overlayColor: Colors.blue.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0,
                    max: 10000,
                    onChanged: (value) {
                      setState(() {
                        _sliderValue = value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '\$0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '\$10,000',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        amount,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}