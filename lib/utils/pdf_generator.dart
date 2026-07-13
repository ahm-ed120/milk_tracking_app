import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/milk_provider.dart';

class PdfGenerator {
  // Generates PDF document bytes for a specific customer and month
  static Future<Uint8List> generateInvoice({
    required Customer customer,
    required int year,
    required int month,
    required MilkProvider provider,
  }) async {
    final pdf = pw.Document();

    final totalLiters = provider.getDeliveredLitersForCustomerForMonth(customer, year, month);
    final monthBill = provider.getBillForCustomerForMonth(customer, year, month);
    final monthlyPayments = provider.getTotalPaidForMonth(customer.id, year, month);
    final previousBalance = provider.getPreviousUnpaidBalance(customer, year, month);
    final monthlyBalance = provider.getMonthlyBalance(customer, year, month);

    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month, 1));
    final issueDate = DateFormat('d MMMM y').format(DateTime.now());

    // Generate date list for table
    final lastDay = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    int endDay = lastDay;
    if (year == now.year && month == now.month) {
      endDay = now.day;
    }

    final List<List<String>> tableData = [];
    // Table Header
    tableData.add(['Date', 'Milk Delivered (L)', 'Rate / Liter', 'Daily Subtotal']);

    for (int day = 1; day <= endDay; day++) {
      final date = DateTime(year, month, day);
      final qty = provider.getQuantityForDate(customer, date);
      final rate = provider.getRateForDate(customer, date);
      final sub = qty * rate;

      if (qty > 0 || customer.isPausedOn(date)) {
        String qtyStr = "${qty.toStringAsFixed(1)} L";
        if (customer.isPausedOn(date)) {
          qtyStr = "0.0 L (Paused)";
        }
        tableData.add([
          DateFormat('d MMM (EEE)').format(date),
          qtyStr,
          "Rs. ${rate.toStringAsFixed(0)}",
          "Rs. ${sub.toStringAsFixed(0)}",
        ]);
      }
    }

    // Get payments for this month
    final monthPayments = provider.getPaymentsForMonth(customer.id, year, month);

    // Design layout using PDF widgets
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Shop Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "MILK DELIVERY SERVICES",
                        style: pw.TextStyle(
                          fontSize: 20, 
                          fontWeight: pw.FontWeight.bold, 
                          color: PdfColor.fromInt(0xFF6366F1), // Indigo primary
                        ),
                      ),
                      pw.Text("Daily Fresh Milk Tracker & Ledger Invoice", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("INVOICE", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Billing Cycle: $monthName", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Date Issued: $issueDate", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 12),

              // Customer Profile info block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("BILLED TO:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(customer.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Phone: ${customer.phone}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Address: ${customer.address}", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ACCOUNT SUMMARY:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text("Monthly Liters: ${totalLiters.toStringAsFixed(1)} L", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Monthly Bill: Rs. ${monthBill.toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Previous Balance: Rs. ${previousBalance.toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Payments This Month: Rs. ${monthlyPayments.toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Due This Month: Rs. ${monthlyBalance.toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Ledger Table header title
              pw.Text(
                "Daily Delivery History Log",
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)),
              ),
              pw.SizedBox(height: 8),

              // Main ledger table
              pw.TableHelper.fromTextArray(
                headers: tableData[0],
                data: tableData.sublist(1),
                border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColor.fromInt(0xFFF1F5F9), width: 1)),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF6366F1), // Indigo
                ),
                rowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 20),

              // Payment records subtable if any
              if (monthPayments.isNotEmpty) ...[
                pw.Text(
                  "Payments Logged in $monthName",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)),
                ),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  headers: ['Payment Date', 'Amount Received', 'Notes'],
                  data: monthPayments.map((p) => [
                    DateFormat('d MMM y').format(p.date),
                    "Rs. ${p.amount.toStringAsFixed(0)}",
                    p.notes.isEmpty ? "Payment" : p.notes
                  ]).toList(),
                  border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColor.fromInt(0xFFF1F5F9), width: 1)),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A)),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE2E8F0)),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerLeft,
                  },
                ),
                pw.SizedBox(height: 20),
              ],

              // TOTAL OUTSTANDING BLOCK
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildInvoicePdfRow("Month Billed:", "Rs. ${monthBill.toStringAsFixed(0)}"),
                      pw.SizedBox(height: 4),
                      _buildInvoicePdfRow("Month Collections:", "Rs. ${monthlyPayments.toStringAsFixed(0)}"),
                      pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFFE2E8F0)),
                      _buildInvoicePdfRow(
                        "Net Outstanding Due:", 
                        "Rs. ${monthlyBalance.toStringAsFixed(0)}", 
                        isBold: true,
                        color: monthlyBalance > 0 ? PdfColor.fromInt(0xFFF43F5E) : PdfColor.fromInt(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 10),
              // Footer
              pw.Center(
                child: pw.Text("Thank you for your business! Please pay outstanding balance by 5th of next month.",
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoicePdfRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9, 
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10, 
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Uses printing package to show a native OS share / print layout sheet
  static Future<void> shareOrPrintPdf(Uint8List pdfBytes, String filename) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
    }
  }
}
