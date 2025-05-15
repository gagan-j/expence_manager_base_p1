// Note: Renamed from Transaction to ExpenseTransaction to avoid naming conflicts
class ExpenseTransaction {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final String? subCategory;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String? description;
  final String account;

  ExpenseTransaction({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.date,
    required this.type,
    this.description,
    required this.account,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'subCategory': subCategory,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'account': account,
    };
  }

  static ExpenseTransaction fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      category: map['category'],
      subCategory: map['subCategory'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      description: map['description'],
      account: map['account'],
    );
  }

  ExpenseTransaction copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    String? subCategory,
    DateTime? date,
    String? type,
    String? description,
    String? account,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      account: account ?? this.account,
    );
  }
}