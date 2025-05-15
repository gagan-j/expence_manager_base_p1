class Account {
  int? id;
  String name;
  double initialValue;
  String accountGroup;
  String? subgroup;

  Account({
    this.id,
    required this.name,
    required this.initialValue,
    required this.accountGroup,
    this.subgroup,
  });


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'initialValue': initialValue,
      'account_group': accountGroup,
      'subgroup': subgroup,
    };
  }
}
