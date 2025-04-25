import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../widgets/pie_chart.dart';
import 'new_expense_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:animations/animations.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showWeekly = false;

  final List<Transaction> allTransactions = [
    Transaction(
      category: 'Food',
      subCategory: 'Groceries',
      name: 'Big Bazaar',
      amount: 500,
      date: DateTime.now(),
      account: 'Cash',
    ),
    Transaction(
      category: 'Transport',
      subCategory: 'Bus',
      name: 'BMTC Pass',
      amount: 200,
      date: DateTime.now().subtract(const Duration(days: 1)),
      account: 'UPI',
    ),
    Transaction(
      category: 'Utilities',
      subCategory: 'Electricity',
      name: 'BESCOM Bill',
      amount: 800,
      date: DateTime.now().subtract(const Duration(days: 8)),
      account: 'Bank',
    ),
  ];

  void _addNewTransaction(Transaction newTxn) {
    setState(() {
      allTransactions.insert(0, newTxn);
    });
  }

  List<Transaction> _filteredTransactions() {
    final now = DateTime.now();

    return allTransactions.where((txn) {
      if (showWeekly) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return txn.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            txn.date.month == now.month &&
            txn.date.year == now.year;
      } else {
        return txn.date.month == now.month && txn.date.year == now.year;
      }
    }).toList();
  }

  List<ChartData> _generateChartData(List<Transaction> txns) {
    final Map<String, double> categoryTotals = {};
    for (var txn in txns) {
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpensePieChart(
                  chartData: chartData,
                  showWeekly: showWeekly,
                  onToggle: () {
                    setState(() {
                      showWeekly = !showWeekly;
                    });
                  },
                ),

                const SizedBox(height: 16),
                const Text(
                  'Income vs Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                  },
                  child: const Text('Logout'),
                ),
                const SizedBox(height: 20),
                Text(
                  showWeekly ? 'This Week\'s Transactions' : 'This Month\'s Transactions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxns.length,
                  itemBuilder: (context, index) {
                    final txn = filteredTxns[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        onLongPress: () {
                          setState(() {
                            allTransactions.remove(txn);
                          });
                        },
                        leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
                        title: Text(
                          txn.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${txn.category} → ${txn.subCategory ?? "Other"}\n${DateFormat.yMMMd().format(txn.date)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          '-₹${txn.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 500),
        openBuilder: (context, _) => const NewExpenseScreen(),
        closedElevation: 6.0,
        closedShape: const CircleBorder(),
        closedColor: Colors.grey[400]!,
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            onPressed: openContainer,
            backgroundColor: Colors.grey[400],
            child: const Icon(Icons.add, color: Colors.black),
          );
        },
        onClosed: (result) {
          if (result != null && result is Transaction) {
            _addNewTransaction(result);
          }
        },
      ),
    );
  }
}
