import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../db/db_helper.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> accountOptions = [];
  bool _isLoading = true;
  bool _isIncome = false; // Track if this is an income or expense

  // Different category maps for expense and income
  final Map<String, List<String>> expenseCategoryMap = {
    'Food': ['KFC', 'Snacks', 'Lunch', 'Dinner', 'Breakfast', 'Burger King'],
    'Travel': ['Bus', 'Cab', 'Train'],
    'Phone Recharge': ['Airtel', 'Jio'],
    'Others': [],
  };

  final Map<String, List<String>> incomeCategoryMap = {
    'Salary': ['Regular', 'Bonus', 'Overtime'],
    'Investments': ['Dividends', 'Interest', 'Capital Gains'],
    'Gifts': ['Birthday', 'Anniversary', 'Holiday'],
    'Others': [],
  };

  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedAccount;
  bool _isSaving = false;

  // Get the appropriate category map based on transaction type
  Map<String, List<String>> get categoryMap =>
      _isIncome ? incomeCategoryMap : expenseCategoryMap;

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
      final accounts = await DBHelper.instance.fetchAccounts();
      if (mounted) {
        setState(() {
          accountOptions = accounts.map((acc) => acc.name).toList();

          // Make sure we have at least default options if DB is empty
          if (accountOptions.isEmpty) {
            accountOptions = ['Cash', 'Bank Account'];
          }

          if (accountOptions.isNotEmpty && selectedAccount == null) {
            selectedAccount = accountOptions.first;
          }
          _isLoading = false;
        });
      }
      print('Loaded ${accountOptions.length} accounts for dropdown');
    } catch (e) {
      print('Error loading accounts: $e');
      if (mounted) {
        setState(() {
          accountOptions = ['Cash', 'Bank Account']; // Fallback
          selectedAccount = accountOptions.first;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _categoryController = TextEditingController();
        return AlertDialog(
          title: Text("Add New ${_isIncome ? 'Income' : 'Expense'} Category"),
          backgroundColor: Colors.black,
          titleTextStyle: const TextStyle(color: Colors.white),
          content: TextField(
            controller: _categoryController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Category Name",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String newCategory = _categoryController.text.trim();
                if (newCategory.isNotEmpty && !categoryMap.containsKey(newCategory)) {
                  setState(() {
                    categoryMap[newCategory] = [];
                    selectedCategory = newCategory;
                    selectedSubcategory = null;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addNewSubcategory() {
    if (selectedCategory == null) return;
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _subCategoryController = TextEditingController();
        return AlertDialog(
          title: const Text("Add New Subcategory"),
          backgroundColor: Colors.black,
          titleTextStyle: const TextStyle(color: Colors.white),
          content: TextField(
            controller: _subCategoryController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Subcategory Name",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String newSubcategory = _subCategoryController.text.trim();
                if (newSubcategory.isNotEmpty &&
                    !categoryMap[selectedCategory]!.contains(newSubcategory)) {
                  setState(() {
                    categoryMap[selectedCategory]!.add(newSubcategory);
                    selectedSubcategory = newSubcategory;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Save transaction method - works for both expense and income
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

    try {
      // First pop the screen, then save in background
      Navigator.pop(context, true);

      // Now save to DB (after navigation)
      DBHelper.instance.insertTransaction(newTransaction);
      print('${_isIncome ? "Income" : "Expense"} transaction saved successfully');
    } catch (e) {
      print('Error in save process: $e');
      // Cannot show snackbar as we've already popped
    }
  }

  // Toggle between income and expense modes
  void _toggleTransactionType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      // Reset category and subcategory when switching modes
      selectedCategory = null;
      selectedSubcategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Color themes based on transaction type
    final Color themeColor = _isIncome ? Colors.green.shade300 : Colors.red.shade300;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Add Income' : 'Add Expense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle buttons for Income/Expense
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleTransactionType(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isIncome ? Colors.red.shade300 : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8)
                        ),
                      ),
                    ),
                    child: const Text('EXPENSE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleTransactionType(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isIncome ? Colors.green.shade300 : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8)
                        ),
                      ),
                    ),
                    child: const Text('INCOME', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Date: ${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} '
                      'Time: ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Amount (₹)",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _isIncome ? "Income Source" : "Expense Name",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: [
                      ...categoryMap.keys.map(
                            (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: "AddCategory",
                        child: Text("+ Add Category"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == "AddCategory") {
                        _addNewCategory();
                      } else {
                        setState(() {
                          selectedCategory = value;
                          selectedSubcategory = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Category",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: themeColor),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedCategory != null && categoryMap[selectedCategory]!.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedSubcategory,
                      items: [
                        ...categoryMap[selectedCategory]!.map(
                              (sub) => DropdownMenuItem(
                            value: sub,
                            child: Text(sub),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: "AddSubcategory",
                          child: Text("+ Add Subcategory"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == "AddSubcategory") {
                          _addNewSubcategory();
                        } else {
                          setState(() {
                            selectedSubcategory = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Subcategory",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: themeColor),
                        ),
                      ),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAccount,
              items: accountOptions.map((acc) {
                return DropdownMenuItem(
                  value: acc,
                  child: Text(acc),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAccount = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Account",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
              )
                  : Text("Save ${_isIncome ? 'Income' : 'Expense'}"),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings - add this if needed
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}