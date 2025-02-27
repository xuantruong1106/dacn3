import 'package:dacn3/connect/database_connect.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  final int userId;

  const StatisticsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, double> categoryPercentages = {};
  Map<String, Color> categoryColors = {};
  late double mount;
  String highestCategory = "";
  double highestPercentage = 0.0;
  List<Color> defaultColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.yellow
  ];

  @override
  void initState() {
    super.initState();
    fetchTransactionData();
  }

  Future<void> fetchTransactionData() async {
    await DatabaseConnection().connect();

    final transactions = await DatabaseConnection().executeQuery(
      'SELECT * FROM get_transactions_in_current_month(@id);',
      substitutionValues: {'id': widget.userId},
    );

    final categories = await DatabaseConnection().executeQuery(
      'SELECT * FROM get_all_categories();',
    );

    Map<String, int> categoryCounts = {};
    int totalTransactions = 0;

    // Khởi tạo danh sách danh mục với số lượng giao dịch bằng 0
    List<Color> generatedColors = [];
    for (int i = 0; i < categories.length; i++) {
      categoryCounts[categories[i][1]] = 0;
      generatedColors
          .add(defaultColors[i % defaultColors.length]); // Gán màu tuần hoàn
    }

    // Ánh xạ danh mục với màu sắc
    Map<String, Color> colorMapping = {};
    for (int i = 0; i < categories.length; i++) {
      colorMapping[categories[i][1]] = generatedColors[i];
    }

    // Cập nhật số lượng giao dịch cho danh mục có giao dịch
    for (var transaction in transactions) {
      String category = transaction[2];
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      totalTransactions++;
    }

    // Tính phần trăm số giao dịch cho từng danh mục
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
      mount = double.tryParse(transactions[0][3])!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.arrow_back, () {
                    Navigator.pop(context);
                  }),
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildIconButton(Icons.notifications_none, () {}),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '\$$mount',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Biểu đồ tròn
            if (categoryPercentages.isNotEmpty)
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.blue, // Màu cho tiến trình
                            value: highestPercentage, // Giá trị phần trăm chính
                            radius: 10, // Làm mỏng vòng tròn
                            showTitle:
                                false, // Không hiển thị số % trên đường viền
                          ),
                          PieChartSectionData(
                            color: Colors.grey[
                                200], // Màu nền mờ cho phần chưa hoàn thành
                            value: 100 -
                                highestPercentage, // Phần còn lại của vòng tròn
                            radius: 10,
                            showTitle: false,
                          ),
                        ],
                        sectionsSpace: 0, // Không có khoảng trống giữa các phần
                        centerSpaceRadius:
                            70, // Khoảng trống ở giữa để giống Progress Indicator
                        borderData: FlBorderData(show: false), // Không có viền
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${highestPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          highestCategory,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),

            const SizedBox(height: 20),

            // Danh sách danh mục hiển thị toàn bộ dưới biểu đồ
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryColors.keys.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: categoryColors[category]!,
                            radius: 10,
                          ),
                          SizedBox(height: 4),
                          Text(category, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    List<PieChartSectionData> sections = [];
    categoryPercentages.forEach((category, percentage) {
      if (percentage > 0) {
        sections.add(
          PieChartSectionData(
            color: categoryColors[category]!,
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      }
    });
    return sections;
  }
}
