import '../models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../db/db_helper.dart';
import '../services/transaction_service.dart';

class NewExpenseScreen extends StatefulWidget {
  final String? initialType;

  const NewExpenseScreen({Key? key, this.initialType}) : super(key: key);

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isIncome = false;
  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedAccount;
  DateTime _selectedDateTime = DateTime.now();
  bool _isSaving = false;

  final Map<String, List<String>> _categorySubcategories = {
    'Food': ['Groceries', 'Dining Out', 'Snacks'],
    'Transport': ['Fuel', 'Public Transport', 'Taxi'],
    'Shopping': ['Clothing', 'Electronics', 'Gifts'],
    'Bills': ['Electricity', 'Water', 'Internet', 'Phone'],
    'Entertainment': ['Movies', 'Games', 'Events'],
    'Health': ['Medicine', 'Doctor', 'Gym'],
    'Travel': ['Flights', 'Hotels', 'Activities'],
    'Education': ['Books', 'Courses', 'Tuition'],
    'Personal': ['Haircut', 'Cosmetics', 'Others'],
    // Income categories
    'Salary': ['Regular', 'Bonus', 'Overtime'],
    'Investment': ['Dividends', 'Interest', 'Capital Gains'],
    'Gifts': ['Birthday', 'Festival', 'Others'],
    'Refunds': ['Shopping', 'Services', 'Tax'],
    'Rent': ['Property', 'Equipment', 'Vehicle'],
    'Business': ['Sales', 'Services', 'Commission'],
  };

  final newTransaction = ExpenseTransaction(
    category: selectedCategory!,
    subCategory: selectedSubcategory,
    name: _nameController.text.isEmpty
        ? (_isIncome ? "Unnamed Income" : "Unnamed Expense")
        : _nameController.text,
    amount: double.tryParse(_amountController.text) ?? 0,
    date: _selectedDateTime,
    description: _descriptionController.text,
    account: selectedAccount!,
    type: _isIncome ? 'income' : 'expense',
  );

  final List<String> _incomeCategories = [
    'Salary', 'Investment', 'Gifts', 'Refunds', 'Rent', 'Business'
  ];

  final List<String> _expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment',
    'Health', 'Travel', 'Education', 'Personal'
  ];

  List<String> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    // Set initial type based on parameter
    if (widget.initialType == 'income') {
      _isIncome = true;
    } else if (widget.initialType == 'expense') {
      _isIncome = false;
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await DBHelper.instance.fetchAccounts();
      setState(() {
        _accounts = accounts.map((acc) => acc.name).toList();
        if (_accounts.isNotEmpty) {
          selectedAccount = _accounts.first;
        }
      });
    } catch (e) {
      print('Error loading accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts: $e')),
      );
    }
  }

  void _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  void _saveTransaction() {
    if (_amountController.text.isEmpty ||
        selectedCategory == null ||
        selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all the required fields."),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Create the transaction with type
    final newTransaction = Transaction(
      category: selectedCategory!,
      subCategory: selectedSubcategory,
      name: _nameController.text.isEmpty
          ? (_isIncome ? "Unnamed Income" : "Unnamed Expense")
          : _nameController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      date: _selectedDateTime,
      description: _descriptionController.text,
      account: selectedAccount!,
      type: _isIncome ? 'income' : 'expense', // Set the type based on selection
    );

    // First pop the screen, then save in background
    Navigator.pop(context, true);

    // Use the transaction service to save
    TransactionService().addTransaction(newTransaction).then((_) {
      print('${_isIncome ? "Income" : "Expense"} transaction saved successfully');
    }).catchError((e) {
      print('Error in save process: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _isIncome ? 'Add Income' : 'Add Expense',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Switch between income and expense
          IconButton(
            icon: Icon(
              _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: _isIncome ? Colors.green : Colors.red,
            ),
            onPressed: () {
              setState(() {
                _isIncome = !_isIncome;
                selectedCategory = null;
                selectedSubcategory = null;
              });
            },
            tooltip: 'Toggle Income/Expense',
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Indicator
            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: _isIncome ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isIncome ? 'Income' : 'Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.currency_rupee, color: Colors.grey),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _amountController.clear();
                  },
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.grey[900],
              items: (_isIncome ? _incomeCategories : _expenseCategories)
                  .map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                  selectedSubcategory = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Subcategory Dropdown (if a category is selected)
            if (selectedCategory != null &&
                _categorySubcategories.containsKey(selectedCategory))
              DropdownButtonFormField<String>(
                value: selectedSubcategory,
                decoration: const InputDecoration(
                  labelText: 'Subcategory (Optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.grey[900],
                items:
                _categorySubcategories[selectedCategory]!.map((String subcategory) {
                  return DropdownMenuItem<String>(
                    value: subcategory,
                    child: Text(subcategory),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubcategory = value;
                  });
                },
              ),

            if (selectedCategory != null &&
                _categorySubcategories.containsKey(selectedCategory))
              const SizedBox(height: 16),

            // Account Dropdown
            DropdownButtonFormField<String>(
              value: selectedAccount,
              decoration: const InputDecoration(
                labelText: 'Account',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.grey[900],
              items: _accounts.map((String account) {
                return DropdownMenuItem<String>(
                  value: account,
                  child: Text(account),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAccount = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Date Picker
            Row(
              children: [
                const Text(
                  'Date: ',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    DateFormat.yMMMd().format(_selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _pickDate,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: Icon(
                  _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                label: const Text(
                  'SAVE',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome ? Colors.green : Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}