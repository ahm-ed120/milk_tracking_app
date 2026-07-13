import 'pause_period.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double defaultQuantity;
  final double rate;
  final DateTime joinDate;
  final bool isActive;
  final List<PausePeriod> pausePeriods;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.defaultQuantity,
    required this.rate,
    required this.joinDate,
    this.isActive = true,
    this.pausePeriods = const [],
  });

  // Check if customer is paused on a specific date
  bool isPausedOn(DateTime date) {
    for (final period in pausePeriods) {
      if (period.containsDate(date)) {
        return true;
      }
    }
    return false;
  }

  // Check if customer has joined yet on a specific date
  bool hasJoinedOn(DateTime date) {
    // Normalize date to ignore time components
    final target = DateTime(date.year, date.month, date.day);
    final join = DateTime(joinDate.year, joinDate.month, joinDate.day);
    return !target.isBefore(join);
  }

  // Factory constructor for creating from JSON map
  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawPause = json['pausePeriods'] as List<dynamic>? ?? [];
    final pauses = rawPause.map((item) => PausePeriod.fromJson(item as Map<String, dynamic>)).toList();

    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      defaultQuantity: (json['defaultQuantity'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      joinDate: DateTime.parse(json['joinDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      pausePeriods: pauses,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'defaultQuantity': defaultQuantity,
      'rate': rate,
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive,
      'pausePeriods': pausePeriods.map((p) => p.toJson()).toList(),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? defaultQuantity,
    double? rate,
    DateTime? joinDate,
    bool? isActive,
    List<PausePeriod>? pausePeriods,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      rate: rate ?? this.rate,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      pausePeriods: pausePeriods ?? this.pausePeriods,
    );
  }
}
