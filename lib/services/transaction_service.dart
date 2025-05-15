import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../models/account.dart';

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });
}

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;

  TransactionService._internal();

  static Database? _database;
  List<ExpenseTransaction> allTransactions = [];
  List<Account> allAccounts = [];

  // Add streams for real-time updates
  final _transactionsStreamController = StreamController<List<ExpenseTransaction>>.broadcast();
  final _summaryStreamController = StreamController<FinancialSummary>.broadcast();
  final _accountsStreamController = StreamController<List<Account>>.broadcast();

  Stream<List<ExpenseTransaction>> get transactionsStream => _transactionsStreamController.stream;
  Stream<FinancialSummary> get summaryStream => _summaryStreamController.stream;
  Stream<List<Account>> get accountsStream => _accountsStreamController.stream;

  Future<void> initialize() async {
    await database;
    // Initial fetch to populate streams
    await fetchAccounts();
    await fetchTransactions();
    _updateSummary();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        date TEXT,
        category TEXT,
        subcategory TEXT,
        type TEXT,
        accountId INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        balance REAL,
        type TEXT,
        iconName TEXT
      )
    ''');

    // Add default accounts
    await db.insert('accounts', {
      'name': 'Cash',
      'balance': 1000.0,
      'type': 'cash',
      'iconName': 'money'
    });

    await db.insert('accounts', {
      'name': 'Bank Account',
      'balance': 5000.0,
      'type': 'bank',
      'iconName': 'account_balance'
    });
  }

  // Update streams when data changes
  void _updateTransactionsStream() {
    _transactionsStreamController.add(allTransactions);
  }

  void _updateAccountsStream() {
    _accountsStreamController.add(allAccounts);
  }

  void _updateSummary() async {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double availableBalance = 0.0;

    // Calculate income and expense totals from transactions
    for (var tx in allTransactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
      }
    }

    // Get the sum of all account balances for available balance
    final accounts = await fetchAccounts();
    availableBalance = accounts.fold(0.0, (sum, account) => sum + account.balance);

    final summary = FinancialSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: availableBalance,
    );

    _summaryStreamController.add(summary);
  }

  // Transaction Methods
  Future<int> addTransaction(ExpenseTransaction transaction) async {
    final db = await database;

    // First insert the transaction
    final transactionId = await db.insert('transactions', {
      'title': transaction.title,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'category': transaction.category,
      'subcategory': transaction.subcategory,
      'type': transaction.type,
      'accountId': transaction.accountId,
      'notes': transaction.notes,
    });

    // Then update the account balance
    if (transaction.accountId != null) {
      await updateAccountBalance(transaction.accountId!, transaction.amount, transaction.type);
    }

    // Update transaction with new ID
    transaction.id = transactionId;
    allTransactions.add(transaction);

    // Update streams
    _updateTransactionsStream();
    _updateSummary();

    return transactionId;
  }

  Future<void> updateTransaction(ExpenseTransaction transaction) async {
    final db = await database;

    // First get the old transaction to calculate balance difference
    final oldTransaction = await getTransactionById(transaction.id!);

    // Update the transaction
    await db.update(
      'transactions',
      {
        'title': transaction.title,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'category': transaction.category,
        'subcategory': transaction.subcategory,
        'type': transaction.type,
        'accountId': transaction.accountId,
        'notes': transaction.notes,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    // If account changed or amount changed, we need to update both accounts
    if (oldTransaction != null &&
        (oldTransaction.accountId != transaction.accountId ||
            oldTransaction.amount != transaction.amount ||
            oldTransaction.type != transaction.type)) {

      // Reverse the effect of the old transaction
      if (oldTransaction.accountId != null) {
        await updateAccountBalance(
            oldTransaction.accountId!,
            oldTransaction.amount,
            oldTransaction.type == 'expense' ? 'income' : 'expense' // Reverse the effect
        );
      }

      // Apply the new transaction
      if (transaction.accountId != null) {
        await updateAccountBalance(
            transaction.accountId!,
            transaction.amount,
            transaction.type
        );
      }
    }

    // Update in-memory list
    final index = allTransactions.indexWhere((tx) => tx.id == transaction.id);
    if (index != -1) {
      allTransactions[index] = transaction;
    }

    // Update streams
    _updateTransactionsStream();
    _updateSummary();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;

    // First get the transaction to reverse its effect
    final transaction = await getTransactionById(id);

    // Delete the transaction
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Reverse the effect on the account
    if (transaction != null && transaction.accountId != null) {
      await updateAccountBalance(
          transaction.accountId!,
          transaction.amount,
          transaction.type == 'expense' ? 'income' : 'expense' // Reverse the effect
      );
    }

    // Update in-memory list
    allTransactions.removeWhere((tx) => tx.id == id);

    // Update streams
    _updateTransactionsStream();
    _updateSummary();
  }

  Future<ExpenseTransaction?> getTransactionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExpenseTransaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ExpenseTransaction>> fetchTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    allTransactions = List.generate(maps.length, (i) {
      return ExpenseTransaction.fromMap(maps[i]);
    });

    // Update streams
    _updateTransactionsStream();
    _updateSummary();

    return allTransactions;
  }

  List<ExpenseTransaction> getFilteredTransactions({String? type, DateTime? startDate, DateTime? endDate}) {
    return allTransactions.where((tx) {
      bool typeMatch = type == null || tx.type == type;
      bool dateMatch = true;

      if (startDate != null) {
        dateMatch = dateMatch && !tx.date.isBefore(startDate);
      }

      if (endDate != null) {
        final nextDay = endDate.add(const Duration(days: 1));
        dateMatch = dateMatch && tx.date.isBefore(nextDay);
      }

      return typeMatch && dateMatch;
    }).toList();
  }

  // Account Methods
  Future<int> addAccount(Account account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());

    // Refresh accounts and transactions to update account info
    await fetchAccounts();
    await fetchTransactions();

    return id;
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );

    // Refresh accounts and transactions to update account info
    await fetchAccounts();
    await fetchTransactions();
  }

  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Refresh accounts and transactions to update account info
    await fetchAccounts();
    await fetchTransactions();
  }

  Future<List<Account>> fetchAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    allAccounts = List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });

    // Update accounts stream
    _updateAccountsStream();

    return allAccounts;
  }

  Future<Account?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  // Helper method to update account balance
  Future<void> updateAccountBalance(int accountId, double amount, String transactionType) async {
    final account = await getAccountById(accountId);
    if (account != null) {
      if (transactionType == 'expense') {
        account.balance -= amount;
      } else if (transactionType == 'income') {
        account.balance += amount;
      }
      await updateAccount(account);
    }
  }

  // Clean up when done
  void dispose() {
    _transactionsStreamController.close();
    _summaryStreamController.close();
    _accountsStreamController.close();
  }
}