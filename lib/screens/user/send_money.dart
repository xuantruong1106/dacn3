import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';

class SendMoneyScreen extends StatefulWidget {
  final int userId;
  const SendMoneyScreen({super.key, required this.userId});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> dataUser;
  bool _isLoading = true;
  final _amountController = TextEditingController();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _contacts = [
    {'name': 'Yamilet', 'selected': false},
    {'name': 'Alexa', 'selected': false},
    {'name': 'Yakub', 'selected': false},
    {'name': 'Krishna', 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    dataUser = [];

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
      await getCardInfo();
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
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

      await DatabaseConnection().close();
    } catch (e) {
      _showErrorSnackBar('Failed to load card information');
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
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Section
                        _buildCard(),

                        const SizedBox(height: 32),

                        // Send to Section
                        Text(
                          'Send to',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Add New Contact
                              _buildContactItem(
                                isAdd: true,
                                onTap: () {
                                  // Handle add new contact
                                },
                              ),
                              const SizedBox(width: 16),
                              // Contact List
                              ..._contacts.map((contact) => Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: _buildContactItem(
                                      name: contact['name'],
                                      isSelected: contact['selected'],
                                      onTap: () {
                                        setState(() {
                                          for (var c in _contacts) {
                                            c['selected'] =
                                                c['name'] == contact['name'];
                                          }
                                        });
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Amount Input Section
                        _buildAmountInput(),

                        const Spacer(),

                        // Send Button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/requestmoney');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B5B98),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFF4B5B98).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
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
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      height: 180,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.currency_exchange_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ETH',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  dataUser.isNotEmpty
                      ? '${dataUser[0]['total_amount']} ETH'
                      : '0.00 ETH',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dataUser.isNotEmpty
                      ? 'Card ${dataUser[0]['card_number'].toString().substring(0, 4)}••••'
                      : 'No card available',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    String? name,
    bool isAdd = false,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isAdd
                  ? Colors.white
                  : isSelected
                      ? const Color(0xFF4B5B98)
                      : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isAdd
                    ? const Color(0xFF4B5B98)
                    : isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isAdd
                  ? const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF4B5B98),
                      size: 32,
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: const AssetImage('assets/user.png'),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAdd ? 'Add New' : name!,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF4B5B98) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
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
                'Enter Amount',
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
            keyboardType: TextInputType.number,
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
              prefixText: 'ETH ',
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
