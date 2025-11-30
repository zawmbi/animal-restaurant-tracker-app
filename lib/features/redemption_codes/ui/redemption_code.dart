class RedemptionCode {
  final String code;
  final bool isValid;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String gift;
  final bool isMemento; // true if gift is a memento, false if facility or other

  RedemptionCode({
    required this.code,
    required this.isValid,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.gift,
    required this.isMemento,
  });

  bool get isCurrentlyValid {
    final now = DateTime.now();
    return isValid && now.isAfter(startDate) && now.isBefore(endDate);
  }
}
