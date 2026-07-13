class Payment {
  final String id;
  final String customerId;
  final DateTime date;
  final double amount;
  final String notes;
  final int? paymentMonth; // Month this payment is for (1-12)
  final int? paymentYear;  // Year this payment is for

  Payment({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    this.notes = '',
    this.paymentMonth,
    this.paymentYear,
  });

  // Factory constructor for creating from JSON map
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
      paymentMonth: json['paymentMonth'] as int?,
      paymentYear: json['paymentYear'] as int?,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'date': date.toIso8601String(),
      'amount': amount,
      'notes': notes,
      'paymentMonth': paymentMonth,
      'paymentYear': paymentYear,
    };
  }

  Payment copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    double? amount,
    String? notes,
    int? paymentMonth,
    int? paymentYear,
  }) {
    return Payment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      paymentMonth: paymentMonth ?? this.paymentMonth,
      paymentYear: paymentYear ?? this.paymentYear,
    );
  }
}
