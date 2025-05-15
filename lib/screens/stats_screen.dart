import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/account.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

// Define the BarData class outside of the _StatsScreenState class
class BarData {
  final String date;
  final double income;
  final double expense;

  BarData(this.date, this.income, this.expense);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<ExpenseTransaction> allTransactions = [];
  List<Account> _accounts = [];
  bool _isLoading = false;
  String _selectedPeriod = 'Month';
  String _selectedChart = 'Expenses';
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _transactionService.fetchTransactions();
      final accounts = await _transactionService.fetchAccounts();

      setState(() {
        allTransactions = _transactionService.allTransactions;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  List<ExpenseTransaction> _getFilteredTransactions() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return allTransactions.where((tx) =>
            tx.date.isAfter(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day))
        ).toList();
      case 'Month':
        return allTransactions.where((tx) =>
        tx.date.month == now.month && tx.date.year == now.year
        ).toList();
      case 'Year':
        return allTransactions.where((tx) => tx.date.year == now.year).toList();
      case 'All Time':
        return allTransactions;
      default:
        return allTransactions;
    }
  }

  List<ChartData> _generateCategoryData() {
    final transactions = _getFilteredTransactions();
    final Map<String, double> categoryTotals = {};

    for (var tx in transactions.where((t) => t.type == 'expense')) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    return categoryTotals.entries
        .map((e) => ChartData(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<ChartData> _generateIncomeData() {
    final transactions = _getFilteredTransactions();
    final Map<String, double> incomeTotals = {};

    for (var tx in transactions.where((t) => t.type == 'income')) {
      incomeTotals[tx.category] = (incomeTotals[tx.category] ?? 0) + tx.amount;
    }

    return incomeTotals.entries
        .map((e) => ChartData(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<BarData> _generateDailyData() {
    final transactions = _getFilteredTransactions();
    final Map<String, Map<String, double>> dailyData = {};

    // Get the start and end dates based on selected period
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day);
    int daysDifference;

    switch (_selectedPeriod) {
      case 'Week':
        startDate = now.subtract(Duration(days: 6));
        daysDifference = 7;
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        daysDifference = DateTime(now.year, now.month + 1, 0).day;
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        daysDifference = 12; // We'll use months for year view
        break;
      case 'All Time':
      // Find the earliest transaction date
        if (transactions.isEmpty) {
          startDate = now.subtract(const Duration(days: 30));
          daysDifference = 30;
        } else {
          transactions.sort((a, b) => a.date.compareTo(b.date));
          startDate = transactions.first.date;
          daysDifference = now.difference(startDate).inDays + 1;
          if (daysDifference > 90) {
            // If more than 90 days, group by month
            startDate = DateTime(startDate.year, startDate.month, 1);
            final months = (now.year - startDate.year) * 12 + now.month - startDate.month;
            daysDifference = months + 1;
          }
        }
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
        daysDifference = 30;
    }

    // Initialize the map with all dates in the range
    if (_selectedPeriod == 'Year') {
      // Initialize with months for year view
      for (int month = 1; month <= 12; month++) {
        final date = DateTime(now.year, month, 1);
        final dateKey = DateFormat('MMM').format(date);
        dailyData[dateKey] = {'income': 0.0, 'expense': 0.0};
      }
    } else if (daysDifference > 90) {
      // Initialize with months for all time view if more than 90 days
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      while (current.isBefore(DateTime(now.year, now.month + 1, 1))) {
        final dateKey = DateFormat('MMM yyyy').format(current);
        dailyData[dateKey] = {'income': 0.0, 'expense': 0.0};
        current = DateTime(
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          1,
        );
      }
    } else {
      // Initialize with days
      for (int i = 0; i < daysDifference; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = DateFormat('d MMM').format(date);
        dailyData[dateKey] = {'income': 0.0, 'expense': 0.0};
      }
    }

    // Populate with transaction data
    for (var tx in transactions) {
      String dateKey;

      if (_selectedPeriod == 'Year') {
        dateKey = DateFormat('MMM').format(tx.date);
      } else if (daysDifference > 90) {
        dateKey = DateFormat('MMM yyyy').format(tx.date);
      } else {
        dateKey = DateFormat('d MMM').format(tx.date);
      }

      if (dailyData.containsKey(dateKey)) {
        final type = tx.type == 'income' ? 'income' : 'expense';
        dailyData[dateKey]![type] = (dailyData[dateKey]![type] ?? 0) + tx.amount;
      }
    }

    // Convert to list of BarData
    return dailyData.entries
        .map((e) => BarData(e.key, e.value['income'] ?? 0, e.value['expense'] ?? 0))
        .toList();
  }

  double _calculateTotalExpense() {
    final transactions = _getFilteredTransactions();
    return transactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _calculateTotalIncome() {
    final transactions = _getFilteredTransactions();
    return transactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Widget _buildSummaryCards() {
    final totalExpense = _calculateTotalExpense();
    final totalIncome = _calculateTotalIncome();
    final balance = totalIncome - totalExpense;

    return Row(
      children: [
        _buildSummaryCard(
          title: 'Income',
          amount: totalIncome,
          icon: Icons.arrow_upward,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          title: 'Expenses',
          amount: totalExpense,
          icon: Icons.arrow_downward,
          color: Colors.red,
        ),
        const SizedBox(width: 12),
        _buildSummaryCard(
          title: 'Balance',
          amount: balance,
          icon: Icons.account_balance_wallet,
          color: balance >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('Week'),
          _buildPeriodButton('Month'),
          _buildPeriodButton('Year'),
          _buildPeriodButton('All Time'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedPeriod == period ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: _selectedPeriod == period ? Colors.white : Colors.grey,
            fontWeight: _selectedPeriod == period ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChartFilter() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartButton('Daily'),
          _buildChartButton('Expenses'),
          _buildChartButton('Income'),
        ],
      ),
    );
  }

  Widget _buildChartButton(String chart) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedChart = chart;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedChart == chart ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          chart,
          style: TextStyle(
            color: _selectedChart == chart ? Colors.white : Colors.grey,
            fontWeight: _selectedChart == chart ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (_selectedChart) {
      case 'Daily':
        return _buildLineChart();
      case 'Expenses':
        return _buildSimplePieChart(_generateCategoryData(), Colors.red);
      case 'Income':
        return _buildSimplePieChart(_generateIncomeData(), Colors.green);
      default:
        return _buildSimplePieChart(_generateCategoryData(), Colors.red);
    }
  }

  // New method to build a scrollable line chart
  Widget _buildLineChart() {
    final data = _generateDailyData();
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data for this period',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Find the maximum value for scaling
    double maxValue = 0;
    for (var item in data) {
      maxValue = math.max(maxValue, math.max(item.income, item.expense));
    }

    // Add a little padding to the max value to prevent lines from touching the top
    maxValue = maxValue * 1.1;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(top: 20, right: 20),
              // Make the chart wider based on data points
              width: math.max(MediaQuery.of(context).size.width - 32, data.length * 60.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${NumberFormat('#,##0').format(maxValue)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const Spacer(),
                      Text('₹${NumberFormat('#,##0').format(maxValue * 0.75)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const Spacer(),
                      Text('₹${NumberFormat('#,##0').format(maxValue * 0.5)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const Spacer(),
                      Text('₹${NumberFormat('#,##0').format(maxValue * 0.25)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const Spacer(),
                      Text('₹0', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      const SizedBox(height: 20), // Space for x-axis labels
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Line chart area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Background grid lines
                            _buildGridLines(constraints, maxValue),

                            // Draw income line
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight - 20), // Subtract space for x-axis labels
                              painter: LineChartPainter(
                                data: data,
                                maxValue: maxValue,
                                color: Colors.green,
                                dataType: 'income',
                              ),
                            ),

                            // Draw expense line
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight - 20), // Subtract space for x-axis labels
                              painter: LineChartPainter(
                                data: data,
                                maxValue: maxValue,
                                color: Colors.red,
                                dataType: 'expense',
                              ),
                            ),

                            // X-axis labels
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  data.length,
                                      (index) => SizedBox(
                                    width: constraints.maxWidth / data.length,
                                    child: Text(
                                      data[index].date,
                                      style: TextStyle(color: Colors.grey[400], fontSize: 9),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Income', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Expense', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to build grid lines for the chart
  Widget _buildGridLines(BoxConstraints constraints, double maxValue) {
    return CustomPaint(
      size: Size(constraints.maxWidth, constraints.maxHeight - 20),
      painter: GridLinePainter(maxValue: maxValue),
    );
  }

  Widget _buildSimplePieChart(List<ChartData> data, Color baseColor) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data for this period',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Calculate total
    final total = data.fold(0.0, (sum, item) => sum + item.amount);

    // Generate colors
    final List<Color> colors = List.generate(
      data.length,
          (index) => HSLColor.fromColor(baseColor)
          .withLightness(0.3 + 0.4 * (index / math.max(1, data.length - 1)))
          .toColor(),
    );

    return Column(
      children: [
        // Pie chart
        SizedBox(
          height: 200,
          child: CustomPaint(
            size: const Size(200, 200),
            painter: PieChartPainter(data: data, colors: colors, total: total),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(data.length, (i) {
            final item = data[i];
            final percent = total > 0 ? (item.amount / total * 100) : 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors[i % colors.length].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i % colors.length],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.category}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₹${NumberFormat('#,##0').format(item.amount)} (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPeriodFilter(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChartFilter(),
              const SizedBox(height: 16),
              _buildChart(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for grid lines
class GridLinePainter extends CustomPainter {
  final double maxValue;

  GridLinePainter({required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * (i / 4));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<BarData> data;
  final double maxValue;
  final Color color;
  final String dataType; // 'income' or 'expense'

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.dataType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final pointWidth = size.width / data.length;

    // Draw the line
    bool isFirstPoint = true;
    for (int i = 0; i < data.length; i++) {
      final value = dataType == 'income' ? data[i].income : data[i].expense;
      final x = i * pointWidth + (pointWidth / 2);
      final y = size.height - (size.height * (value / maxValue));

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }

      // Draw point at each data point
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final List<ChartData> data;
  final List<Color> colors;
  final double total;

  PieChartPainter({required this.data, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2; // Explicitly make radius a double
    final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);

    double startAngle = -math.pi / 2; // Start from top (12 o'clock position)

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double sweepAngle = total > 0 ? (item.amount / total) * 2 * math.pi : 0; // Explicitly make sweepAngle a double

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw a small white border between segments
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 1.5;

      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    canvas.drawCircle(
      center,
      radius * 0.5, // Explicitly cast to double if needed: (radius * 0.5).toDouble()
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}