import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/random_cvv_card_numbrer/utils.dart';

class RequestMoneyScreen extends StatefulWidget {
  final int userId;
  final String username;
  const RequestMoneyScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen>
    with SingleTickerProviderStateMixin {
  final _receiverAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  late List<Map<String, dynamic>> dataUser;
  late String receiverName = '';
  late List<Map<String, dynamic>> _categories;
  String? _selectedCategory;
  int? _selectedCategoryId;
  String? _error;
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
    _categories = [];

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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        getCardInfo(),
        getCategories(),
      ]);
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _receiverAddressController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getCategories() async {
    try {
      final result = await DatabaseConnection().executeQuery(
        'SELECT id, name_category FROM categories WHERE type_category = 0',
      );

      setState(() {
        _categories = result
            .map<Map<String, dynamic>>((e) => {
                  'id': e[0],
                  'name': e[1].toString(),
                })
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load categories');
    }
  }

  Future<void> getCardInfo() async {
    try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_cards_by_account(@id);',
        substitutionValues: {'id': widget.userId},
      );

      if (results.isNotEmpty) {
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
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load card information');
    }
  }

  Future<void> getReceiverAddress(int receiverAddress) async {
    try {
      setState(() => _isProcessing = true);
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

  Future<void> checkBalance(double amount) async {
    try {
      setState(() => _isProcessing = true);
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM check_balance(@id, @amount);',
        substitutionValues: {
          'id': widget.userId,
          'amount': amount,
        },
      );

      if (results.isNotEmpty && results[0][0] == false) {
        _showInsufficientFundsDialog();
      } else {
        await sendMoney(amount);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to check balance');
    } finally {
      setState(() => _isProcessing = false);
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

  Future<void> sendMoney(double amount) async {
    try {
      await DatabaseConnection().connect();

      // Sửa lỗi: Thay thế ReceiverName bằng receiverName và _mess bằng _messageController
      final sanitizedReceiverName = receiverName.replaceAll("'", "''");
      final sanitizedMessage = _messageController.text.isNotEmpty
          ? _messageController.text.replaceAll("'", "''")
          : "No message";

      final int? receiverAddressInt =
          int.tryParse(_receiverAddressController.text);

      if (receiverAddressInt == null ||
          _selectedCategoryId == null ||
          dataUser.isEmpty) {
        _showErrorSnackBar('Missing required information for transaction');
        return;
      }

      // Sử dụng SQL parameters thay vì truyền giá trị trực tiếp vào query
      final results = await DatabaseConnection().executeQuery(
        'SELECT insert_transaction(@1, @2, @3, @4, @5, @6, @7, @8, @9, @10);',
        substitutionValues: {
          '1': 0,
          '2': generateRandomhash().toString(),
          '3': receiverAddressInt,
          '4': sanitizedReceiverName,
          '5': widget.userId,
          '6': widget.username.replaceAll("'", "''"),
          '7': amount,
          '8': sanitizedMessage,
          '9': _selectedCategoryId,
          '10': dataUser[0]['id'],
        },
      );

      if (results.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/main',
            arguments: widget.userId);
      }
    } catch (e) {
      print('sendMoney-error: $e');
      _showErrorSnackBar('Transaction failed: ${e.toString()}');
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
                          // Form Fields
                          _buildFormSection(),

                          const SizedBox(height: 32),

                          // Amount Input
                          _buildAmountSection(),

                          const SizedBox(height: 32),

                          // Error Message
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          // Send Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      double? amount = double.tryParse(
                                          _amountController.text);
                                      if (amount != null) {
                                        setState(() => _error = null);
                                        checkBalance(amount);
                                      } else {
                                        setState(() {
                                          _error =
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

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
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
            controller: _messageController,
            icon: Icons.message_rounded,
            hintText: 'Add a message (optional)',
          ),
          const SizedBox(height: 24),
          _buildCategoryDropdown(),
        ],
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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
          items: _categories.map((category) {
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
              _selectedCategoryId = _categories.firstWhere(
                (element) => element['name'] == newValue,
                orElse: () => {'id': null, 'name': ''},
              )['id'];
            });
          },
        ),
      ],
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
            controller: _amountController,
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
}
