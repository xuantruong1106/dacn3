import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;
  const StatisticsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, double> categoryPercentages = {};
  Map<String, Color> categoryColors = {};
  double? totalAmount;
  String highestCategory = "";
  double highestPercentage = 0.0;
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Color> defaultColors = [
    const Color(0xFF4B5B98), // Primary blue
    const Color(0xFFFF6B6B), // Coral red
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF009688), // Teal
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFFEB3B), // Yellow
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    fetchTransactionData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(0, month));
  }

  Future<void> fetchTransactionData() async {
    try {
      await DatabaseConnection().connect();

      print('User ID type: ${widget.userId}');

      final transactions = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_transactions_in_current_month(@id);',
        substitutionValues: {'id': widget.userId},
      );

      final categories = await DatabaseConnection().executeQuery(
        'SELECT * FROM get_all_categories();',
      );

      print(transactions);
      print(categories);

      Map<String, int> categoryCounts = {};
      int totalTransactions = 0;

      // Initialize categories with zero transactions
      List<Color> generatedColors = [];
      for (int i = 0; i < categories.length; i++) {
        categoryCounts[categories[i][1]] = 0;
        generatedColors.add(defaultColors[i % defaultColors.length]);
      }

      // Map categories to colors
      Map<String, Color> colorMapping = {};
      for (int i = 0; i < categories.length; i++) {
        colorMapping[categories[i][1]] = generatedColors[i];
      }

      // Update transaction counts for categories
      for (var transaction in transactions) {
        String category = transaction[2];
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        totalTransactions++;
      }

      // Calculate percentages
      Map<String, double> percentages = {};
      String maxCategory = "";
      double maxPercentage = 0.0;

      categoryCounts.forEach((category, count) {
        double percentage =
            totalTransactions > 0 ? (count / totalTransactions) * 100 : 0;
        percentages[category] = percentage;

        if (percentage > maxPercentage) {
          maxPercentage = percentage;
          maxCategory = category;
        }
      });

      setState(() {
        categoryPercentages = percentages;
        highestCategory = maxCategory;
        highestPercentage = maxPercentage;
        categoryColors = colorMapping;
        totalAmount = transactions.isNotEmpty
            ? double.tryParse(transactions[0][3].toString())
            : 0.0;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load statistics');
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
        title: Text(
          'Statistics',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: const Color(0xFF4B5B98),
            onPressed: () {},
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Balance Card
                      _buildBalanceCard(),

                      const SizedBox(height: 32),

                      // Chart Section
                      _buildChartSection(),

                      const SizedBox(height: 32),

                      // Categories Section
                      _buildCategoriesSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Text(
              'Statistics for ${_getMonthName(_selectedMonth)} $_selectedYear',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${totalAmount?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(30),
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
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 70,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${highestPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: categoryColors[highestCategory],
                        ),
                      ),
                      Text(
                        highestCategory,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
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
          Text(
            'Categories',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryPercentages.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColors[entry.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    return categoryPercentages.entries.map((entry) {
      final isMajorSection = entry.key == highestCategory;
      return PieChartSectionData(
        color: categoryColors[entry.key]!.withOpacity(isMajorSection ? 1 : 0.7),
        value: entry.value,
        title: '',
        radius: isMajorSection ? 60 : 50,
        titleStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
