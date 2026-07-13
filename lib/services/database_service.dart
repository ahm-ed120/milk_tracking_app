import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';
import '../models/delivery_override.dart';
import '../models/delivery_confirmation.dart';
import '../models/payment.dart';import '../models/quantity_change.dart';import '../models/quantity_change.dart';
import '../models/rate_change.dart';

class DatabaseService {
  static const String _fileName = 'milk_tracker_db.json';

  // Get the file path for saving data locally
  Future<File> _getLocalFile() async {
    try {
      if (kIsWeb) {
        throw UnsupportedError(
          "Web storage is not supported natively in this file implementation.",
        );
      }
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_fileName');
    } catch (e) {
      debugPrint("Error getting database path: $e");
      return File(_fileName);
    }
  }

  // Load all data from the JSON file
  Future<Map<String, dynamic>> loadData() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        debugPrint("Database file does not exist. Initializing empty state.");
        return {
          'customers': <Customer>[],
          'overrides': <DeliveryOverride>[],
          'payments': <Payment>[],
          'confirmations': <DeliveryConfirmation>[],
          'rateChanges': <RateChange>[],
          'quantityChanges': <QuantityChange>[],
        };
      }

      final contents = await file.readAsString();
      final Map<String, dynamic> jsonMap =
          json.decode(contents) as Map<String, dynamic>;

      final rawCustomers = jsonMap['customers'] as List<dynamic>? ?? [];
      final rawOverrides = jsonMap['overrides'] as List<dynamic>? ?? [];
      final rawPayments = jsonMap['payments'] as List<dynamic>? ?? [];
      final rawConfirmations = jsonMap['confirmations'] as List<dynamic>? ?? [];
      final rawRateChanges = jsonMap['rateChanges'] as List<dynamic>? ?? [];
      final rawQuantityChanges = jsonMap['quantityChanges'] as List<dynamic>? ?? [];

      final customers = rawCustomers
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();

      final overrides = rawOverrides
          .map(
            (item) => DeliveryOverride.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final payments = rawPayments
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList();

      final confirmations = rawConfirmations
          .map(
            (item) =>
                DeliveryConfirmation.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final rateChanges = rawRateChanges
          .map((item) => RateChange.fromJson(item as Map<String, dynamic>))
          .toList();

      final quantityChanges = rawQuantityChanges
          .map((item) => QuantityChange.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
        "Database loaded: ${customers.length} customers, ${overrides.length} overrides, ${payments.length} payments, ${confirmations.length} confirmations.",
      );
      return {
        'customers': customers,
        'overrides': overrides,
        'payments': payments,
        'confirmations': confirmations,
        'rateChanges': rateChanges,
        'quantityChanges': quantityChanges,
      };
    } catch (e) {
      debugPrint("Error loading data from file: $e");
      return {
        'customers': <Customer>[],
        'overrides': <DeliveryOverride>[],
        'payments': <Payment>[],
        'confirmations': <DeliveryConfirmation>[],
        'rateChanges': <RateChange>[],
        'quantityChanges': <QuantityChange>[],
      };
    }
  }

  // Save all data to the JSON file
  Future<bool> saveData({
    required List<Customer> customers,
    required List<DeliveryOverride> overrides,
    required List<Payment> payments,
    required List<DeliveryConfirmation> confirmations,
    required List<RateChange> rateChanges,
    required List<QuantityChange> quantityChanges,
  }) async {
    try {
      final file = await _getLocalFile();

      final Map<String, dynamic> data = {
        'customers': customers.map((c) => c.toJson()).toList(),
        'overrides': overrides.map((o) => o.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'confirmations': confirmations.map((c) => c.toJson()).toList(),
        'rateChanges': rateChanges.map((r) => r.toJson()).toList(),
        'quantityChanges': quantityChanges.map((q) => q.toJson()).toList(),
      };

      final String jsonStr = json.encode(data);
      await file.writeAsString(jsonStr, flush: true);
      debugPrint(
        "Database saved: ${customers.length} customers, ${confirmations.length} confirmations.",
      );
      return true;
    } catch (e) {
      debugPrint("Error saving database to file: $e");
      return false;
    }
  }

  // Get the backup directory path
  Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();

    final backupDir = Directory('${documentsDir.path}/MilkTracker');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  // Create a backup of the current database with timestamp
  Future<String?> createBackup({
    required List<Customer> customers,
    required List<DeliveryOverride> overrides,
    required List<Payment> payments,
    required List<DeliveryConfirmation> confirmations,
    required List<RateChange> rateChanges,
    required List<QuantityChange> quantityChanges,
  }) async {
    try {
      final backupDir = await _getBackupDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final backupFileName = 'milk_tracker_backup_$timestamp.json';
      final backupFile = File('${backupDir.path}/$backupFileName');

      final Map<String, dynamic> data = {
        'customers': customers.map((c) => c.toJson()).toList(),
        'overrides': overrides.map((o) => o.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'confirmations': confirmations.map((c) => c.toJson()).toList(),
        'rateChanges': rateChanges.map((r) => r.toJson()).toList(),
        'quantityChanges': quantityChanges.map((q) => q.toJson()).toList(),
        'backupDate': DateTime.now().toIso8601String(),
      };

      final String jsonStr = json.encode(data);
      await backupFile.writeAsString(jsonStr, flush: true);
      debugPrint("Backup created: ${backupFile.path}");
      return backupFile.path;
    } catch (e) {
      debugPrint("Error creating backup: $e");
      return null;
    }
  }

  // Restore database from a backup file
  Future<Map<String, dynamic>?> restoreFromBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        debugPrint("Backup file not found: $backupFilePath");
        return null;
      }

      final contents = await backupFile.readAsString();
      final Map<String, dynamic> jsonMap =
          json.decode(contents) as Map<String, dynamic>;

      final rawCustomers = jsonMap['customers'] as List<dynamic>? ?? [];
      final rawOverrides = jsonMap['overrides'] as List<dynamic>? ?? [];
      final rawPayments = jsonMap['payments'] as List<dynamic>? ?? [];
      final rawConfirmations = jsonMap['confirmations'] as List<dynamic>? ?? [];
      final rawRateChanges = jsonMap['rateChanges'] as List<dynamic>? ?? [];
      final rawQuantityChanges = jsonMap['quantityChanges'] as List<dynamic>? ?? [];

      final customers = rawCustomers
          .map((item) => Customer.fromJson(item as Map<String, dynamic>))
          .toList();

      final overrides = rawOverrides
          .map(
            (item) => DeliveryOverride.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final payments = rawPayments
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList();

      final confirmations = rawConfirmations
          .map(
            (item) =>
                DeliveryConfirmation.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final rateChanges = rawRateChanges
          .map((item) => RateChange.fromJson(item as Map<String, dynamic>))
          .toList();

      final quantityChanges = rawQuantityChanges
          .map((item) => QuantityChange.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
        "Backup restored: ${customers.length} customers, ${overrides.length} overrides, ${payments.length} payments, ${confirmations.length} confirmations.",
      );
      return {
        'customers': customers,
        'overrides': overrides,
        'payments': payments,
        'confirmations': confirmations,
        'rateChanges': rateChanges,
        'quantityChanges': quantityChanges,
      };
    } catch (e) {
      debugPrint("Error restoring from backup: $e");
      return null;
    }
  }

  // List available backup files
  Future<List<File>> listBackupFiles() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFiles =
          backupDir
              .listSync()
              .whereType<File>()
              .where(
                (file) =>
                    file.path.contains('milk_tracker_backup_') &&
                    file.path.endsWith('.json'),
              )
              .toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );
      return backupFiles;
    } catch (e) {
      debugPrint("Error listing backup files: $e");
      return [];
    }
  }
}
