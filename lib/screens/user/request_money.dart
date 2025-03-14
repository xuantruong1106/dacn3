// ignore_for_file: avoid_print, use_build_context_synchronously, unnecessary_brace_in_string_interps, no_leading_underscores_for_local_identifiers, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/connect/blockchain_service.dart';
import 'package:dacn3/random_cvv_card_numbrer/utils.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestMoneyScreen extends StatefulWidget {
  final int userId;
  final String username;
  RequestMoneyScreen({super.key, required this.userId, required this.username});
  // final db = DatabaseConnection();
  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen>
    with SingleTickerProviderStateMixin {
  final _receiverAddressController = TextEditingController();
  final _mount = TextEditingController();
  final _mess = TextEditingController();

  final blockchainService = BlockchainService();
  late List<Map<String, dynamic>> dataUser;
  late String receiverName = '';
  late String recipientAddress = '';
  late List<Map<String, dynamic>> _category;
  String? _selectedCategory;
  int? _selectedCategoryId;
  String? error = '';
  bool _isLoading = false;
  bool _isProcessing = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    dataUser = [];
    _category = [];

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _loadInitialData();
  }

  @override
  void dispose() {
    _receiverAddressController.dispose();
    _mount.dispose();
    _mess.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([getCardInfo(), getCategory()]);
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  Future<void> getCategory() async {
    try {
      final result = await DatabaseConnection().executeQuery('''
        SELECT id, name_category 
        FROM categories
        where type_category = 0''');

      print('getCategory: $result');

      setState(() {
        _category = result
            .map<Map<String, dynamic>>((e) => {
                  'id': e[0], // ID của category
                  'name': e[1].toString(), // Tên của category
                })
            .toList();
      });

      print('getCategory: $_category');

      // await DatabaseConnection().close();
    } catch (e) {
      print('getCategory-error: $e');
      _showErrorSnackBar('Failed to load categories');
    }
  }

  Future<void> getCardInfo() async {
    try {
      print('getCardInfo: ${widget.userId}');
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
          'SELECT * FROM get_cards_by_account(@id);',
          substitutionValues: {
            'id': widget.userId,
          });

      if (results.isEmpty) {
        print('result empty');
        return;
      }

      setState(() {
        dataUser = results
            .map((row) => {
                  'id': row[0],
                  'card_number': row[1],
                  'private_key': row[2],
                  'total_amount': row[3],
                })
            .toList();
      });
    } catch (e) {
      print('getCardInfo-error: $e');
      _showErrorSnackBar('Failed to load card information');
    }
  }

  Future<void> getReceiverAddress(int receiverAddress) async {
    try {
      setState(() => _isProcessing = true);
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
          'SELECT * FROM get_receivername(@address);',
          substitutionValues: {
            'address': receiverAddress,
          });

      if (results.isEmpty) {
        print('result empty');
      }

      print(results[0][0]);
      setState(() {
        receiverName = results.isNotEmpty ? results[0][0] as String : '';
        recipientAddress = results.isNotEmpty ? results[0][1] as String : '';
      });
    } catch (e) {
      print('getReceiverAddress-error: $e');
      _showErrorSnackBar('Failed to find receiver');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> checkBalance(int id, double mount) async {
    try {
      setState(() => _isProcessing = true);
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
          'SELECT * FROM check_balance(@id, @mount);',
          substitutionValues: {'id': widget.userId, 'mount': mount});

      if (results.isNotEmpty && results[0][0] == false) {
        _showInsufficientFundsDialog();
      } else {
        // Thực hành giao dịch
        print('checkBalance(): $mount');
        sendMoney(mount);
      }
    } catch (e) {
      print('getReceiverAddress-error: $e');
      _showErrorSnackBar('Failed to check balance');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> sendMoney(double _mount2) async {
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

      if (results.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/main',
            arguments: widget.userId);
      }
    } catch (e) {
      print('sendMoney-error: $e');
      _showErrorSnackBar('Transaction failed: ${e.toString()}');
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Insufficient Funds',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You don\'t have enough balance to complete this transaction.',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: const Color(0xFF4B5B98),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4B5B98),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),

                            // Form Fields
                            _buildFormSection(),

                            const SizedBox(height: 32),

                            _buildAmountSection(),

                            const SizedBox(height: 20),

                            // Error Message
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  error!,
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // Error Message
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  error!,
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            // Send Money Button
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        double? amount =
                                            double.tryParse(_mount.text);
                                        if (amount != null) {
                                          setState(() => error = null);
                                          checkBalance(widget.userId, amount);
                                        } else {
                                          setState(() {
                                            error =
                                                'Please enter a valid amount';
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B5B98),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  elevation: 8,
                                  shadowColor:
                                      const Color(0xFF4B5B98).withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        'Send Money',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )),
                )),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    IconData? icon,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          keyboardType: keyboardType,
          onFieldSubmitted: onSubmitted,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: const Color(0xFF4B5B98)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4B5B98)),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            label: 'Receiver Address',
            controller: _receiverAddressController,
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                getReceiverAddress(int.tryParse(value) ?? 0);
              }
            },
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Receiver Name',
            initialValue: receiverName,
            icon: Icons.badge_rounded,
            enabled: false,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Message',
            controller: _mess,
            icon: Icons.message_rounded,
            hintText: 'Add a message (optional)',
          ),
          const SizedBox(height: 24),
          _buildCategoryDropdown(),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.currency_exchange_rounded,
                  size: 18,
                ),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5B98),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
              prefixText: 'USD ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.category_rounded, color: Color(0xFF4B5B98)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4B5B98)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _category.map((category) {
            return DropdownMenuItem<String>(
              value: category['name'],
              child: Text(
                category['name'],
                style: GoogleFonts.inter(),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
              _selectedCategoryId = _category.firstWhere(
                (element) => element['name'] == newValue,
                orElse: () => {'id': null, 'name': ''},
              )['id'];
            });
          },
        ),
      ],
    );
  }
}
