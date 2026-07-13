class RateChange {
  final String id;
  final String customerId;
  final DateTime effectiveDate;
  final double rate;

  RateChange({
    required this.id,
    required this.customerId,
    required this.effectiveDate,
    required this.rate,
  });

  factory RateChange.fromJson(Map<String, dynamic> json) {
    return RateChange(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'effectiveDate': DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day).toIso8601String(),
      'rate': rate,
    };
  }

  RateChange copyWith({
    String? id,
    String? customerId,
    DateTime? effectiveDate,
    double? rate,
  }) {
    return RateChange(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      rate: rate ?? this.rate,
    );
  }
}
