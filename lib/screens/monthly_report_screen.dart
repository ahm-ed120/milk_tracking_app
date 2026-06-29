import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MockCustomer {
  final String id;
  final String name;
  final double liters;
  final double billed;
  final double paid;

  const _MockCustomer({
    required this.id,
    required this.name,
    required this.liters,
    required this.billed,
    required this.paid,
  });
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<_MockCustomer> _customers = const [
    _MockCustomer(id: '1', name: 'Asha Khan', liters: 48.5, billed: 4800, paid: 3200),
    _MockCustomer(id: '2', name: 'Ravi Sharma', liters: 31.0, billed: 3100, paid: 3100),
    _MockCustomer(id: '3', name: 'Neha Verma', liters: 54.0, billed: 5400, paid: 2500),
    _MockCustomer(id: '4', name: 'Kiran Patel', liters: 27.5, billed: 2750, paid: 2750),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth, 1));

    double totalLiters = 0.0;
    double totalBilled = 0.0;
    double totalCollected = 0.0;

    final breakdownList = <_MockCustomer>[];

    for (final customer in _customers) {
      totalLiters += customer.liters;
      totalBilled += customer.billed;
      totalCollected += customer.paid;

      if (customer.liters > 0 || customer.paid > 0) {
        breakdownList.add(customer);
      }
    }

    double pendingCollection = totalBilled - totalCollected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Ledgers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  _buildStatsBox('Month Liters Billed', '${totalLiters.toStringAsFixed(1)} L', AppTheme.secondary),
                  _buildStatsBox('Total Billed Revenue', 'Rs. ${totalBilled.toStringAsFixed(0)}', AppTheme.statusUnpaid),
                  _buildStatsBox('Collections Received', 'Rs. ${totalCollected.toStringAsFixed(0)}', AppTheme.statusPaid),
                  _buildStatsBox('Collections Pending', 'Rs. ${pendingCollection.toStringAsFixed(0)}', pendingCollection > 0 ? AppTheme.statusPartial : AppTheme.statusPaid),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Customer Details - $monthName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: breakdownList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                          const SizedBox(height: 12),
                          Text('No logs recorded for $monthName.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: breakdownList.length,
                      itemBuilder: (context, index) {
                        final customer = breakdownList[index];
                        final balance = customer.billed - customer.paid;

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
                                  '${customer.liters.toStringAsFixed(1)} L',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Billed: Rs. ${customer.billed.toStringAsFixed(0)}'),
                                  Text('Paid: Rs. ${customer.paid.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.statusPaid)),
                                  Text(
                                    'Bal: Rs. ${balance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: balance > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
