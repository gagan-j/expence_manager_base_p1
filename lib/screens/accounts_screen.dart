import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../services/transaction_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<Account> _accounts = [];

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
      final accounts = await _transactionService.fetchAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts: $e')),
      );
    }
  }

  void _showAddEditAccountDialog([Account? account]) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: account?.name ?? '');
    final _balanceController = TextEditingController(
      text: account?.balance != null ? account!.balance.toString() : '',
    );
    String _selectedType = account?.type ?? 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(account == null ? 'Add Account' : 'Edit Account'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _balanceController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Balance',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an initial balance';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                      DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                      DropdownMenuItem(value: 'savings', child: Text('Savings')),
                      DropdownMenuItem(value: 'investment', child: Text('Investment')),
                    ],
                    onChanged: (value) {
                      _selectedType = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newAccount = Account(
                    id: account?.id,
                    name: _nameController.text,
                    balance: double.parse(_balanceController.text),
                    type: _selectedType,
                    iconName: _getIconNameForType(_selectedType),
                  );

                  try {
                    if (account == null) {
                      await _transactionService.addAccount(newAccount);
                    } else {
                      await _transactionService.updateAccount(newAccount);
                    }
                    Navigator.of(context).pop();
                    _loadAccounts();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving account: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getIconNameForType(String type) {
    switch (type) {
      case 'cash':
        return 'money';
      case 'bank':
        return 'account_balance';
      case 'credit':
        return 'credit_card';
      case 'savings':
        return 'savings';
      case 'investment':
        return 'trending_up';
      default:
        return 'account_balance_wallet';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Future<void> _deleteAccount(Account account) async {
    try {
      await _transactionService.deleteAccount(account.id!);
      _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Accounts',
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
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Total Balance: ₹${NumberFormat('#,##0.00').format(_accounts.fold(0.0, (sum, account) => sum + account.balance))}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ..._accounts.map((account) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.grey[900],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForType(account.type),
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            account.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##0.00').format(account.balance)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: account.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () {
                                _showAddEditAccountDialog(account);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () {
                                _deleteAccount(account);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddEditAccountDialog();
        },
      ),
    );
  }
}