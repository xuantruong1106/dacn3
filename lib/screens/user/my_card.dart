import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dacn3/connect/blockchain_service.dart';

class MyCardsScreen extends StatefulWidget {
  final int userId;
  const MyCardsScreen({super.key, required this.userId});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 4600;
  late List<Map<String, dynamic>> dataUser;
  late List<Map<String, dynamic>> dataTransaction;
  bool _isLoading = true;
  final blockchainService =  BlockchainService();
  late final BigInt walletBalanceAfter;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    dataUser = [];
    dataTransaction = [];

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

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await getInfoUser();
      await getInfoTransaction();
      walletBalanceAfter = await blockchainService.checkWalletBalance(dataUser[0]['card_number']);
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getInfoUser() async {
    try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_user_and_card_info(@id);',
        substitutionValues: {'id': widget.userId},
      );

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
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load card information');
    }
  }

  Future<void> getInfoTransaction() async {
    try {
      await DatabaseConnection().connect();
      final results = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_basic_transaction_info(@id);',
        substitutionValues: {'id': widget.userId},
      );

      setState(() {
        dataTransaction = results
            .map((row) => {
                  'type_transaction': row[1],
                  'transaction_amount': row[2],
                  'category_name': row[3],
                  'icon': row[4],
                })
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load transaction data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_rounded),
        //   color: const Color(0xFF4B5B98),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          'My Cards',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: const Color(0xFF4B5B98),
            onPressed: () {
              // Add new card functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4B5B98),
              ),
            )
          : SafeArea(
              child: FadeTransition(
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
                          // Card Section
                          _buildCard(),

                          const SizedBox(height: 32),

                          // Monthly Spending Limit
                          _buildSpendingLimit(),

                          const SizedBox(height: 32),

                          // Recent Transactions
                          _buildTransactionsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard() {
    return Container(
      // Remove fixed height to allow dynamic sizing
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B5B98), Color(0xFF341969)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B5B98).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: CardPatternPainter(),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(20), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Allow column to shrink
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 28, // Smaller icon
                    ),
                    const Icon(
                      Icons.contactless_rounded,
                      color: Colors.white,
                      size: 24, // Smaller icon
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  dataUser.isNotEmpty
                      ? '\$$walletBalanceAfter'
                      : '\$0.00',
                  style: GoogleFonts.inter(
                    fontSize: 24, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dataUser.isNotEmpty
                      ? "${widget.userId}"
                      : '•••• •••• •••• ••••',
                  style: GoogleFonts.inter(
                    fontSize: 14, // Smaller font
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12), // Reduced spacing
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expires',
                          style: GoogleFonts.inter(
                            fontSize: 11, // Smaller font
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          dataUser.isNotEmpty
                              ? dataUser[0]['expiration_date']
                              : 'MM/YY',
                          style: GoogleFonts.inter(
                            fontSize: 13, // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30), // Reduced spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: GoogleFonts.inter(
                            fontSize: 11, // Smaller font
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          dataUser.isNotEmpty ? dataUser[0]['cvv'] : '•••',
                          style: GoogleFonts.inter(
                            fontSize: 13, // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      "assets/mastercard.svg",
                      width: 50, // Smaller logo
                      height: 35,
                      placeholderBuilder: (context) => const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24, // Smaller error icon
                      ),
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

  Widget _buildSpendingLimit() {
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
                'Monthly Spending Limit',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B5B98).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${_sliderValue.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5B98),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4B5B98),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF4B5B98).withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              trackHeight: 6,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$10,000',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5B98),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        dataTransaction.isNotEmpty
            ? Column(
                children: List.generate(
                  dataTransaction.length > 5 ? 5 : dataTransaction.length,
                  (index) => _buildTransactionItem(
                    icon: dataTransaction[index]['icon'],
                    category: dataTransaction[index]['category_name'],
                    amount: dataTransaction[index]['transaction_amount'],
                    isExpense: dataTransaction[index]['type_transaction'] == 1,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String icon,
    required String category,
    required String amount,
    required bool isExpense,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isExpense ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            isExpense ? '-\$$amount' : '+\$$amount',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isExpense ? Colors.red[600] : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for card background pattern
class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.7, 0);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.8,
      size.width,
      size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
