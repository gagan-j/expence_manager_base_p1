import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:testing_exp_1/models/account.dart';
import 'package:testing_exp_1/models/transaction.dart' as app_transaction;

class DBHelper {
  static Database? _db;

  // Singleton pattern: Access instance via DBHelper.instance
  static final DBHelper instance = DBHelper._();

  DBHelper._(); // Private constructor to restrict instantiation

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDB();
      return _db!;
    }
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_manager.db');

    return openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          initialValue REAL,
          account_group TEXT,
          subgroup TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT,
          subCategory TEXT,
          name TEXT,
          amount REAL,
          date TEXT,
          description TEXT,
          account TEXT
        )
      ''');
    });
  }

  Future<void> insertDefaultAccounts() async {
    final db = await instance.db;

    // Check if default accounts exist
    final accounts = await db.query('accounts');
    if (accounts.isEmpty) {
      final defaultAccounts = [
        Account(name: 'Cash', initialValue: 0, accountGroup: 'Assets'),
        Account(name: 'Bank Account', initialValue: 0, accountGroup: 'Assets'),
      ];

      for (var account in defaultAccounts) {
        await db.insert('accounts', account.toMap());
      }
    }
  }

  Future<void> insertTransaction(app_transaction.Transaction transaction) async {
    final db = await instance.db;

    final accountQuery = await db.query('accounts', where: 'name = ?', whereArgs: [transaction.account]);
    if (accountQuery.isNotEmpty) {
      final accountId = accountQuery.first['id'] as int;  // Cast the ID to int
      final transactionMap = transaction.toMap();
      transactionMap['account_id'] = accountId;
      await db.insert('transactions', transactionMap);
    }
  }

  Future<List<app_transaction.Transaction>> fetchTransactions() async {
    final db = await instance.db;
    final res = await db.query('transactions');

    return res.isNotEmpty
        ? res.map((txn) => app_transaction.Transaction(
      category: txn['category'] as String, // Cast 'category' to String
      subCategory: txn['subCategory'] as String?, // Cast to String? for nullable field
      name: txn['name'] as String, // Cast 'name' to String
      amount: txn['amount'] as double, // Cast 'amount' to double
      date: DateTime.parse(txn['date'] as String), // Cast 'date' to String and parse it
      description: txn['description'] as String?, // Cast 'description' to String?
      account: txn['account'] as String, // Cast 'account' to String
    )).toList()
        : [];
  }

  Future<void> deleteTransaction(int id) async {
    final db = await instance.db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
