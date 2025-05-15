import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../widgets/pie_chart.dart';
import '../services/transaction_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool showWeekly = false;
  List<Transaction> allTransactions = [];
  bool _isLoading = false;
  final TransactionService _transactionService = TransactionService();
  FinancialSummary _summary = FinancialSummary(totalIncome: 0, totalExpense: 0, netWorth: 0);

  @override
  void initState() {
    super.initState();
    _loadData();

    // Subscribe to updates
    _transactionService.transactionsStream.listen((transactions) {
      if (mounted) {
        setState(() {
          allTransactions = transactions;
        });
      }
    });

    _transactionService.summaryStream.listen((summary) {
      if (mounted) {
        setState(() {
          _summary = summary;
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _transactionService.fetchTransactions();
      await _transactionService.fetchAccounts();

      setState(() {
        allTransactions = _transactionService.allTransactions;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Transaction> _filteredTransactions() {
    return _transactionService.getFilteredTransactions(weekly: showWeekly);
  }

  List<ChartData> _generateChartData(List<Transaction> txns) {
    final Map<String, double> categoryTotals = {};

    for (var txn in txns.where((t) => t.type == 'expense')) {
      categoryTotals[txn.category] =
          (categoryTotals[txn.category] ?? 0) + txn.amount;
    }

    return categoryTotals.entries
        .map((entry) => ChartData(category: entry.key, amount: entry.value))
        .toList();
  }

  // Monthly stats
  Map<String, double> get _monthlyIncome {
    final Map<String, double> monthlyData = {};

    // Get the last 6 months
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final month = now.month - i <= 0
          ? now.month - i + 12
          : now.month - i;
      final year = now.month - i <= 0
          ? now.year - 1
          : now.year;

      final monthName = DateFormat('MMM').format(DateTime(year, month));
      monthlyData[monthName] = 0;
    }

    // Fill with data
    for (var txn in allTransactions.where((t) => t.type == 'income')) {
      final monthName = DateFormat('MMM').format(txn.date);
      if (monthlyData.containsKey(monthName)) {
        monthlyData[monthName] = (monthlyData[monthName] ?? 0) + txn.amount;
      }
    }

    // Reverse to get chronological order
    return Map.fromEntries(monthlyData.entries.toList().reversed);
  }

  Map<String, double> get _monthlyExpense {
    final Map<String, double> monthlyData = {};

    // Get the last 6 months
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final month = now.month - i <= 0
          ? now.month - i + 12
          : now.month - i;
      final year = now.month - i <= 0
          ? now.year - 1
          : now.year;

      final monthName = DateFormat('MMM').format(DateTime(year, month));
      monthlyData[monthName] = 0;
    }

    // Fill with data
    for (var txn in allTransactions.where((t) => t.type == 'expense')) {
      final monthName = DateFormat('MMM').format(txn.date);
      if (monthlyData.containsKey(monthName)) {
        monthlyData[monthName] = (monthlyData[monthName] ?? 0) + txn.amount;
      }
    }

    // Reverse to get chronological order
    return Map.fromEntries(monthlyData.entries.toList().reversed);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxns = _filteredTransactions();
    final chartData = _generateChartData(filteredTxns);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.white,
          backgroundColor: Colors.grey[900],
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income vs Expense Card
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Income vs Expense',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Income",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("₹${_summary.totalIncome.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.green)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Expense",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("₹${_summary.totalExpense.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _summary.totalExpense > 0 && _summary.totalIncome > 0
                                ? _summary.totalExpense / (_summary.totalIncome + _summary.totalExpense)
                                : 0.5,
                            backgroundColor: Colors.green.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Balance: ₹${_summary.balance.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: _summary.balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Monthly Trends Card - Fixed layout
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Trends',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Income Trend - Fixed Layout
                          _buildFlatTrendSection(
                              "Income Trend",
                              _monthlyIncome,
                              Colors.green.shade300
                          ),

                          const SizedBox(height: 24),

                          // Expense Trend - Fixed Layout
                          _buildFlatTrendSection(
                              "Expense Trend",
                              _monthlyExpense,
                              Colors.red.shade300
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expense Breakdown Card
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Expense Breakdown',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showWeekly = !showWeekly;
                                  });
                                },
                                child: Text(
                                  showWeekly ? 'Weekly' : 'Monthly',
                                  style: TextStyle(color: Colors.blue.shade300),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (chartData.isEmpty)
                            Container(
                              height: 300,
                              alignment: Alignment.center,
                              child: const Text(
                                'No expenses yet. Add one to see breakdowns.',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ExpensePieChart(
                              chartData: chartData,
                              showWeekly: showWeekly,
                              onToggle: () {
                                setState(() {
                                  showWeekly = !showWeekly;
                                });
                              },
                            ),
                        ],
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

  // Trend section with fixed heights to prevent overflow
  Widget _buildFlatTrendSection(String title, Map<String, double> data, Color color) {
    // Get the maximum value for reference
    final double maxValue = data.values.fold(0.0, (max, value) => value > max ? value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),

        // Fixed height bar chart
        SizedBox(
          height: 50, // Fixed height
          child: Row(
            children: data.entries.map((entry) {
              // Calculate height as percentage of max
              double percentage = maxValue > 0 ? entry.value / maxValue : 0;
              double barHeight = 40 * percentage; // Max height 40px

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Spacer(), // Pushes bar to bottom
                    Container(
                      height: barHeight.clamp(0, 40), // Ensure height doesn't exceed 40px
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Month labels - separate from bars to prevent overflow
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: data.keys.map((month) =>
              Text(
                month,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              )
          ).toList(),
        ),

        // Min-max labels
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '₹0',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            if (maxValue > 0)
              Text(
                '₹${maxValue.toInt()}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }
}