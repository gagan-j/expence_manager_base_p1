import 'package:flutter/material.dart';
import '../models/account.dart';
import '../db/db_helper.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedAccounts = await DBHelper.instance.fetchAccounts();
      setState(() {
        accounts = fetchedAccounts;
      });
      print('Loaded ${accounts.length} accounts');
    } catch (e) {
      print('Error loading accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        final TextEditingController _accountGroupController = TextEditingController(text: 'Default Group');

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
              const SizedBox(height: 8),
              TextField(
                controller: _accountGroupController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Account Group",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final String accountName = _accountNameController.text.trim();
                final double initialBalance =
                    double.tryParse(_accountBalanceController.text) ?? 0.0;
                final String accountGroup = _accountGroupController.text.trim();

                if (accountName.isNotEmpty) {
                  try {
                    final newAccount = Account(
                      name: accountName,
                      initialValue: initialBalance,
                      accountGroup: accountGroup.isEmpty ? 'Default Group' : accountGroup,
                    );

                    // Save to database
                    await DBHelper.instance.insertAccount(newAccount);

                    // Refresh accounts list
                    _loadAccounts();

                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding account: $e')),
                    );
                  }
                } else {
                  // Add a message if name is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid account name')),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
            tooltip: 'Refresh accounts',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAccounts,
        color: Colors.white,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              accounts.isEmpty
                  ? Container(
                height: 200,
                alignment: Alignment.center,
                child: const Text(
                  'No accounts yet. Add one using the + button!',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(account.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance: ₹${account.initialValue.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'Group: ${account.accountGroup}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          if (account.id != null) {
                            try {
                              await DBHelper.instance.deleteAccount(account.id!);
                              _loadAccounts();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting account: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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