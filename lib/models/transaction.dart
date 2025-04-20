class Transaction {
  final String category;
  final String? subCategory;
  final String name;
  final double amount;
  final DateTime date;
  final String? description;
  final String account;

  Transaction({
    required this.category,
    this.subCategory,
    required this.name,
    required this.amount,
    required this.date,
    this.description,
    required this.account,
  });
}
