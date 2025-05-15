import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../widgets/pie_chart.dart';
import '../db/db_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DBHelper.instance.fetchTransactions();
      setState(() {
        allTransactions = transactions;
      });
      print('Loaded ${transactions.length} transactions');
    } catch (e) {
      print('Error loading transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Transaction> _filteredTransactions() {
    final now = DateTime.now();

    return allTransactions.where((txn) {
      if (showWeekly) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return txn.date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } else {
        return txn.date.month == now.month && txn.date.year == now.year;
      }
    }).toList();
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
        title: const Text('Home'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh transactions',
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
                  // Income vs Expense Card removed as requested

                  const SizedBox(height: 16),

                  if (chartData.isEmpty)
                    Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: const Text(
                        'No expenses yet. Add one using the + button!',
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

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                    },
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 20),

                  // Transactions Section with Tabs
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: const [
                            Tab(text: 'All Transactions'),
                            Tab(text: 'Income Only'),
                          ],
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.grey[800],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 400, // Set a fixed height for the TabBarView
                          child: TabBarView(
                            children: [
                              // All Transactions Tab
                              _buildTransactionList(filteredTxns),

                              // Income Only Tab
                              _buildTransactionList(
                                filteredTxns.where((txn) => txn.type == 'income').toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewExpenseScreen()),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'No transactions for this period',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final bool isIncome = txn.type == 'income';

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
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

              if (result == true) {
                setState(() {
                  allTransactions.remove(txn);
                });
                if (txn.id != null) {
                  await DBHelper.instance.deleteTransaction(txn.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                }
              }
            },
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              txn.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '${txn.category} ${txn.subCategory != null ? "→ ${txn.subCategory}" : ""}\n${DateFormat.yMMMd().format(txn.date)}',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              '${isIncome ? "+" : "-"}₹${txn.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}