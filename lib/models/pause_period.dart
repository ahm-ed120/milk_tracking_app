class PausePeriod {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;

  PausePeriod({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  // Check if a specific date falls within this pause period
  bool containsDate(DateTime date) {
    // Standardize dates to remove time parts
    final target = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    
    if (target.isBefore(start)) {
      return false;
    }

    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return !target.isAfter(end);
    }

    // Ongoing pause (endDate is null) and target is on or after start
    return true;
  }

  // Factory constructor for creating from JSON map
  factory PausePeriod.fromJson(Map<String, dynamic> json) {
    return PausePeriod(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  PausePeriod copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PausePeriod(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
