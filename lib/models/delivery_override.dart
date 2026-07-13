class DeliveryOverride {
  final String id;
  final String customerId;
  final DateTime date;
  final double deliveredQuantity;
  final double rate; // Rate locked at the time of delivery

  DeliveryOverride({
    required this.id,
    required this.customerId,
    required this.date,
    required this.deliveredQuantity,
    required this.rate,
  });

  // Factory constructor for creating from JSON map
  factory DeliveryOverride.fromJson(Map<String, dynamic> json) {
    return DeliveryOverride(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      date: DateTime.parse(json['date'] as String),
      deliveredQuantity: (json['deliveredQuantity'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'deliveredQuantity': deliveredQuantity,
      'rate': rate,
    };
  }

  DeliveryOverride copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    double? deliveredQuantity,
    double? rate,
  }) {
    return DeliveryOverride(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      rate: rate ?? this.rate,
    );
  }
}
