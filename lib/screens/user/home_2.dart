import 'package:dacn3/screens/user/transaction_detail.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Home extends StatefulWidget {
  final int userId;
  const Home({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> dataUser;
  late List<Map<String, dynamic>> dataTransaction;
  bool _isLoading = true;
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
    } finally {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
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
      _showErrorSnackBar('Failed to load user data');
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
                  'transaction_id': row[0],
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  child: CustomScrollView(
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.grey[50],
                        elevation: 0,
                        expandedHeight: 100,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'profile',
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: AssetImage("assets/user.png"),
                                        fit: BoxFit.cover,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        dataUser.isNotEmpty
                                            ? dataUser[0]['username']
                                            : "Guest",
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.search_rounded),
                                    onPressed: () {},
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card
                              _buildCard(),

                              const SizedBox(height: 25),

                              // Quick Actions
                              _buildQuickActions(),

                              const SizedBox(height: 25),

                              // Transactions Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            ],
                          ),
                        ),
                      ),

                      // Transactions List
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (dataTransaction.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No transactions yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final transaction = dataTransaction[index];
                            final isExpense =
                                transaction['type_transaction'] == 1;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isExpense
                                        ? Colors.red[50]
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      transaction['icon'],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  transaction['category_name'],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                trailing: Text(
                                  isExpense
                                      ? '-\$${transaction['transaction_amount']}'
                                      : '+\$${transaction['transaction_amount']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isExpense
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                ),
                                onTap: () {
                                  print(
                                      'Transaction ID: ${transaction['transaction_id']}');
                                  // Navigate to transaction detail screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionDetailScreen(
                                          transactionId: transaction[
                                                  'transaction_id'] ??
                                              0 // You'll need to add 'id' to your transaction data
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: dataTransaction.isEmpty
                              ? 1
                              : dataTransaction.length,
                        ),
                      ),

                      // Bottom Padding
                      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      // Remove fixed height to allow dynamic sizing
      constraints: const BoxConstraints(
          minHeight: 180), // Minimum height instead of fixed
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
                      size: 28, // Slightly smaller icon
                    ),
                    SvgPicture.asset(
                      "assets/mastercard.svg",
                      width: 50, // Slightly smaller logo
                      height: 35,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  dataUser.isNotEmpty
                      ? '\$${dataUser[0]['total_amount']}'
                      : '\$0.00',
                  style: GoogleFonts.inter(
                    fontSize: 24, // Slightly smaller font
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
                    fontSize: 14, // Smaller font size
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
                          dataUser.isNotEmpty ? '•••' : '•••',
                          style: GoogleFonts.inter(
                            fontSize: 13, // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.arrow_upward_rounded,
        'label': 'Send',
        'color': const Color(0xFF4B5B98),
        'onTap': () {
          Navigator.pushReplacementNamed(
            context,
            '/sent',
            arguments: {
              'userId': widget.userId,
              'username': dataUser[0]['username'],
            },
          );
        },
      },
      {
        'icon': Icons.account_balance_rounded,
        'label': 'Loan',
        'color': Colors.orange[700],
        'onTap': () {
          Navigator.pushReplacementNamed(
            context,
            '/loan',
            arguments: {
              'userId': widget.userId,
            },
          );
        },
      },
      {
        'icon': Icons.analytics_rounded,
        'label': 'Limit',
        'color': Colors.green[600],
        'onTap': () {},
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.map((action) {
        return GestureDetector(
          onTap: action['onTap'] as void Function(),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
