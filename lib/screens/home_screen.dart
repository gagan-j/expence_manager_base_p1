import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../models/transaction.dart';
import '../widgets/pie_chart.dart';
import 'new_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Transaction> transactions = [
    Transaction(
      category: 'Food',
      subCategory: 'Groceries',
      name: 'Big Bazaar',
      amount: 500,
      date: DateTime.now(),
    ),
    Transaction(
      category: 'Transport',
      subCategory: 'Bus',
      name: 'BMTC Pass',
      amount: 200,
      date: DateTime.now().subtract(Duration(days: 1)),
    ),
    Transaction(
      category: 'Utilities',
      subCategory: 'Electricity',
      name: 'BESCOM Bill',
      amount: 800,
      date: DateTime.now().subtract(Duration(days: 2)),
    ),
  ];

  void _addNewTransaction(Transaction newTxn) {
    setState(() {
      transactions.insert(0, newTxn);
    });
  }

  List<ChartData> _generateChartData() {
    final Map<String, double> categoryTotals = {};

    for (var txn in transactions) {
      categoryTotals[txn.category] =
          (categoryTotals[txn.category] ?? 0) + txn.amount;
    }

    return categoryTotals.entries
        .map((entry) => ChartData(category: entry.key, amount: entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateChartData();

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[400],
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final newTxn = await Navigator.push<Transaction>(
            context,
            MaterialPageRoute(builder: (context) => NewExpenseScreen()),
          );

          if (newTxn != null) {
            _addNewTransaction(newTxn);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ExpensePieChart(chartData: chartData),
              const SizedBox(height: 20),
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final txn = transactions[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet,
                        color: Colors.white),
                    title: Text(
                      txn.name ?? 'No Name',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${txn.category} → ${txn.subCategory ?? "Other"}\n${txn.date.day}/${txn.date.month}/${txn.date.year}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      '-₹${txn.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
