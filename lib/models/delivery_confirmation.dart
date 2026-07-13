class DeliveryConfirmation {
  final String id;
  final String customerId;
  final DateTime date;
  final bool isDelivered;
  final DateTime? confirmedAt; // When was it marked as delivered

  DeliveryConfirmation({
    required this.id,
    required this.customerId,
    required this.date,
    required this.isDelivered,
    this.confirmedAt,
  });

  factory DeliveryConfirmation.fromJson(Map<String, dynamic> json) {
    return DeliveryConfirmation(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      date: DateTime.parse(json['date'] as String),
      isDelivered: json['isDelivered'] as bool? ?? false,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'isDelivered': isDelivered,
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  DeliveryConfirmation copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    bool? isDelivered,
    DateTime? confirmedAt,
  }) {
    return DeliveryConfirmation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      isDelivered: isDelivered ?? this.isDelivered,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
