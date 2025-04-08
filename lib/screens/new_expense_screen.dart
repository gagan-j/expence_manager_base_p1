import 'package:flutter/material.dart';
import '../models/transaction.dart';

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

  //testing purpos data
  Map<String, List<String>> categoryMap = {
    'Food': ['KFC', 'Snacks', 'Lunch', 'Dinner', 'Breakfast', 'Burger King'],
    'Travel': ['Bus', 'Cab', 'Train'],
    'Phone Recharge': ['Airtel', 'Jio'],
    'Others': [],
  };

  String? selectedCategory;
  String? selectedSubcategory;

  List<String> accountOptions = ['Cash', 'Bank Account'];
  String? selectedAccount;

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
          title: const Text("Add New Category"),
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
                if (newSubcategory.isNotEmpty && !categoryMap[selectedCategory]!.contains(newSubcategory)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Expense"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
              ),
            ),
            const SizedBox(height: 16),

            // Expense Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Expense Name",
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
                    decoration: const InputDecoration(labelText: "Category"),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedCategory != null)
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
                      decoration: const InputDecoration(labelText: "Subcategory"),
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
              decoration: const InputDecoration(labelText: "Account"),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
              ),
              maxLines: 2,
            ) ,
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_amountController.text.isEmpty || selectedCategory == null || selectedAccount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all the required fields."),
                    ),
                  );
                  return;
                }

                final newTransaction = Transaction(
                  category: selectedCategory!,
                  subCategory: selectedSubcategory,
                  name: _nameController.text,
                  amount: double.tryParse(_amountController.text) ?? 0,
                  date: _selectedDateTime,
                );

                Navigator.pop(context, newTransaction);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text("Save Expense"),
            ),
          ],
        ),
      ),
    );
  }
}
