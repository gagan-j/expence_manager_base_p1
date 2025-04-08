class Transaction {
  final String category;
  final String? subCategory;
  final String name;
  final double amount;
  final DateTime date;

  Transaction({
    required this.category,
    required this.subCategory,
    required this.name,
    required this.amount,
    required this.date,
  });
}
