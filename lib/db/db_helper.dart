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

    return openDatabase(path, version: 2, onCreate: (Database db, int version) async {
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
          account TEXT,
          type TEXT DEFAULT 'expense'
        )
      ''');
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        // Add the type column to the transactions table if upgrading from version 1
        await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "expense"');
      }
    });
  }

  // Methods for initial account setup
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
      print('Default accounts inserted');
    }
  }

  // Methods for Transactions
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    final db = await instance.db;
    final id = await db.insert('transactions', transaction.toMap());
    print('${transaction.type.toUpperCase()} transaction inserted with id: $id');
    return id;
  }

  Future<List<app_transaction.Transaction>> fetchTransactions() async {
    final db = await instance.db;
    final res = await db.query('transactions', orderBy: 'date DESC');
    print('Fetched ${res.length} transactions from DB');

    return res.isNotEmpty
        ? res.map((txn) => app_transaction.Transaction(
      id: txn['id'] as int?,
      category: txn['category'] as String,
      subCategory: txn['subCategory'] as String?,
      name: txn['name'] as String,
      amount: txn['amount'] as double,
      date: DateTime.parse(txn['date'] as String),
      description: txn['description'] as String?,
      account: txn['account'] as String,
      type: txn['type'] as String? ?? 'expense',
    )).toList()
        : [];
  }

  Future<void> deleteTransaction(int id) async {
    final db = await instance.db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    print('Transaction with id: $id deleted');
  }

  // Methods for Accounts
  Future<int> insertAccount(Account account) async {
    final db = await instance.db;
    final result = await db.insert('accounts', account.toMap());
    print('Account inserted with id: $result');
    return result;
  }

  Future<List<Account>> fetchAccounts() async {
    final db = await instance.db;
    final res = await db.query('accounts');
    print('Fetched ${res.length} accounts from DB');

    return res.isNotEmpty
        ? res.map((acc) => Account(
      id: acc['id'] as int?,
      name: acc['name'] as String,
      initialValue: acc['initialValue'] as double,
      accountGroup: acc['account_group'] as String,
      subgroup: acc['subgroup'] as String?,
    )).toList()
        : [];
  }

  Future<void> deleteAccount(int id) async {
    final db = await instance.db;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    print('Account with id: $id deleted');
  }

  Future<void> updateAccount(Account account) async {
    final db = await instance.db;
    if (account.id != null) {
      await db.update(
        'accounts',
        account.toMap(),
        where: 'id = ?',
        whereArgs: [account.id],
      );
      print('Account with id: ${account.id} updated');
    }
  }
}