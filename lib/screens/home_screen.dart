import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../widgets/pie_chart.dart';
import '../services/transaction_service.dart';
import 'new_expense_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showWeekly = false;
  List<Transaction> allTransactions = [];
  bool _isLoading = false;
  final TransactionService _transactionService = TransactionService();
  FinancialSummary _summary = FinancialSummary(totalIncome: 0, totalExpense: 0, netWorth: 0);

  @override
  void initState() {
    super.initState();
    _loadTransactions();

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

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _transactionService.fetchTransactions();
      setState(() {
        allTransactions = _transactionService.allTransactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transactions: $e')),
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

  @override
  Widget build(BuildContext context) {
    final filteredTxns = _filteredTransactions();
    final chartData = _generateChartData(filteredTxns);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Profile picture that logs out when clicked
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.deepPurple.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTransactions,
          color: Colors.white,
          backgroundColor: Colors.grey[900],
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Expenses Summary - No card background
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Monthly Expenses',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Income Column
                            _buildSummaryItem(
                                "Income",
                                "₹${_summary.totalIncome.toStringAsFixed(0)}",
                                Colors.green
                            ),

                            // Vertical Divider
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[700],
                            ),

                            // Expense Column
                            _buildSummaryItem(
                                "Expenses",
                                "₹${_summary.totalExpense.toStringAsFixed(0)}",
                                Colors.red
                            ),

                            // Vertical Divider
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[700],
                            ),

                            // Balance Column
                            _buildSummaryItem(
                                "Balance",
                                "₹${_summary.balance.toStringAsFixed(0)}",
                                _summary.balance >= 0 ? Colors.green : Colors.red
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Add more space before pie chart section
                  const SizedBox(height: 24),

                  // Monthly Breakdown header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showWeekly = !showWeekly;
                          });
                        },
                        icon: Icon(
                          Icons.calendar_today,
                          color: Colors.blue[300],
                          size: 16,
                        ),
                        label: Text(
                          showWeekly ? 'Weekly' : 'Monthly',
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Increased space for pie chart
                  if (chartData.isEmpty)
                    Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No expenses yet. Add one using the + button!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      // Increased height to prevent overflow
                      height: 280,
                      // Added padding for better spacing
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ExpensePieChart(
                          chartData: chartData,
                          showWeekly: showWeekly,
                          onToggle: () {
                            setState(() {
                              showWeekly = !showWeekly;
                            });
                          },
                        ),
                      ),
                    ),

                  // Extra spacing after the pie chart
                  const SizedBox(height: 30),

                  // Recent Transactions Header
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Transactions List
                  _buildTransactionList(filteredTxns),

                  // Add bottom padding to prevent FAB overlap
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      // Simple FAB that shows a bottom sheet
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          _showAddTransactionBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTransactionButton(
                    context,
                    icon: Icons.arrow_downward,
                    label: 'Expense',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewExpenseScreen(initialType: 'expense'),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadTransactions();
                        }
                      });
                    },
                  ),
                  _buildTransactionButton(
                    context,
                    icon: Icons.arrow_upward,
                    label: 'Income',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewExpenseScreen(initialType: 'income'),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadTransactions();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            )
        ),
        const SizedBox(height: 8),
        Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions for this period',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Limit to just the most recent transactions
    final displayTransactions = transactions.take(4).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTransactions.length,
      itemBuilder: (context, index) {
        final txn = displayTransactions[index];
        final bool isIncome = txn.type == 'income';

        // Get previous transaction date for grouping
        final previousDate = index > 0 ? displayTransactions[index - 1].date : null;
        final showDateHeader = previousDate == null ||
            DateFormat.yMd().format(previousDate) !=
                DateFormat.yMd().format(txn.date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header when date changes
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4, left: 8),
                child: Text(
                  DateFormat.yMMMMd().format(txn.date),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

            Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                dense: true, // Make the list tile more compact
                onLongPress: () async {
                  // Show confirmation dialog
                  final bool? result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Transaction'),
                        backgroundColor: Colors.grey[850],
                        content: Text(
                          'Are you sure you want to delete this ${txn.type}?',
                          style: const TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (result == true && txn.id != null) {
                    try {
                      await _transactionService.deleteTransaction(txn.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete transaction: $e')),
                      );
                    }
                  }
                },
                leading: CircleAvatar(
                  radius: 16, // Smaller radius
                  backgroundColor: isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 16, // Smaller icon
                  ),
                ),
                title: Text(
                  txn.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14, // Smaller font
                  ),
                ),
                subtitle: Text(
                  txn.category,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12, // Smaller font
                  ),
                ),
                trailing: Text(
                  '${isIncome ? "+" : "-"}₹${txn.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Smaller font
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}