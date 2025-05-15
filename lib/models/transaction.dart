class Transaction {
  int? id; // Optional 'id' field
  final String category;
  final String? subCategory;
  final String name;
  final double amount;
  final DateTime date;
  final String? description;
  final String account;
  final String type; // New field: 'expense' or 'income'

  Transaction({
    this.id, // 'id' is optional
    required this.category,
    this.subCategory,
    required this.name,
    required this.amount,
    required this.date,
    this.description,
    required this.account,
    this.type = 'expense', // Default to expense
  });

  // Convert Transaction to Map for inserting into the database
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include 'id' if it exists
      'category': category,
      'subCategory': subCategory,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'account': account,
      'type': type, // Include the type
    };
  }

  // Convert Map to Transaction object
  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?, // Fetch 'id' from the map if available
      category: map['category'] as String,
      subCategory: map['subCategory'] as String?,
      name: map['name'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      account: map['account'] as String,
      type: map['type'] as String? ?? 'expense', // Default to expense if not specified
    );
  }
}