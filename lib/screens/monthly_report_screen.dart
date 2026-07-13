import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/milk_provider.dart';
import '../theme/app_theme.dart';
import 'customer_detail_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final milkProvider = Provider.of<MilkProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (milkProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth, 1));

    // MATH AGGREGATIONS FOR THE SELECT MONTH
    double totalLiters = 0.0;
    double totalBilled = 0.0;
    double totalCollected = 0.0;

    // List of customer statistics for display
    final List<Map<String, dynamic>> breakdownList = [];

    for (final customer in milkProvider.customers) {
      final liters = milkProvider.getDeliveredLitersForCustomerForMonth(customer, _selectedYear, _selectedMonth);
      final bill = milkProvider.getBillForCustomerForMonth(customer, _selectedYear, _selectedMonth);
      final customerMonthPayments = milkProvider.getTotalPaidForMonth(customer.id, _selectedYear, _selectedMonth);

      totalLiters += liters;
      totalBilled += bill;
      totalCollected += customerMonthPayments;

      if (liters > 0 || customerMonthPayments > 0) {
        breakdownList.add({
          'customer': customer,
          'liters': liters,
          'bill': bill,
          'paid': customerMonthPayments,
          'balance': bill - customerMonthPayments,
        });
      }
    }

    double pendingCollection = totalBilled - totalCollected;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Ledgers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // MONTH/YEAR DROP DOWN ACCORDION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppTheme.glassCard(context),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: List.generate(12, (index) => index + 1).map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(DateFormat('MMMM').format(DateTime(2020, m, 1))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMonth = val;
                            });
                          }
                        },
                      ),
                    ),
                    const VerticalDivider(width: 24),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [2024, 2025, 2026, 2027].map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text(y.toString()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // LEDGER ANALYTICS SUMMARIES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatsBox("Month Liters Billed", "${totalLiters.toStringAsFixed(1)} L", AppTheme.secondary),
                  _buildStatsBox("Total Billed Revenue", "Rs. ${totalBilled.toStringAsFixed(0)}", AppTheme.statusUnpaid),
                  _buildStatsBox("Collections Received", "Rs. ${totalCollected.toStringAsFixed(0)}", AppTheme.statusPaid),
                  _buildStatsBox("Collections Pending", "Rs. ${pendingCollection.toStringAsFixed(0)}", pendingCollection > 0 ? AppTheme.statusPartial : AppTheme.statusPaid),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BREAKDOWN GRID HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Customer Details - $monthName",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // CUSTOMER BREAKDOWNS
            Expanded(
              child: breakdownList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                          const SizedBox(height: 12),
                          Text("No logs recorded for $monthName."),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: breakdownList.length,
                      itemBuilder: (context, index) {
                        final item = breakdownList[index];
                        final customer = item['customer'] as Customer;
                        final liters = item['liters'] as double;
                        final bill = item['bill'] as double;
                        final paid = item['paid'] as double;
                        final balance = item['balance'] as double;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppTheme.glassCard(context),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    customer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${liters.toStringAsFixed(1)} L",
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Billed: Rs. ${bill.toStringAsFixed(0)}"),
                                  Text("Paid: Rs. ${paid.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.statusPaid)),
                                  Text(
                                    "Bal: Rs. ${balance.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: balance > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerDetailScreen(customer: customer),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
