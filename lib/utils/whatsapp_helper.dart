import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/milk_provider.dart';

class WhatsAppHelper {
  // Cleans phone numbers to ensure they work with wa.me API
  static String _sanitizePhoneNumber(String phone) {
    // Strip out all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If Pakistani/Indian numbers are written starting with 0, drop the zero and add the country code.
    // Pakistan country code: +92, India country code: +91.
    // Let's assume standard formatting based on length:
    // If 11 digits starting with 0 (e.g. 03001234567), change to 923001234567
    if (digits.length == 11 && digits.startsWith('0')) {
      return '92${digits.substring(1)}';
    }
    // If 10 digits (e.g. standard Indian mobile), prepend 91
    if (digits.length == 10) {
      return '91$digits';
    }
    
    return digits;
  }

  // Opens a standard chat with a prefilled message
  static Future<void> openWhatsAppChat({
    required String phone,
    required String message,
  }) async {
    final sanitizedPhone = _sanitizePhoneNumber(phone);
    final encodedMessage = Uri.encodeComponent(message);
    
    // We try multiple URI formats: primary is HTTPS wa.me link which works on Web, Android, iOS, Windows out of the box!
    final Uri url = Uri.parse('https://wa.me/$sanitizedPhone?text=$encodedMessage');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to launching in standard browser if external app fails
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }

  // Formats and shares a complete monthly billing statement invoice to WhatsApp
  static Future<void> shareInvoiceToWhatsApp({
    required Customer customer,
    required int year,
    required int month,
    required MilkProvider provider,
  }) async {
    final totalLiters = provider.getDeliveredLitersForCustomerForMonth(customer, year, month);
    final monthBill = provider.getBillForCustomerForMonth(customer, year, month);
    final monthlyPayments = provider.getTotalPaidForMonth(customer.id, year, month);
    final previousBalance = provider.getPreviousUnpaidBalance(customer, year, month);
    final monthlyBalance = provider.getMonthlyBalance(customer, year, month);

    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month, 1));
    final issueDate = DateFormat('d MMMM y').format(DateTime.now());

    // Generate date-by-date delivery history ledger text
    final lastDay = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    int endDay = lastDay;
    if (year == now.year && month == now.month) {
      endDay = now.day;
    }

    final StringBuffer ledgerText = StringBuffer();
    for (int day = 1; day <= endDay; day++) {
      final date = DateTime(year, month, day);
      final qty = provider.getQuantityForDate(customer, date);

      if (qty > 0 || customer.isPausedOn(date)) {
        final dayStr = DateFormat('d MMM').format(date);
        if (customer.isPausedOn(date)) {
          ledgerText.write("📅 $dayStr: *Paused (0L)*\n");
        } else {
          ledgerText.write("📅 $dayStr: *${qty.toStringAsFixed(1)}L*\n");
        }
      }
    }

    // Build invoice message template
    final String message = 
'''🥛 *MILK DELIVERY INVOICE* 🥛
-----------------------------------
*Customer:* ${customer.name}
*Billing Cycle:* $monthName
*Date Issued:* $issueDate
-----------------------------------
📊 *BILL SUMMARY:*
* Delivered Liters:* ${totalLiters.toStringAsFixed(1)} L
* Milk Rate:* Rs. ${customer.rate.toStringAsFixed(0)} / L
* Monthly Bill:* *Rs. ${monthBill.toStringAsFixed(0)}*
* Previous Balance:* Rs. ${previousBalance.toStringAsFixed(0)}
* Payments This Month:* Rs. ${monthlyPayments.toStringAsFixed(0)}
* Due This Month:* *Rs. ${monthlyBalance.toStringAsFixed(0)}*
-----------------------------------
📋 *DAILY LEDGER BREAKDOWN:*
${ledgerText.toString()}
-----------------------------------
_Thank you for your business! Please clear the pending dues by the 5th of next month._
_Generated via Milk Tracker App_''';

    await openWhatsAppChat(phone: customer.phone, message: message);
  }
}
