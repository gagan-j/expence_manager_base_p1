import 'package:flutter/material.dart';
import '../models/account.dart'; // Assuming you have the Account model here

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> accounts = [
    Account(name: 'Cash', initialValue: 1000.0, accountGroup: 'Cash Group'),
    Account(name: 'Bank Account', initialValue: 2000.0, accountGroup: 'Bank Group'),
  ];

  double get netWorth {
    return accounts.fold(0, (sum, account) => sum + account.initialValue);
  }

  double get totalIncome {
    return accounts.fold(0, (sum, account) => sum + account.initialValue);
  }

  double get totalExpense {
    // For now, it's set to 0, you can calculate it later based on your transactions
    return 0;
  }

  void _addNewAccount() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _accountNameController = TextEditingController();
        final TextEditingController _accountBalanceController = TextEditingController();

        return AlertDialog(
          title: const Text("Add New Account"),
          backgroundColor: Colors.black,
          titleTextStyle: const TextStyle(color: Colors.white),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _accountNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Account Name",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _accountBalanceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial Balance",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final String accountName = _accountNameController.text.trim();
                final double initialBalance =
                    double.tryParse(_accountBalanceController.text) ?? 0.0;

                if (accountName.isNotEmpty && initialBalance > 0) {
                  setState(() {
                    accounts.add(Account(
                      name: accountName,
                      initialValue: initialBalance,
                      accountGroup: 'Default Group', // Default accountGroup
                    ));
                  });
                  Navigator.of(context).pop();
                } else {
                  // Add a message if balance is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid account name and balance')),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accounts"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth & Income/Expense/Total Row
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Net Worth: ₹${netWorth.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Income", style: TextStyle(color: Colors.white70)),
                          Text("₹${totalIncome.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text("Expense", style: TextStyle(color: Colors.white70)),
                          Text("₹${totalExpense.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Total", style: TextStyle(color: Colors.white70)),
                          Text("₹${(netWorth + totalIncome - totalExpense).toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List of Accounts
            ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(account.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '₹${account.initialValue.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAccount,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}