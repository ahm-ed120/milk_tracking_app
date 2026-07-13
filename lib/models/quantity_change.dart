class QuantityChange {
  final String id;
  final String customerId;
  final DateTime effectiveDate;
  final double quantity;

  QuantityChange({
    required this.id,
    required this.customerId,
    required this.effectiveDate,
    required this.quantity,
  });

  factory QuantityChange.fromJson(Map<String, dynamic> json) {
    return QuantityChange(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'effectiveDate': DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day).toIso8601String(),
      'quantity': quantity,
    };
  }

  QuantityChange copyWith({
    String? id,
    String? customerId,
    DateTime? effectiveDate,
    double? quantity,
  }) {
    return QuantityChange(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      quantity: quantity ?? this.quantity,
    );
  }
}
