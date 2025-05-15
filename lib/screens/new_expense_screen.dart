// Import Account model and update the form to include account selection
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/transaction_service.dart';

class NewExpenseScreen extends StatefulWidget {
  final ExpenseTransaction? transaction; // For editing existing transaction

  const NewExpenseScreen({Key? key, this.transaction}) : super(key: key);

  @override
  _NewExpenseScreenState createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';
  String? _selectedCategory;
  String? _selectedSubcategory;
  int? _selectedAccountId;

  bool _isLoading = true;
  List<Account> _accounts = [];

  final Map<String, List<String>> categories = {
    'Food': ['Groceries', 'Restaurant', 'Take-out', 'Snacks', 'Coffee'],
    'Housing': ['Rent', 'Mortgage', 'Utilities', 'Maintenance', 'Insurance'],
    'Transportation': ['Public Transit', 'Fuel', 'Car Maintenance', 'Ride Share', 'Parking'],
    'Entertainment': ['Movies', 'Games', 'Subscriptions', 'Events', 'Hobbies'],
    'Shopping': ['Clothing', 'Electronics', 'Gifts', 'Home Goods', 'Personal Care'],
    'Health': ['Doctor', 'Pharmacy', 'Fitness', 'Insurance', 'Self-care'],
    'Education': ['Tuition', 'Books', 'Courses', 'Supplies', 'Software'],
    'Travel': ['Flights', 'Accommodation', 'Transportation', 'Food', 'Activities'],
    'Salary': ['Regular Income', 'Bonus', 'Commission'],
    'Investments': ['Dividends', 'Interest', 'Capital Gains'],
    'Gifts': ['Received', 'Given'],
    'Other': ['Miscellaneous'],
  };

  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();

    // If we're editing an existing transaction, pre-populate the form
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedSubcategory = widget.transaction!.subcategory;
      _selectedAccountId = widget.transaction!.accountId;
    }

    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _transactionService.fetchAccounts();
      setState(() {
        _accounts = accounts;
        // If no account was pre-selected and we have accounts available, default to the first one
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          _selectedAccountId = accounts[0].id;
        }
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

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      if (_selectedSubcategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a subcategory')),
        );
        return;
      }

      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final transaction = ExpenseTransaction(
          id: widget.transaction?.id,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          category: _selectedCategory!,
          subcategory: _selectedSubcategory!,
          type: _selectedType,
          accountId: _selectedAccountId,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (widget.transaction == null) {
          await _transactionService.addTransaction(transaction);
        } else {
          await _transactionService.updateTransaction(transaction);
        }

        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Selector
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'expense';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedType == 'expense'
                                ? Colors.red
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'income';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedType == 'income'
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title Field
              const Text(
                'Title',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter a title',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              const Text(
                'Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Selector
              const Text(
                'Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    items: _accounts.map((account) {
                      return DropdownMenuItem<int>(
                        value: account.id,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForType(account.type),
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              account.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            Text(
                              '₹${NumberFormat('#,##0.00').format(account.balance)}',
                              style: TextStyle(
                                color: account.balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
                    hint: const Text(
                      'Select Account',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              const Text(
                'Date',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    items: categories.keys.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedSubcategory = null;
                      });
                    },
                    hint: const Text(
                      'Select Category',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subcategory Dropdown
              if (_selectedCategory != null) ...[
                const Text(
                  'Subcategory',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubcategory,
                      isExpanded: true,
                      dropdownColor: Colors.grey[850],
                      items: (categories[_selectedCategory]?.cast<String>() ?? <String>[])
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategory = value;
                        });
                      },
                      hint: const Text(
                        'Select Subcategory',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes Field
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add notes',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}