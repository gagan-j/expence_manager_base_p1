class Account {
  final int? id;
  final String name;
  final double balance;
  final String? description;

  Account({
    this.id,
    required this.name,
    required this.balance,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'balance': balance,
      'description': description,
    };
  }

  static Account fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      description: map['description'],
    );
  }

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    String? description,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      description: description ?? this.description,
    );
  }
}