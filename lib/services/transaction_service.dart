import 'dart:async';
import 'package:flutter/foundation.dart';
import '../db/db_helper.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netWorth;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netWorth
  });

  double get balance => totalIncome - totalExpense;
}

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;

  TransactionService._internal();

  List<ExpenseTransaction> allTransactions = [];

  // Stream controllers
  final _transactionsController = StreamController<List<ExpenseTransaction>>.broadcast();
  final _summaryController = StreamController<FinancialSummary>.broadcast();

  // Stream getters
  Stream<List<ExpenseTransaction>> get transactionsStream => _transactionsController.stream;
  Stream<FinancialSummary> get summaryStream => _summaryController.stream;

  // Initialize the service - added for main.dart
  Future<void> initialize() async {
    await fetchTransactions();
  }

  // Fetch all transactions
  Future<List<ExpenseTransaction>> fetchTransactions() async {
    try {
      final transactions = await DBHelper.instance.fetchTransactions();
      allTransactions = transactions;
      _transactionsController.add(allTransactions);

      // Update financial summary
      _updateSummary();

      return allTransactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Add a new transaction
  Future<bool> addTransaction(ExpenseTransaction transaction) async {
    try {
      await DBHelper.instance.insertTransaction(transaction);
      await fetchTransactions();
      return true;
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  // Update an existing transaction
  Future<bool> updateTransaction(ExpenseTransaction transaction) async {
    try {
      await DBHelper.instance.updateTransaction(transaction);
      await fetchTransactions();
      return true;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await DBHelper.instance.deleteTransaction(id);
      await fetchTransactions();
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Get filtered transactions (weekly or monthly)
  List<ExpenseTransaction> getFilteredTransactions({required bool weekly}) {
    if (allTransactions.isEmpty) return [];

    final now = DateTime.now();
    final startDate = weekly
        ? DateTime(now.year, now.month, now.day - now.weekday + 1) // Start of this week (Monday)
        : DateTime(now.year, now.month, 1); // Start of this month

    return allTransactions.where((tx) =>
    tx.date.isAfter(startDate) ||
        (tx.date.day == startDate.day &&
            tx.date.month == startDate.month &&
            tx.date.year == startDate.year)
    ).toList();
  }

  // Calculate and update financial summary
  void _updateSummary() {
    double income = 0.0;
    double expense = 0.0;
    double netWorth = 0.0;

    for (final tx in allTransactions) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    netWorth = income - expense;

    final summary = FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      netWorth: netWorth,
    );

    _summaryController.add(summary);
  }

  // Added for stats_screen.dart
  Future<List<Account>> fetchAccounts() async {
    return await DBHelper.instance.fetchAccounts();
  }

  void dispose() {
    _transactionsController.close();
    _summaryController.close();
  }
}