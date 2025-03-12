import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:intl/intl.dart';

class SavingsDepositScreen extends StatefulWidget {
  final int userId;
  final double currentBalance;

  const SavingsDepositScreen({
    Key? key,
    required this.userId,
    required this.currentBalance,
  }) : super(key: key);

  @override
  State<SavingsDepositScreen> createState() => _SavingsDepositScreenState();
}

class _SavingsDepositScreenState extends State<SavingsDepositScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuccessMessage = false;

  // Selected term and interest rate
  int _selectedTermMonths = 3;
  double _interestRate = 4.5;

  // Available terms and their interest rates
  final Map<int, double> _termsAndRates = {
    3: 4.5, // 3 months - 4.5%
    6: 5.2, // 6 months - 5.2%
    12: 6.0, // 12 months - 6.0%
    24: 6.8, // 24 months - 6.8%
    36: 7.5, // 36 months - 7.5%
  };

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _notificationAnimation;

  @override
  void initState() {
    super.initState();

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

    _notificationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showNotification(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _createSavingsDeposit() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    // Validate form
    if (_formKey.currentState!.validate()) {
      // Parse amount
      double amount;
      try {
        amount = double.parse(_amountController.text.replaceAll(',', ''));
      } catch (e) {
        setState(() {
          _errorMessage = 'Số tiền không hợp lệ';
        });
        _showNotification('Số tiền không hợp lệ', true);
        return;
      }

      // Check if amount is greater than current balance
      if (amount > widget.currentBalance) {
        setState(() {
          _errorMessage = 'Số dư không đủ để thực hiện giao dịch này';
        });
        _showNotification('Số dư không đủ để thực hiện giao dịch này', true);
        return;
      }

      // Show loading state
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseConnection().connect();

        // 1. Create a savings account record
        final savingsResult = await DatabaseConnection().executeQuery(
          '''
          INSERT INTO savings_accounts 
          (user_id, amount, interest_rate, term_months, start_date, end_date, description, status)
          VALUES 
          (@user_id, @amount, @interest_rate, @term_months, CURRENT_TIMESTAMP, 
           CURRENT_TIMESTAMP + INTERVAL '@term_months months', @description, 'active')
          RETURNING id
          ''',
          substitutionValues: {
            'user_id': widget.userId,
            'amount': amount,
            'interest_rate': _interestRate,
            'term_months': _selectedTermMonths,
            'description': _descriptionController.text,
          },
        );

        final savingsId = savingsResult[0][0];

        // 2. Create a transaction record for the deposit
        await DatabaseConnection().executeQuery(
          '''
          INSERT INTO transactions 
          (type_transaction, transaction_hash, sender_id, sender_name, amount, 
           messages, timestamp, category_id, card_id)
          VALUES 
          (1, @transaction_hash, @sender_id, 'Savings Deposit', @amount, 
           @messages, CURRENT_TIMESTAMP, 
           (SELECT id FROM categories WHERE category_name = 'Savings' LIMIT 1), 
           (SELECT card_id FROM accounts WHERE id = @user_id LIMIT 1))
          ''',
          substitutionValues: {
            'transaction_hash': 'SAV${DateTime.now().millisecondsSinceEpoch}',
            'sender_id': widget.userId.toString(),
            'amount': amount,
            'messages':
                'Tiền gửi tiết kiệm: ${_selectedTermMonths} tháng với lãi suất ${_interestRate}%',
            'user_id': widget.userId,
          },
        );

        // 3. Update user's balance
        await DatabaseConnection().executeQuery(
          '''
          UPDATE accounts 
          SET balance = balance - @amount
          WHERE id = @user_id
          ''',
          substitutionValues: {
            'amount': amount,
            'user_id': widget.userId,
          },
        );

        // Show success message
        setState(() {
          _showSuccessMessage = true;
          _isLoading = false;

          // Reset form
          _amountController.clear();
          _descriptionController.clear();

          // Reset animation to show success message with animation
          _animationController.reset();
          _animationController.forward();
        });

        _showNotification("Gửi tiền tiết kiệm thành công!", false);
      } catch (e) {
        setState(() {
          _errorMessage = "Lỗi cơ sở dữ liệu: $e";
          _isLoading = false;
        });
        _showNotification("Lỗi cơ sở dữ liệu: $e", true);
      }
    }
  }

  // Calculate the maturity amount based on principal, interest rate and term
  double _calculateMaturityAmount() {
    if (_amountController.text.isEmpty) return 0;

    double principal;
    try {
      principal = double.parse(_amountController.text.replaceAll(',', ''));
    } catch (e) {
      return 0;
    }

    // Simple interest calculation: P(1 + rt) where r is annual rate and t is time in years
    double rateDecimal = _interestRate / 100;
    double timeInYears = _selectedTermMonths / 12;

    return principal * (1 + rateDecimal * timeInYears);
  }

  // Format currency
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maturity amount
    final maturityAmount = _calculateMaturityAmount();
    final interestEarned = maturityAmount -
        (double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: const Color(0xFF4B5B98),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gửi tiền tiết kiệm',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Savings Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B5B98).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            color: Color(0xFF4B5B98),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Center(
                        child: Text(
                          'Gửi tiền tiết kiệm để tăng trưởng tài sản của bạn',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Success Message
                      if (_showSuccessMessage) ...[
                        ScaleTransition(
                          scale: _notificationAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thành công!',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tiền gửi tiết kiệm của bạn đã được tạo thành công.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showSuccessMessage = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Savings Form
                      Container(
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
                            // Error Message
                            if (_errorMessage != null) ...[
                              ScaleTransition(
                                scale: _notificationAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red[700],
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Lỗi!',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _errorMessage!,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.red[700],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _errorMessage = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Amount Field
                            Text(
                              'Số tiền gửi',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số tiền';
                                }
                                try {
                                  final amount =
                                      double.parse(value.replaceAll(',', ''));
                                  if (amount <= 0) {
                                    return 'Số tiền phải lớn hơn 0';
                                  }
                                  if (amount > widget.currentBalance) {
                                    return 'Số dư không đủ';
                                  }
                                } catch (e) {
                                  return 'Số tiền không hợp lệ';
                                }
                                return null;
                              },
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.attach_money_rounded,
                                  color: Color(0xFF4B5B98),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4B5B98)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.red[400]!),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '0.00',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Số dư hiện tại: ${_formatCurrency(widget.currentBalance)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Term Selection
                            Text(
                              'Kỳ hạn',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Term Chips
                            Wrap(
                              spacing: 8,
                              children: _termsAndRates.keys.map((months) {
                                final isSelected =
                                    _selectedTermMonths == months;
                                return ChoiceChip(
                                  label: Text(
                                    '$months tháng',
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedTermMonths = months;
                                        _interestRate = _termsAndRates[months]!;
                                      });
                                    }
                                  },
                                  backgroundColor: Colors.grey[100],
                                  selectedColor: const Color(0xFF4B5B98),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Interest Rate Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4B5B98).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFF4B5B98).withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Lãi suất:',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${_interestRate.toStringAsFixed(1)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4B5B98),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Description Field
                            Text(
                              'Mô tả (tùy chọn)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF4B5B98),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF4B5B98)),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Nhập mô tả cho khoản tiết kiệm này',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Maturity Summary
                      if (_amountController.text.isNotEmpty &&
                          double.tryParse(
                                  _amountController.text.replaceAll(',', '')) !=
                              null)
                        Container(
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
                              Text(
                                'Tóm tắt khoản tiết kiệm',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                'Số tiền gốc:',
                                _formatCurrency(double.tryParse(
                                        _amountController.text
                                            .replaceAll(',', '')) ??
                                    0),
                              ),
                              _buildSummaryRow(
                                'Lãi suất:',
                                '${_interestRate.toStringAsFixed(1)}% / năm',
                              ),
                              _buildSummaryRow(
                                'Kỳ hạn:',
                                '$_selectedTermMonths tháng',
                              ),
                              _buildSummaryRow(
                                'Tiền lãi dự kiến:',
                                _formatCurrency(interestEarned),
                                isHighlighted: true,
                              ),
                              _buildSummaryRow(
                                'Tổng tiền nhận được:',
                                _formatCurrency(maturityAmount),
                                isHighlighted: true,
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ngày đáo hạn: ${DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: _selectedTermMonths * 30)))}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createSavingsDeposit,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  'Gửi tiền tiết kiệm',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF4B5B98) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
