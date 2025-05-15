class Account {
  int? id;
  String name;
  double balance;
  String type; // cash, bank, credit card, etc.
  String? iconName;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'iconName': iconName,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      type: map['type'],
      iconName: map['iconName'],
    );
  }
}