// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_brace_in_string_interps, no_leading_underscores_for_local_identifiers, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/connect/blockchain_service.dart';
import 'package:dacn3/random_cvv_card_numbrer/utils.dart';

class RequestMoneyScreen extends StatefulWidget {
   final int userId;
   final String username;
  RequestMoneyScreen({super.key, required this.userId,  required this.username });
  // final db = DatabaseConnection();
  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}


class _RequestMoneyScreenState extends State<RequestMoneyScreen> {

  final _receiverAddressController = TextEditingController();
  final _mount = TextEditingController();
  final _mess = TextEditingController(); 
  final blockchainService =  BlockchainService();
  late List<Map<String, dynamic>> dataUser;
  late String receiverName = '';
  late String recipientAddress = '';
  late List<Map<String, dynamic>> _category;
  String? _selectedCategory;
  int? _selectedCategoryId;
  String? error = '';
  
  @override
  void initState() {
    super.initState();
    dataUser = [];
    _category = [];
    getCardInfo();
    getCategory();
  }
 @override
  void dispose() {
    _receiverAddressController.dispose();
    _mount.dispose();
    super.dispose();
  }



Future<void> getCategory() async {
    try {

      final result = await DatabaseConnection().executeQuery(''' 
        SELECT id, name_category 
        FROM categories
        where type_category = 0''');
      
      print('getCategory: $result');

        setState(() {
          _category = result.map<Map<String, dynamic>>((e) => {
            'id': e[0], // ID của category
            'name': e[1].toString(), // Tên của category
          }).toList();
        });
      
       print('getCategory: $_category');

      // await DatabaseConnection().close();
    } catch (e){
      
      print('getCategory-error: $e');
    }
}

Future<void> getCardInfo() async{
   try {
    
      print('getCardInfo: ${widget.userId}');
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_cards_by_account(@id);',
      substitutionValues: {
            'id': widget.userId,
      });

      if(results.isEmpty){
        
        print('result empty');
        return;
      }

      setState(() { 
        dataUser = results.map((row) => {
          'id': row[0],
          'card_number': row[1],
          'private_key': row[2],
          'total_amount': row[3],
        }).toList();
      });
  } catch(e)
  {
    
    print('getCardInfo-error: $e');
  }
}

Future<void> getReceiverAddress(int receiverAddress) async {
    try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_receivername(@address);',
        substitutionValues: {'address': receiverAddress},
      );

      setState(() {
        receiverName = results.isNotEmpty ? results[0][0] as String : '';
      });
    } catch (e) {
      _showErrorSnackBar('Failed to find receiver');
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

Future<void> checkBalance(int id, double mount) async{
  try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM check_balance(@id, @mount);',
        substitutionValues: {
          'id': widget.userId,
          'mount': mount
    });

     if (results.isNotEmpty && results[0][0] == false) {
    // Hiển thị cảnh báo số dư không đủ
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cảnh báo'),
          content: const Text('Số dư không đủ để thực hiện giao dịch.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    // Thực hành giao dịch
    print('checkBalance(): $mount');
    sendMoney(mount);
  }
  } catch (e) {
    print('getReceiverAddress-error: $e');
  }
}

Future<void> sendMoney(double _mount2) async{
      try {
          
          await BlockchainService().checkBeforeTransfer(recipientAddress, _mount2);  
          print('request money checkBeforeTransfer: done ');

          await DatabaseConnection().connect();

          final results = await DatabaseConnection().executeQuery('''
              SELECT insert_transaction(
                ${0}, 
                '${generateRandomhash().toString()}', 
                ${int.tryParse(_receiverAddressController.text)}, 
                '${receiverName.replaceAll("'", "''")}', 
                ${widget.userId}, 
                '${widget.username.replaceAll("'", "''")}', 
                ${_mount2}, 
                '${_mess.text.isNotEmpty ? _mess.text.replaceAll("'", "''") : "No message"}', 
                ${_selectedCategoryId}, 
                ${dataUser[0]['id']}
              );
          ''');

          if(results.isNotEmpty){
             Navigator.pushReplacementNamed(context, '/main',  arguments: widget.userId);
          }
    } catch (e) {
      print('sendMoney-error: $e');
    }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFF4B5B98),
          onPressed: () => Navigator.pushReplacementNamed(context, '/main',
              arguments: widget.userId),
        ),
        title: Text(
          'Send Money',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Center(
                    child: const Text(
                      'Request Money',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Form Fields
                const Text(
                  'Receiver Address',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              TextField(
                controller: _receiverAddressController,
                decoration: InputDecoration(
                  hintText: '1228',
                  prefixIcon:
                      Icon(Icons.person_outline, color: Colors.grey[400]),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                 keyboardType: TextInputType.number, // Giới hạn nhập số
                  onSubmitted: (_receiverAddressController) {
                    getReceiverAddress(int.tryParse(_receiverAddressController) ?? 0); // Gọi hàm khi nhấn Enter
                  },
              ),
              const SizedBox(height: 24),

              const Text(
                'Receiver Name',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: '$receiverName',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Content',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              TextField(
                controller: _mess,
                decoration: InputDecoration(
                  hintText: 'Tanya Myroniuk',
                  prefixIcon:
                      Icon(Icons.title, color: Colors.grey[400]),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),


              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder( borderSide: BorderSide(color: Colors.white),),
                      prefixIcon: Icon(Icons.title, color: Colors.grey[400]),
                    ),
                    dropdownColor: Colors.white,
                    items: _category.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _selectedCategoryId = _category.firstWhere(
                          (element) => element['name'] == newValue)['id'];
                      });
                      print('Selected ID: $_selectedCategoryId');
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),

        

              // Amount Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter Your Amount',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                          },
                          child: const Text(
                            'Change Currency?',
                            style: TextStyle(
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'USD',
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _mount,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                (error ?? '').isNotEmpty ? error! : ' ',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),

              const Spacer(),

              // Send Money Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                      double? amount = double.tryParse(_mount.text);
                      if (amount != null) {
                        setState(() {
                          error = ' ';
                        });
                        checkBalance(widget.userId, amount);
                      } else {
                        setState(() {
                          error = 'Please enter a valid amount.';
                        });
                      } 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Send Money',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
