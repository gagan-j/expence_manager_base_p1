import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'new_expense_screen.dart';
import 'package:animations/animations.dart';
import 'new_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  String _selectedTimeRange = 'All';
  String _selectedType = 'All';

  FinancialSummary _summary = FinancialSummary(
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
  );

  List<ExpenseTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to transaction updates
    _transactionService.transactionsStream.listen((transactions) {
      setState(() {
        _applyFilters();
      });
    });

    // Listen to summary updates
    _transactionService.summaryStream.listen((summary) {
      setState(() {
        _summary = summary;
      });
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _transactionService.fetchTransactions();
      _applyFilters();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _applyFilters() {
    DateTime? startDate;
    final now = DateTime.now();

    // Apply date filter
    switch (_selectedTimeRange) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'All':
        startDate = null;
        break;
    }

    // Apply type filter
    String? typeFilter = _selectedType == 'All' ? null : _selectedType.toLowerCase();

    _transactions = _transactionService.getFilteredTransactions(
      type: typeFilter,
      startDate: startDate,
    );
  }

  _showDeleteConfirmation(BuildContext context, ExpenseTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _transactionService.deleteTransaction(transaction.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'keeping eye on money app',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##0.00').format(_summary.balance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.arrow_upward,
                          title: 'Income',
                          amount: _summary.totalIncome,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.arrow_downward,
                          title: 'Expenses',
                          amount: _summary.totalExpense,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimeRangeFilter('All'),
                          _buildTimeRangeFilter('Today'),
                          _buildTimeRangeFilter('Week'),
                          _buildTimeRangeFilter('Month'),
                          _buildTimeRangeFilter('Year'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    //icon: const Icon(Icons.filter_list, color: Colors.grey), its giving me error during emulation idk check once
                    onSelected: (value) {
                      setState(() {
                        _selectedType = value;
                        _applyFilters();
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'All',
                        child: Text('All Types'),
                      ),
                      const PopupMenuItem(
                        value: 'Income',
                        child: Text('Income Only'),
                      ),
                      const PopupMenuItem(
                        value: 'Expense',
                        child: Text('Expenses Only'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _selectedType,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),


            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                // Inside your home_screen.dart file, find the ElevatedButton in the "No transactions found" section


// Then replace the existing ElevatedButton with:
              OpenContainer(
                transitionType: ContainerTransitionType.fade,
                transitionDuration: const Duration(milliseconds: 500),
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                closedColor: Colors.deepPurple,
                closedBuilder: (context, openContainer) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Add Transaction', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
                openBuilder: (context, _) {
                  return const NewExpenseScreen();
                },
                onClosed: (value) {
                  if (value == true) {
                    _loadData(); // Call your existing _loadData method
                  }
                },
              ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final bool isExpense = transaction.type == 'expense';

                  // Group transactions by date
                  final bool showDateHeader = index == 0 ||
                      !_isSameDay(
                        _transactions[index].date,
                        _transactions[index - 1].date,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader) ...[
                        if (index > 0) const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _formatDate(transaction.date),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Card(
                        color: Colors.grey[900],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewExpenseScreen(
                                  transaction: transaction,
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Category icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(transaction.category).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(transaction.category),
                                    color: _getCategoryColor(transaction.category),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Transaction details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${transaction.category} • ${transaction.subcategory}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isExpense ? '-' : '+'} ₹${NumberFormat('#,##0.00').format(transaction.amount)}',
                                      style: TextStyle(
                                        color: isExpense ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => NewExpenseScreen(
                                                  transaction: transaction,
                                                ),
                                              ),
                                            ).then((_) => _loadData());
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () {
                                            _showDeleteConfirmation(context, transaction);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${NumberFormat('#,##0.00').format(amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilter(String range) {
    final isSelected = _selectedTimeRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = range;
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEE, MMM d, y').format(date);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'housing':
        return Icons.home;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.airplanemode_active;
      case 'salary':
        return Icons.payments;
      case 'investments':
        return Icons.trending_up;
      case 'gifts':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.indigo,
    ];

    // Use a hash of the category name to get a consistent color
    final hash = category.hashCode.abs() % colors.length;
    return colors[hash];
  }
}