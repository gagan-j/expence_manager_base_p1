class ExpenseTransaction {
  int? id;
  String title;
  double amount;
  DateTime date;
  String category;
  String subcategory;
  String type; // 'income' or 'expense'
  int? accountId; // Add this field
  String? notes;

  ExpenseTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.subcategory,
    required this.type,
    this.accountId, // Add this field
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'subcategory': subcategory,
      'type': type,
      'accountId': accountId, // Add this field
      'notes': notes,
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      subcategory: map['subcategory'],
      type: map['type'],
      accountId: map['accountId'], // Add this field
      notes: map['notes'],
    );
  }
}