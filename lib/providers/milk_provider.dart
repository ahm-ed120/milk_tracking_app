import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/delivery_confirmation.dart';
import '../models/delivery_override.dart';
import '../models/payment.dart';
import '../models/pause_period.dart';
import '../models/quantity_change.dart';
import '../models/rate_change.dart';
import '../services/database_service.dart';

class MilkProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Customer> _customers = [];
  List<DeliveryOverride> _overrides = [];
  List<Payment> _payments = [];
  List<DeliveryConfirmation> _confirmations = [];
  List<RateChange> _rateChanges = [];
  List<QuantityChange> _quantityChanges = [];
  bool _isLoading = true;

  // Getters
  List<Customer> get customers => _customers;
  List<DeliveryOverride> get overrides => _overrides;
  List<Payment> get payments => _payments;
  List<DeliveryConfirmation> get confirmations => _confirmations;
  List<RateChange> get rateChanges => _rateChanges;
  List<QuantityChange> get quantityChanges => _quantityChanges;
  bool get isLoading => _isLoading;

  // Initialize and load database
  MilkProvider() {
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    _isLoading = true;
    notifyListeners();

    final data = await _dbService.loadData();
    _customers = List<Customer>.from(data['customers'] as List);
    _overrides = List<DeliveryOverride>.from(data['overrides'] as List);
    _payments = List<Payment>.from(data['payments'] as List);
    _confirmations = List<DeliveryConfirmation>.from(data['confirmations'] as List);
    _rateChanges = List<RateChange>.from(data['rateChanges'] as List);
    _quantityChanges = List<QuantityChange>.from(data['quantityChanges'] as List);

    _ensureRateHistoryInitialized();
    _ensureQuantityHistoryInitialized();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveDatabase() async {
    await _dbService.saveData(
      customers: _customers,
      overrides: _overrides,
      payments: _payments,
      confirmations: _confirmations,
      rateChanges: _rateChanges,
      quantityChanges: _quantityChanges,
    );
  }

  void _ensureRateHistoryInitialized() {
    for (final customer in _customers) {
      final normalizedJoinDate = _normalizeDate(customer.joinDate);
      final customerRateChanges = _rateChanges
          .where((rateChange) => rateChange.customerId == customer.id)
          .toList();

      if (customerRateChanges.isEmpty) {
        _rateChanges.add(RateChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customer.id,
          effectiveDate: normalizedJoinDate,
          rate: customer.rate,
        ));
        continue;
      }

      final earliestRateChange = customerRateChanges.reduce((a, b) {
        return a.effectiveDate.isBefore(b.effectiveDate) ? a : b;
      });

      if (earliestRateChange.effectiveDate.isAfter(normalizedJoinDate)) {
        _rateChanges.add(RateChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customer.id,
          effectiveDate: normalizedJoinDate,
          rate: earliestRateChange.rate,
        ));
      }
    }
  }

  void _ensureQuantityHistoryInitialized() {
    for (final customer in _customers) {
      final normalizedJoinDate = _normalizeDate(customer.joinDate);
      final customerQuantityChanges = _quantityChanges
          .where((quantityChange) => quantityChange.customerId == customer.id)
          .toList();

      if (customerQuantityChanges.isEmpty) {
        _quantityChanges.add(QuantityChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customer.id,
          effectiveDate: normalizedJoinDate,
          quantity: customer.defaultQuantity,
        ));
        continue;
      }

      final earliestQuantityChange = customerQuantityChanges.reduce((a, b) {
        return a.effectiveDate.isBefore(b.effectiveDate) ? a : b;
      });

      if (earliestQuantityChange.effectiveDate.isAfter(normalizedJoinDate)) {
        _quantityChanges.add(QuantityChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customer.id,
          effectiveDate: normalizedJoinDate,
          quantity: earliestQuantityChange.quantity,
        ));
      }
    }
  }

  // --- HELPERS ---
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // --- CORE LOGIC ENGINE (4-Step Priority Quantity & Rate Resolution) ---

  // Priority 1: Join Date guard (0L if date < joinDate)
  // Priority 2: Pause Periods guard (0L if paused on date)
  // Priority 3: Manual overrides (custom quantity if exists)
  // Priority 4: Quantity changes history (effective quantity on that date)
  // Priority 5: Default fallback (fixed quantity)
  double getQuantityForDate(Customer customer, DateTime date) {
    final normDate = _normalizeDate(date);
    
    // Step 1: Join Date Check
    if (!customer.hasJoinedOn(normDate)) {
      return 0.0;
    }

    // Step 2: Pause Period Check
    if (customer.isPausedOn(normDate)) {
      return 0.0;
    }

    // Step 3: Manual Override Check
    final override = _findOverride(customer.id, normDate);
    if (override != null) {
      return override.deliveredQuantity;
    }

    // Step 4: Quantity Changes History
    final quantityChange = _findQuantityChange(customer.id, normDate);
    if (quantityChange != null) {
      return quantityChange.quantity;
    }

    // Step 5: Default Fixed Quantity
    return customer.defaultQuantity;
  }

  double getRateForDate(Customer customer, DateTime date) {
    final normDate = _normalizeDate(date);

    // If overridden, use the rate locked at the time of delivery
    final override = _findOverride(customer.id, normDate);
    if (override != null) {
      return override.rate;
    }

    // Otherwise, use the rate that was effective on that date
    final rateChange = _findRateChange(customer.id, normDate);
    if (rateChange != null) {
      return rateChange.rate;
    }

    // Fall back to current customer rate if no history is found
    return customer.rate;
  }

  RateChange? _findRateChange(String customerId, DateTime date) {
    final normDate = _normalizeDate(date);
    RateChange? latest;

    for (final change in _rateChanges) {
      if (change.customerId != customerId) continue;
      if (change.effectiveDate.isAfter(normDate)) continue;
      if (latest == null || change.effectiveDate.isAfter(latest.effectiveDate)) {
        latest = change;
      }
    }

    return latest;
  }

  QuantityChange? _findQuantityChange(String customerId, DateTime date) {
    final normDate = _normalizeDate(date);
    QuantityChange? latest;

    for (final change in _quantityChanges) {
      if (change.customerId != customerId) continue;
      if (change.effectiveDate.isAfter(normDate)) continue;
      if (latest == null || change.effectiveDate.isAfter(latest.effectiveDate)) {
        latest = change;
      }
    }

    return latest;
  }

  DeliveryOverride? _findOverride(String customerId, DateTime date) {
    final normDate = _normalizeDate(date);
    for (final o in _overrides) {
      if (o.customerId == customerId && isSameDay(o.date, normDate)) {
        return o;
      }
    }
    return null;
  }

  // --- CUSTOMER MANAGEMENT ---

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String address,
    required double defaultQuantity,
    required double rate,
    required DateTime joinDate,
  }) async {
    final normalizedJoinDate = _normalizeDate(joinDate);
    final newCustomer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
      address: address,
      defaultQuantity: defaultQuantity,
      rate: rate,
      joinDate: normalizedJoinDate,
      isActive: true,
      pausePeriods: [],
    );

    _customers.add(newCustomer);
    _rateChanges.add(RateChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: newCustomer.id,
      effectiveDate: normalizedJoinDate,
      rate: rate,
    ));
    _quantityChanges.add(QuantityChange(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: newCustomer.id,
      effectiveDate: normalizedJoinDate,
      quantity: defaultQuantity,
    ));

    notifyListeners();
    await _saveDatabase();
  }

  Future<void> updateCustomer(Customer updatedCustomer) async {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      final existingCustomer = _customers[index];
      final updated = updatedCustomer;
      final newRate = updated.rate;
      final newQuantity = updated.defaultQuantity;

      // Handle Rate Changes
      if (newRate != existingCustomer.rate) {
        final effectiveDate = _normalizeDate(DateTime.now());
        final normalizedJoinDate = _normalizeDate(existingCustomer.joinDate);
        final customerRateChanges = _rateChanges
            .where((rateChange) => rateChange.customerId == updatedCustomer.id)
            .toList();

        if (customerRateChanges.isEmpty) {
          _rateChanges.add(RateChange(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            customerId: updatedCustomer.id,
            effectiveDate: normalizedJoinDate,
            rate: existingCustomer.rate,
          ));
        } else {
          final earliestRateChange = customerRateChanges.reduce((a, b) {
            return a.effectiveDate.isBefore(b.effectiveDate) ? a : b;
          });

          if (earliestRateChange.effectiveDate.isAfter(normalizedJoinDate)) {
            _rateChanges.add(RateChange(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              customerId: updatedCustomer.id,
              effectiveDate: normalizedJoinDate,
              rate: earliestRateChange.rate,
            ));
          }
        }

        final existingRateIndex = _rateChanges.indexWhere(
          (rateChange) =>
              rateChange.customerId == updatedCustomer.id &&
              isSameDay(rateChange.effectiveDate, effectiveDate),
        );

        if (existingRateIndex != -1) {
          _rateChanges[existingRateIndex] = _rateChanges[existingRateIndex].copyWith(rate: newRate);
        } else {
          _rateChanges.add(RateChange(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            customerId: updatedCustomer.id,
            effectiveDate: effectiveDate,
            rate: newRate,
          ));
        }
      }

      // Handle Quantity Changes
      if (newQuantity != existingCustomer.defaultQuantity) {
        final effectiveDate = _normalizeDate(DateTime.now());
        final normalizedJoinDate = _normalizeDate(existingCustomer.joinDate);
        final customerQuantityChanges = _quantityChanges
            .where((quantityChange) => quantityChange.customerId == updatedCustomer.id)
            .toList();

        if (customerQuantityChanges.isEmpty) {
          _quantityChanges.add(QuantityChange(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            customerId: updatedCustomer.id,
            effectiveDate: normalizedJoinDate,
            quantity: existingCustomer.defaultQuantity,
          ));
        } else {
          final earliestQuantityChange = customerQuantityChanges.reduce((a, b) {
            return a.effectiveDate.isBefore(b.effectiveDate) ? a : b;
          });

          if (earliestQuantityChange.effectiveDate.isAfter(normalizedJoinDate)) {
            _quantityChanges.add(QuantityChange(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              customerId: updatedCustomer.id,
              effectiveDate: normalizedJoinDate,
              quantity: earliestQuantityChange.quantity,
            ));
          }
        }

        final existingQuantityIndex = _quantityChanges.indexWhere(
          (quantityChange) =>
              quantityChange.customerId == updatedCustomer.id &&
              isSameDay(quantityChange.effectiveDate, effectiveDate),
        );

        if (existingQuantityIndex != -1) {
          _quantityChanges[existingQuantityIndex] = _quantityChanges[existingQuantityIndex].copyWith(quantity: newQuantity);
        } else {
          _quantityChanges.add(QuantityChange(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            customerId: updatedCustomer.id,
            effectiveDate: effectiveDate,
            quantity: newQuantity,
          ));
        }
      }

      _customers[index] = updated;
      notifyListeners();
      await _saveDatabase();
    }
  }

  Future<void> deleteCustomer(String id) async {
    _customers.removeWhere((c) => c.id == id);
    _overrides.removeWhere((o) => o.customerId == id);
    _payments.removeWhere((p) => p.customerId == id);
    _confirmations.removeWhere((c) => c.customerId == id);
    _rateChanges.removeWhere((r) => r.customerId == id);
    _quantityChanges.removeWhere((q) => q.customerId == id);
    notifyListeners();
    await _saveDatabase();
  }

  // --- PAUSE PERIODS MANAGEMENT ---

  Future<void> pauseCustomer(String customerId, DateTime startDate) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final customer = _customers[index];
    final normStart = _normalizeDate(startDate);

    // Create a new PausePeriod
    final newPause = PausePeriod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: normStart,
      endDate: null, // Open ended
    );

    // Append to customer's pause list
    final updatedPauses = List<PausePeriod>.from(customer.pausePeriods)..add(newPause);
    _customers[index] = customer.copyWith(pausePeriods: updatedPauses);

    notifyListeners();
    await _saveDatabase();
  }

  Future<void> resumeCustomer(String customerId, DateTime resumeDate) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final customer = _customers[index];
    final normResume = _normalizeDate(resumeDate);

    // Find the active pause period (where endDate is null)
    final activePauseIndex = customer.pausePeriods.indexWhere((p) => p.endDate == null);
    if (activePauseIndex == -1) return;

    final activePause = customer.pausePeriods[activePauseIndex];
    
    // The pause period ends the day BEFORE they resume milk
    final endDate = normResume.subtract(const Duration(days: 1));
    
    // Guard: if endDate is before startDate, just remove this pause period
    List<PausePeriod> updatedPauses = List<PausePeriod>.from(customer.pausePeriods);
    if (endDate.isBefore(activePause.startDate)) {
      updatedPauses.removeAt(activePauseIndex);
    } else {
      updatedPauses[activePauseIndex] = activePause.copyWith(endDate: endDate);
    }

    _customers[index] = customer.copyWith(pausePeriods: updatedPauses);
    notifyListeners();
    await _saveDatabase();
  }

  Future<void> deletePausePeriod(String customerId, String pauseId) async {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    final customer = _customers[index];
    final updatedPauses = List<PausePeriod>.from(customer.pausePeriods)
      ..removeWhere((p) => p.id == pauseId);

    _customers[index] = customer.copyWith(pausePeriods: updatedPauses);
    notifyListeners();
    await _saveDatabase();
  }

  // --- MANUAL OVERRIDES MANAGEMENT (Edit Daily Milk Quantity) ---

  Future<void> recordOverride(String customerId, DateTime date, double quantity) async {
    final normDate = _normalizeDate(date);
    final customerIndex = _customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return;
    
    final customer = _customers[customerIndex];
    final existingIndex = _overrides.indexWhere(
      (o) => o.customerId == customerId && isSameDay(o.date, normDate),
    );

    final standardRate = _findRateChange(customer.id, normDate)?.rate ?? customer.rate;

    if (quantity == customer.defaultQuantity) {
      if (existingIndex != -1) {
        // Only remove the override if its rate matches the standard rate for that date.
        final existingOverride = _overrides[existingIndex];
        if (existingOverride.rate == standardRate) {
          _overrides.removeAt(existingIndex);
        } else {
          _overrides[existingIndex] = existingOverride.copyWith(
            deliveredQuantity: quantity,
          );
        }
      }
    } else {
      if (existingIndex != -1) {
        // Update existing override, locking the current delivery rate.
        _overrides[existingIndex] = _overrides[existingIndex].copyWith(
          deliveredQuantity: quantity,
          rate: customer.rate,
        );
      } else {
        // Create new override
        final newOverride = DeliveryOverride(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: customerId,
          date: normDate,
          deliveredQuantity: quantity,
          rate: customer.rate,
        );
        _overrides.add(newOverride);
      }
    }

    notifyListeners();
    await _saveDatabase();
  }

  // --- PAYMENTS MANAGEMENT ---

  Future<void> addPayment({
    required String customerId,
    required double amount,
    required DateTime date,
    String notes = '',
    int? paymentMonth,
    int? paymentYear,
  }) async {
    final newPayment = Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      date: date,
      amount: amount,
      notes: notes,
      paymentMonth: paymentMonth,
      paymentYear: paymentYear,
    );

    _payments.add(newPayment);
    notifyListeners();
    await _saveDatabase();
  }

  Future<void> deletePayment(String paymentId) async {
    _payments.removeWhere((p) => p.id == paymentId);
    notifyListeners();
    await _saveDatabase();
  }

  List<Payment> getPaymentsForCustomer(String customerId) {
    return _payments.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  // --- CALCULATIONS LEDGER ---

  // Gets list of active days to compute in a month
  List<DateTime> _getDaysInMonth(int year, int month) {
    final daysCount = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();

    int endDay = daysCount;
    // If it's the current month, only calculate up to today
    if (year == now.year && month == now.month) {
      endDay = now.day;
    } else if (year > now.year || (year == now.year && month > now.month)) {
      // Future month
      return [];
    }

    return List.generate(endDay, (i) => DateTime(year, month, i + 1));
  }

  // Monthly stats for one customer
  double getDeliveredLitersForCustomerForMonth(Customer customer, int year, int month) {
    final days = _getDaysInMonth(year, month);
    double total = 0.0;
    for (final date in days) {
      total += getQuantityForDate(customer, date);
    }
    return total;
  }

  double getBillForCustomerForMonth(Customer customer, int year, int month) {
    final days = _getDaysInMonth(year, month);
    double totalBill = 0.0;
    for (final date in days) {
      final qty = getQuantityForDate(customer, date);
      final rate = getRateForDate(customer, date);
      totalBill += qty * rate;
    }
    return totalBill;
  }

  // All-time stats for one customer (from join date to today)
  Map<String, double> getAllTimeStatsForCustomer(Customer customer) {
    final now = _normalizeDate(DateTime.now());
    final join = _normalizeDate(customer.joinDate);
    
    if (now.isBefore(join)) {
      return {'liters': 0.0, 'bill': 0.0};
    }

    double totalLiters = 0.0;
    double totalBill = 0.0;

    // Loop through all days from join date to today
    final daysCount = now.difference(join).inDays + 1;
    for (int i = 0; i < daysCount; i++) {
      final date = join.add(Duration(days: i));
      final qty = getQuantityForDate(customer, date);
      final rate = getRateForDate(customer, date);
      totalLiters += qty;
      totalBill += qty * rate;
    }

    return {
      'liters': totalLiters,
      'bill': totalBill,
    };
  }

  double getTotalPaidForCustomer(Customer customer) {
    double total = 0.0;
    for (final p in _payments) {
      if (p.customerId == customer.id) {
        total += p.amount;
      }
    }
    return total;
  }

  double getRemainingBalanceForCustomer(Customer customer) {
    final stats = getAllTimeStatsForCustomer(customer);
    final totalBill = stats['bill'] ?? 0.0;
    final totalPaid = getTotalPaidForCustomer(customer);
    return totalBill - totalPaid;
  }

  String getPaymentStatusForCustomer(Customer customer) {
    final stats = getAllTimeStatsForCustomer(customer);
    final totalBill = stats['bill'] ?? 0.0;
    final totalPaid = getTotalPaidForCustomer(customer);
    final remaining = totalBill - totalPaid;

    if (totalBill == 0) return 'Paid';
    if (remaining <= 0.01) return 'Paid';
    if (totalPaid <= 0.01) return 'Unpaid';
    return 'Partial';
  }

  // --- MONTH-SPECIFIC BILLING ---

  /// Get all payments made for a specific month by a customer
  List<Payment> getPaymentsForMonth(String customerId, int year, int month) {
    return _payments
        .where((p) => p.customerId == customerId && p.paymentMonth == month && p.paymentYear == year)
        .toList();
  }

  /// Get total payments made in a specific month
  double getTotalPaidForMonth(String customerId, int year, int month) {
    return getPaymentsForMonth(customerId, year, month).fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Get monthly balance = monthly bill - payments for that month
  double getMonthlyBalance(Customer customer, int year, int month) {
    final monthlyBill = getBillForCustomerForMonth(customer, year, month);
    final monthlyPayments = getTotalPaidForMonth(customer.id, year, month);
    return monthlyBill - monthlyPayments;
  }

  /// Get unpaid balance before a specific month (cumulative from start to end of previous month)
  double getPreviousUnpaidBalance(Customer customer, int year, int month) {
    final now = DateTime.now();
    final targetMonthStart = DateTime(year, month, 1);

    // If target is in the future, return 0
    if (targetMonthStart.isAfter(now)) {
      return 0;
    }

    // Calculate total bills and payments before this month
    double totalBillBeforeMonth = 0.0;
    double totalPaidBeforeMonth = 0.0;

    // Loop through all months from join date to the month before target
    final joinDate = customer.joinDate;
    DateTime currentDate = DateTime(joinDate.year, joinDate.month, 1);

    while (currentDate.isBefore(targetMonthStart)) {
      totalBillBeforeMonth += getBillForCustomerForMonth(customer, currentDate.year, currentDate.month);
      totalPaidBeforeMonth += getTotalPaidForMonth(customer.id, currentDate.year, currentDate.month);

      // Move to next month
      if (currentDate.month == 12) {
        currentDate = DateTime(currentDate.year + 1, 1, 1);
      } else {
        currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      }
    }

    return totalBillBeforeMonth - totalPaidBeforeMonth;
  }

  // --- DASHBOARD DAILY GLOBAL STATS ---

  double getExpectedMilkVolumeForDate(DateTime date) {
    double total = 0.0;
    for (final c in _customers) {
      total += getQuantityForDate(c, date);
    }
    return total;
  }

  // --- DELIVERY CONFIRMATION TRACKING ---

  /// Returns whether a specific customer's milk was confirmed as delivered on [date].
  bool isDeliveredOnDate(String customerId, DateTime date) {
    final normDate = _normalizeDate(date);
    return _confirmations.any(
      (c) => c.customerId == customerId && isSameDay(c.date, normDate) && c.isDelivered,
    );
  }

  /// Toggles the delivery confirmation for a customer on a specific date.
  Future<void> toggleDelivery(String customerId, DateTime date) async {
    final normDate = _normalizeDate(date);
    final existingIndex = _confirmations.indexWhere(
      (c) => c.customerId == customerId && isSameDay(c.date, normDate),
    );

    if (existingIndex != -1) {
      // Toggle existing record
      final existing = _confirmations[existingIndex];
      _confirmations[existingIndex] = existing.copyWith(
        isDelivered: !existing.isDelivered,
        confirmedAt: !existing.isDelivered ? DateTime.now() : null,
      );
    } else {
      // Create new confirmed record
      _confirmations.add(DeliveryConfirmation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: customerId,
        date: normDate,
        isDelivered: true,
        confirmedAt: DateTime.now(),
      ));
    }

    notifyListeners();
    await _saveDatabase();
  }

  /// Mark all active customers on [date] as delivered at once.
  Future<void> markAllDeliveredForDate(DateTime date) async {
    final normDate = _normalizeDate(date);
    for (final customer in _customers) {
      final qty = getQuantityForDate(customer, normDate);
      if (qty > 0) {
        final existingIndex = _confirmations.indexWhere(
          (c) => c.customerId == customer.id && isSameDay(c.date, normDate),
        );
        if (existingIndex != -1) {
          _confirmations[existingIndex] = _confirmations[existingIndex].copyWith(
            isDelivered: true,
            confirmedAt: DateTime.now(),
          );
        } else {
          _confirmations.add(DeliveryConfirmation(
            id: '${customer.id}_${normDate.millisecondsSinceEpoch}',
            customerId: customer.id,
            date: normDate,
            isDelivered: true,
            confirmedAt: DateTime.now(),
          ));
        }
      }
    }
    notifyListeners();
    await _saveDatabase();
  }

  /// Returns how many customers have been confirmed delivered on [date]
  /// (among those who have quantity > 0).
  int getDeliveredCountForDate(DateTime date) {
    final normDate = _normalizeDate(date);
    return _confirmations.where(
      (c) => isSameDay(c.date, normDate) && c.isDelivered,
    ).length;
  }

  /// Returns total customers who have expected quantity > 0 on [date].
  int getTotalActiveDeliveriesForDate(DateTime date) {
    return _customers.where((c) => getQuantityForDate(c, date) > 0).length;
  }

  // --- BACKUP & RESTORE MANAGEMENT ---

  /// Creates a backup of the current database and returns the file path
  Future<String?> createBackup() async {
    return await _dbService.createBackup(
      customers: _customers,
      overrides: _overrides,
      payments: _payments,
      confirmations: _confirmations,
      rateChanges: _rateChanges,
      quantityChanges: _quantityChanges,
    );
  }

  /// Restores database from a backup file
  Future<bool> restoreFromBackup(String backupFilePath) async {
    try {
      final restoredData = await _dbService.restoreFromBackup(backupFilePath);
      if (restoredData == null) {
        return false;
      }

      _customers = List<Customer>.from(restoredData['customers'] as List);
      _overrides = List<DeliveryOverride>.from(restoredData['overrides'] as List);
      _payments = List<Payment>.from(restoredData['payments'] as List);
      _confirmations = List<DeliveryConfirmation>.from(restoredData['confirmations'] as List);
      _rateChanges = List<RateChange>.from(restoredData['rateChanges'] as List);
      _quantityChanges = List<QuantityChange>.from(restoredData['quantityChanges'] as List? ?? []);

      notifyListeners();
      await _saveDatabase();
      return true;
    } catch (e) {
      debugPrint("Error during restore: $e");
      return false;
    }
  }

  /// Lists all available backup files, most recent first
  Future<List<String>> listAvailableBackups() async {
    final backupFiles = await _dbService.listBackupFiles();
    return backupFiles.map((f) => f.path).toList();
  }

  Future<void> shareBackup(String path) async {
  final file = File(path);

  if (!await file.exists()) return;

  Share.shareXFiles([XFile(file.path)]);
}
}
