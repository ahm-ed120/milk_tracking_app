import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Object? customer;
  const CustomerDetailScreen({super.key, this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _MockCustomer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double defaultQuantity;
  final double rate;
  final DateTime joinDate;
  final List<_MockPausePeriod> pausePeriods;

  const _MockCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.defaultQuantity,
    required this.rate,
    required this.joinDate,
    required this.pausePeriods,
  });

  bool isPausedOn(DateTime date) {
    return pausePeriods.any((period) {
      final startOk = !date.isBefore(period.startDate);
      final endOk = period.endDate == null || !date.isAfter(period.endDate!);
      return startOk && endOk;
    });
  }

  _MockCustomer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? defaultQuantity,
    double? rate,
    DateTime? joinDate,
    List<_MockPausePeriod>? pausePeriods,
  }) {
    return _MockCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      rate: rate ?? this.rate,
      joinDate: joinDate ?? this.joinDate,
      pausePeriods: pausePeriods ?? this.pausePeriods,
    );
  }
}

class _MockPausePeriod {
  final String id;
  final DateTime startDate;
  DateTime? endDate;

  _MockPausePeriod({required this.id, required this.startDate, this.endDate});
}

class _MockPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String notes;
  final int paymentMonth;
  final int paymentYear;

  _MockPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.notes,
    required this.paymentMonth,
    required this.paymentYear,
  });
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late _MockCustomer _activeCustomer;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  final List<_MockPayment> _payments = [];
  final Map<String, double> _overrides = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _activeCustomer = _resolveCustomer(widget.customer);

    _payments.addAll([
      _MockPayment(id: 'p1', amount: 1800, date: DateTime(2024, 5, 10), notes: 'Cash', paymentMonth: 5, paymentYear: 2024),
      _MockPayment(id: 'p2', amount: 1200, date: DateTime(2024, 6, 8), notes: 'Bank transfer', paymentMonth: 6, paymentYear: 2024),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _MockCustomer _resolveCustomer(Object? source) {
    if (source is _MockCustomer) {
      return source;
    }
    return _MockCustomer(
      id: 'demo',
      name: 'Demo Customer',
      phone: '9876543210',
      address: 'Sample Address',
      defaultQuantity: 2.0,
      rate: 220.0,
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
      pausePeriods: const [],
    );
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch call for $phone');
    }
  }

  double _getTotalBill() {
    final days = DateTime.now().difference(_activeCustomer.joinDate).inDays + 1;
    return _activeCustomer.defaultQuantity * days * _activeCustomer.rate;
  }

  double _getTotalPaid() {
    return _payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getRemainingBalance() {
    return _getTotalBill() - _getTotalPaid();
  }

  String _getPaymentStatus() {
    final remaining = _getRemainingBalance();
    if (remaining <= 0) return 'Paid';
    if (remaining < 1000) return 'Partial';
    return 'Unpaid';
  }

  double _getQuantityForDate(DateTime date) {
    final key = '${_activeCustomer.id}-${date.year}-${date.month}-${date.day}';
    if (_overrides.containsKey(key)) {
      return _overrides[key]!;
    }
    return !_activeCustomer.isPausedOn(date) ? _activeCustomer.defaultQuantity : 0.0;
  }

  bool _hasOverride(DateTime date) {
    final key = '${_activeCustomer.id}-${date.year}-${date.month}-${date.day}';
    return _overrides.containsKey(key);
  }

  void _recordOverride(DateTime date, double value) {
    final key = '${_activeCustomer.id}-${date.year}-${date.month}-${date.day}';
    setState(() {
      if (value <= 0) {
        _overrides.remove(key);
      } else {
        _overrides[key] = value;
      }
    });
  }

  double _getMonthlyLiters() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    return daysInMonth * _activeCustomer.defaultQuantity;
  }

  double _getMonthlyBill() {
    return _getMonthlyLiters() * _activeCustomer.rate;
  }

  double _getPaymentsForMonth() {
    return _payments.where((payment) => payment.paymentMonth == _selectedMonth && payment.paymentYear == _selectedYear).fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getPreviousUnpaidBalance() {
    return (_getMonthlyBill() + _getRemainingBalance().clamp(0.0, 1000000.0)) - _getPaymentsForMonth();
  }

  double _getMonthlyBalance() {
    return _getMonthlyBill() - _getPaymentsForMonth();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingBalance = _getRemainingBalance();
    final paymentStatus = _getPaymentStatus();

    Color badgeColor;
    if (paymentStatus == 'Paid') {
      badgeColor = AppTheme.statusPaid;
    } else if (paymentStatus == 'Partial') {
      badgeColor = AppTheme.statusPartial;
    } else {
      badgeColor = AppTheme.statusUnpaid;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeCustomer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCustomerDialog(context),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.statusUnpaid),
            onPressed: () => _confirmDeleteCustomer(context),
            tooltip: 'Delete Customer',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline, size: 20)),
            Tab(text: 'Delivery Log', icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: 'Payments', icon: Icon(Icons.currency_exchange, size: 20)),
            Tab(text: 'Pause/Schedule', icon: Icon(Icons.pause_circle_outline, size: 20)),
            Tab(text: 'Invoice', icon: Icon(Icons.receipt_long, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, remainingBalance, paymentStatus, badgeColor),
        ],
      ),
    );
  }
  //Overview Tab
  Widget _buildOverviewTab(BuildContext context, double remaining, String status, Color badgeColor) {
    final totalBill = _getTotalBill();
    final totalPaid = _getTotalPaid();
    final totalLiters = _getMonthlyLiters();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard(context),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text(
                        _activeCustomer.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeCustomer.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                            ),
                            child: Text(
                              'Status: $status',
                              style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(_activeCustomer.phone),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Dial'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('WhatsApp preview is ready in this frontend mock.')),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Financial Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryTile('Total Bill (All-time)', 'Rs. ${totalBill.toStringAsFixed(0)}', AppTheme.primary, Icons.receipt_long),
              _buildSummaryTile('Total Paid', 'Rs. ${totalPaid.toStringAsFixed(0)}', AppTheme.statusPaid, Icons.payments_outlined),
              _buildSummaryTile('Total Liters', '${totalLiters.toStringAsFixed(1)} L', AppTheme.secondary, Icons.water_drop),
              _buildSummaryTile('Remaining Balance', 'Rs. ${remaining.toStringAsFixed(0)}', remaining > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid, Icons.pending_actions),
            ],
          ),
          const SizedBox(height: 20),
          Text('Billing Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard(context),
            child: Column(
              children: [
                _buildInfoRow('Phone Number', _activeCustomer.phone, Icons.phone_android),
                const Divider(height: 24),
                _buildInfoRow('Billing Address', _activeCustomer.address, Icons.location_on_outlined),
                const Divider(height: 24),
                _buildInfoRow('Default Quantity', '${_activeCustomer.defaultQuantity} Liters', Icons.water_drop_outlined),
                const Divider(height: 24),
                _buildInfoRow('Milk Rate per Liter', 'Rs. ${_activeCustomer.rate.toStringAsFixed(0)} / L', Icons.currency_exchange_outlined),
                const Divider(height: 24),
                _buildInfoRow('Joined on', DateFormat('d MMMM y').format(_activeCustomer.joinDate), Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  //Delivery Log Tab
  Widget _buildDeliveryLogTab(BuildContext context) {
    final now = DateTime.now();
    final join = _activeCustomer.joinDate;

    if (now.isBefore(join)) {
      return const Center(child: Text('Join Date is in the future. No logs recorded yet.'));
    }

    final int daysCount = now.difference(join).inDays + 1;
    final List<DateTime> dates = List.generate(
      daysCount,
      (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final qty = _getQuantityForDate(date);
        final rate = _activeCustomer.rate;
        final cost = qty * rate;
        final isPaused = _activeCustomer.isPausedOn(date);
        final hasOverride = _hasOverride(date);

        Widget statusBadge;
        Color amountColor = Colors.white;

        if (isPaused) {
          statusBadge = const Text('PAUSED', style: TextStyle(color: AppTheme.statusPaused, fontSize: 10, fontWeight: FontWeight.bold));
          amountColor = AppTheme.statusPaused;
        } else if (hasOverride) {
          statusBadge = const Text('OVERRIDDEN', style: TextStyle(color: AppTheme.statusPartial, fontSize: 10, fontWeight: FontWeight.bold));
          amountColor = AppTheme.statusPartial;
        } else {
          statusBadge = const Text('DEFAULT', style: TextStyle(color: AppTheme.statusPaid, fontSize: 10, fontWeight: FontWeight.bold));
          amountColor = AppTheme.statusPaid;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: AppTheme.glassCard(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMMM').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        statusBadge,
                        const SizedBox(width: 8),
                        Text('•  Rs. ${rate.toStringAsFixed(0)}/L'),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${qty.toStringAsFixed(1)} Liters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: amountColor)),
                        Text('Rs. ${cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: isPaused ? null : () => _showEditOverrideDialog(context, date, qty),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditOverrideDialog(BuildContext context, DateTime date, double currentQty) {
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${DateFormat('d MMMM').format(date)} Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set milk delivered for ${_activeCustomer.name} on this date:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Quantity (Liters)', suffixText: 'L'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _recordOverride(date, _activeCustomer.defaultQuantity);
              Navigator.pop(context);
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                _recordOverride(date, val);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  //Payment Tab
  Widget _buildPaymentsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  const SizedBox(height: 12),
                  const Text('No payments logged for this customer yet.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: AppTheme.glassCard(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.statusPaid,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.arrow_downward),
                    ),
                    title: Text('Rs. ${payment.amount.toStringAsFixed(0)} Paid', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.statusPaid)),
                    subtitle: Text('${DateFormat('d MMMM y').format(payment.date)}  •  ${payment.notes.isEmpty ? 'Cash payment' : payment.notes}', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.statusUnpaid, size: 20),
                      onPressed: () => _confirmDeletePayment(context, payment),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'payment_fab',
        onPressed: () => _showAddPaymentDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    double amount = 0.0;
    String notes = '';
    DateTime payDate = DateTime.now();
    int paymentMonth = DateTime.now().month;
    int paymentYear = DateTime.now().year;

    final payDateController = TextEditingController(text: DateFormat('d MMMM y').format(payDate));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Amount Paid (Rs.)', prefixIcon: Icon(Icons.currency_exchange)),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      final a = double.tryParse(val ?? '');
                      return (a == null || a <= 0) ? 'Must be > 0' : null;
                    },
                    onSaved: (val) => amount = double.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Payment Notes', prefixIcon: Icon(Icons.notes), hintText: 'e.g. Cash, Bank Transfer'),
                    onSaved: (val) => notes = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: payDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_month)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: payDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primary,
                              onPrimary: Colors.white,
                              surface: AppTheme.cardDark,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() {
                          payDate = picked;
                          payDateController.text = DateFormat('d MMMM y').format(payDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Which month is this payment for?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: paymentMonth,
                          isExpanded: true,
                          items: List.generate(12, (index) => index + 1).map((m) {
                            return DropdownMenuItem<int>(value: m, child: Text(DateFormat('MMMM').format(DateTime(2020, m, 1))));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                paymentMonth = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: paymentYear,
                          isExpanded: true,
                          items: [2024, 2025, 2026, 2027].map((y) {
                            return DropdownMenuItem<int>(value: y, child: Text(y.toString()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                paymentYear = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  setState(() {
                    _payments.add(_MockPayment(id: DateTime.now().millisecondsSinceEpoch.toString(), amount: amount, date: payDate, notes: notes, paymentMonth: paymentMonth, paymentYear: paymentYear));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, _MockPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment of Rs. ${payment.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _payments.remove(payment);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusUnpaid),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
