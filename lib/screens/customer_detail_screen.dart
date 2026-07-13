import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../providers/milk_provider.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_generator.dart';
import '../utils/whatsapp_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Customer _activeCustomer;
  
  // Invoice state selectors
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _activeCustomer = widget.customer;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Reload customer state in case it changed in parent/db
  void _syncCustomerState(MilkProvider provider) {
    try {
      final updated = provider.customers.firstWhere((c) => c.id == _activeCustomer.id);
      setState(() {
        _activeCustomer = updated;
      });
    } catch (_) {
      // Handled if customer was deleted
    }
  }

  // Dial Call launcher
  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch call for $phone");
    }
  }

  @override
  Widget build(BuildContext context) {
    final milkProvider = Provider.of<MilkProvider>(context);
    _syncCustomerState(milkProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final remainingBalance = milkProvider.getRemainingBalanceForCustomer(_activeCustomer);
    final paymentStatus = milkProvider.getPaymentStatusForCustomer(_activeCustomer);

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
            onPressed: () => _showEditCustomerDialog(context, milkProvider),
            tooltip: "Edit Profile",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.statusUnpaid),
            onPressed: () => _confirmDeleteCustomer(context, milkProvider),
            tooltip: "Delete Customer",
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
            Tab(text: "Overview", icon: Icon(Icons.info_outline, size: 20)),
            Tab(text: "Delivery Log", icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: "Payments", icon: Icon(Icons.currency_exchange, size: 20)),
            Tab(text: "Pause/Schedule", icon: Icon(Icons.pause_circle_outline, size: 20)),
            Tab(text: "Invoice", icon: Icon(Icons.receipt_long, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, milkProvider, remainingBalance, paymentStatus, badgeColor),
          _buildDeliveryLogTab(context, milkProvider),
          _buildPaymentsTab(context, milkProvider),
          _buildPauseTab(context, milkProvider),
          _buildInvoiceTab(context, milkProvider),
        ],
      ),
    );
  }

  // --- TAB 1: OVERVIEW TAB ---
  Widget _buildOverviewTab(
    BuildContext context, 
    MilkProvider provider,
    double remaining,
    String status,
    Color badgeColor,
  ) {
    final stats = provider.getAllTimeStatsForCustomer(_activeCustomer);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QUICK INFO CARD
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
                              "Status: $status",
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
                
                // Contact Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(_activeCustomer.phone),
                        icon: const Icon(Icons.phone),
                        label: const Text("Call Dial"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => WhatsAppHelper.openWhatsAppChat(
                          phone: _activeCustomer.phone,
                          message: "Hello ${_activeCustomer.name}, this is Milk Tracker service.",
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp color
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

          // FINANCIAL SUMMARY GRID
          Text("Financial Summary", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryTile("Total Bill (All-time)", "Rs. ${(stats['bill'] ?? 0.0).toStringAsFixed(0)}", AppTheme.primary, Icons.receipt_long),
              _buildSummaryTile("Total Paid", "Rs. ${provider.getTotalPaidForCustomer(_activeCustomer).toStringAsFixed(0)}", AppTheme.statusPaid, Icons.payments_outlined),
              _buildSummaryTile("Total Liters", "${(stats['liters'] ?? 0.0).toStringAsFixed(1)} L", AppTheme.secondary, Icons.water_drop),
              _buildSummaryTile("Remaining Balance", "Rs. ${remaining.toStringAsFixed(0)}", remaining > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid, Icons.pending_actions),
            ],
          ),
          const SizedBox(height: 20),

          // GENERAL CONFIGURATION DETAILS
          Text("Billing Profile", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard(context),
            child: Column(
              children: [
                _buildInfoRow("Phone Number", _activeCustomer.phone, Icons.phone_android),
                const Divider(height: 24),
                _buildInfoRow("Billing Address", _activeCustomer.address, Icons.location_on_outlined),
                const Divider(height: 24),
                _buildInfoRow("Default Quantity", "${_activeCustomer.defaultQuantity} Liters", Icons.water_drop_outlined),
                const Divider(height: 24),
                _buildInfoRow("Milk Rate per Liter", "Rs. ${_activeCustomer.rate.toStringAsFixed(0)} / L", Icons.currency_exchange_outlined),
                const Divider(height: 24),
                _buildInfoRow("Joined on", DateFormat('d MMMM y').format(_activeCustomer.joinDate), Icons.calendar_month_outlined),
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

  // --- TAB 2: DELIVERY LOG TAB (Historical Calender Override View) ---
  Widget _buildDeliveryLogTab(BuildContext context, MilkProvider provider) {
    // Generate dates from customer joinDate to today, in reverse order (newest first)
    final now = DateTime.now();
    final join = _activeCustomer.joinDate;
    
    if (now.isBefore(join)) {
      return const Center(child: Text("Join Date is in the future. No logs recorded yet."));
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
        final qty = provider.getQuantityForDate(_activeCustomer, date);
        final rate = provider.getRateForDate(_activeCustomer, date);
        final cost = qty * rate;

        final isPaused = _activeCustomer.isPausedOn(date);
        final hasOverride = provider.overrides.any(
          (o) => o.customerId == _activeCustomer.id && provider.isSameDay(o.date, date),
        );

        Widget statusBadge;
        Color amountColor = Colors.white;

        if (isPaused) {
          statusBadge = const Text("PAUSED", style: TextStyle(color: AppTheme.statusPaused, fontSize: 10, fontWeight: FontWeight.bold));
          amountColor = AppTheme.statusPaused;
        } else if (hasOverride) {
          statusBadge = const Text("OVERRIDDEN", style: TextStyle(color: AppTheme.statusPartial, fontSize: 10, fontWeight: FontWeight.bold));
          amountColor = AppTheme.statusPartial;
        } else {
          statusBadge = const Text("DEFAULT", style: TextStyle(color: AppTheme.statusPaid, fontSize: 10, fontWeight: FontWeight.bold));
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
                    Text(
                      DateFormat('EEEE, d MMMM').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        statusBadge,
                        const SizedBox(width: 8),
                        Text("•  Rs. ${rate.toStringAsFixed(0)}/L"),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${qty.toStringAsFixed(1)} Liters",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: amountColor),
                        ),
                        Text(
                          "Rs. ${cost.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Click to edit override for this specific date
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: isPaused 
                          ? null 
                          : () => _showEditOverrideDialog(context, date, qty, provider),
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

  void _showEditOverrideDialog(
    BuildContext context, 
    DateTime date, 
    double currentQty, 
    MilkProvider provider,
  ) {
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${DateFormat('d MMMM').format(date)} Delivery"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Set milk delivered for ${_activeCustomer.name} on this date:"),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Quantity (Liters)",
                suffixText: "L",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Quick reset to default by removing override
              provider.recordOverride(_activeCustomer.id, date, _activeCustomer.defaultQuantity);
              Navigator.pop(context);
            },
            child: const Text("Reset Default"),
          ),
          ElevatedButton(
            onPressed: () {
              final double? val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                provider.recordOverride(_activeCustomer.id, date, val);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PAYMENTS LEDGER TAB ---
  Widget _buildPaymentsTab(BuildContext context, MilkProvider provider) {
    final payments = provider.getPaymentsForCustomer(_activeCustomer.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  const SizedBox(height: 12),
                  const Text("No payments logged for this customer yet."),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
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
                    title: Text(
                      "Rs. ${payment.amount.toStringAsFixed(0)} Paid",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.statusPaid),
                    ),
                    subtitle: Text(
                      "${DateFormat('d MMMM y').format(payment.date)}  •  ${payment.notes.isEmpty ? 'Cash payment' : payment.notes}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.statusUnpaid, size: 20),
                      onPressed: () => _confirmDeletePayment(context, payment, provider),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'payment_fab',
        onPressed: () => _showAddPaymentDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text("Add Payment"),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, MilkProvider provider) {
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
          title: const Text("Record Payment"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Amount Paid (Rs.)",
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      final a = double.tryParse(val ?? '');
                      return (a == null || a <= 0) ? "Must be > 0" : null;
                    },
                    onSaved: (val) => amount = double.parse(val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Payment Notes",
                      prefixIcon: Icon(Icons.notes),
                      hintText: "e.g. Cash, Bank Transfer",
                    ),
                    onSaved: (val) => notes = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: payDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Payment Date",
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
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
                  const Text(
                    "Which month is this payment for?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: paymentMonth,
                          isExpanded: true,
                          items: List.generate(12, (index) => index + 1).map((m) {
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(DateFormat('MMMM').format(DateTime(2020, m, 1))),
                            );
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
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            );
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  provider.addPayment(
                    customerId: _activeCustomer.id,
                    amount: amount,
                    date: payDate,
                    notes: notes,
                    paymentMonth: paymentMonth,
                    paymentYear: paymentYear,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Record"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, Payment payment, MilkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Payment"),
        content: Text("Are you sure you want to delete this payment of Rs. ${payment.amount.toStringAsFixed(0)}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePayment(payment.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusUnpaid),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: PAUSE STATE MANAGER TAB ---
  Widget _buildPauseTab(BuildContext context, MilkProvider provider) {
    final ongoingPauses = _activeCustomer.pausePeriods.where((p) => p.endDate == null).toList();
    final finishedPauses = _activeCustomer.pausePeriods.where((p) => p.endDate != null).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CURRENT ACTIVE STATUS CARD
            Text("Ongoing Suspensions", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            
            if (ongoingPauses.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.statusPartial.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.statusPartial.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.statusPartial,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.pause),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AUTO-GENERATION IS PAUSED",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.statusPartial),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Paused since: ${DateFormat('d MMMM y').format(ongoingPauses.first.startDate)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showResumeDialog(context, provider),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Resume Milk Delivery Today"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusPaid,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.statusPaid.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.statusPaid.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.statusPaid,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.check),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CUSTOMER ACTIVE",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.statusPaid),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Milk delivered automatically every day.",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showPauseDialog(context, provider),
                      icon: const Icon(Icons.pause),
                      label: const Text("Pause Milk Deliveries..."),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusPartial,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // HISTORICAL PAUSE LIST
            Text("Historical Suspension Log", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            if (finishedPauses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No historical pause logs recorded.",
                    style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: finishedPauses.length,
                itemBuilder: (context, index) {
                  final pause = finishedPauses[index];
                  final days = pause.endDate!.difference(pause.startDate).inDays + 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AppTheme.glassCard(context),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(
                        "Paused for $days days",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${DateFormat('d MMM').format(pause.startDate)} → ${DateFormat('d MMM y').format(pause.endDate!)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.statusUnpaid, size: 20),
                        onPressed: () => provider.deletePausePeriod(_activeCustomer.id, pause.id),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPauseDialog(BuildContext context, MilkProvider provider) {
    DateTime pauseStart = DateTime.now();
    final dateController = TextEditingController(text: DateFormat('d MMMM y').format(pauseStart));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Pause Milk Deliveries"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select starting date for pausing the deliveries:"),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Pause Start Date",
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: pauseStart,
                    firstDate: _activeCustomer.joinDate,
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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
                      pauseStart = picked;
                      dateController.text = DateFormat('d MMMM y').format(pauseStart);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                provider.pauseCustomer(_activeCustomer.id, pauseStart);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusPartial),
              child: const Text("Confirm Pause"),
            ),
          ],
        ),
      ),
    );
  }

  void _showResumeDialog(BuildContext context, MilkProvider provider) {
    DateTime resumeDate = DateTime.now();
    final dateController = TextEditingController(text: DateFormat('d MMMM y').format(resumeDate));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Resume Deliveries"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select date when the customer resumes milk delivery:"),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Resume Date",
                  prefixIcon: Icon(Icons.play_arrow),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: resumeDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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
                      resumeDate = picked;
                      dateController.text = DateFormat('d MMMM y').format(resumeDate);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                provider.resumeCustomer(_activeCustomer.id, resumeDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusPaid),
              child: const Text("Resume Now"),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 5: INVOICE & REPORTING TAB ---
  Widget _buildInvoiceTab(BuildContext context, MilkProvider provider) {
    // Math logic based on current year/month selectors
    final totalLiters = provider.getDeliveredLitersForCustomerForMonth(_activeCustomer, _selectedYear, _selectedMonth);
    final subtotal = provider.getBillForCustomerForMonth(_activeCustomer, _selectedYear, _selectedMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String monthName = DateFormat('MMMM YYYY').format(DateTime(_selectedYear, _selectedMonth, 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MONTH & YEAR SELECTORS
          Text("Select Invoice Month", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          
          Container(
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
          const SizedBox(height: 24),

          // MONTH STATS SUMMARY CARD
          Text("Monthly Summary - $monthName", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard(context),
            child: Column(
              children: [
                _buildInvoiceItemRow("Total Liters Delivered", "${totalLiters.toStringAsFixed(1)} Liters", AppTheme.secondary),
                const Divider(height: 24),
                _buildInvoiceItemRow("Standard Rate per Liter", "Rs. ${_activeCustomer.rate.toStringAsFixed(0)} / L", isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                const Divider(height: 24),
                _buildInvoiceItemRow("This Month's Bill", "Rs. ${subtotal.toStringAsFixed(0)}", AppTheme.statusUnpaid),
                const Divider(height: 24),
                // Previous unpaid balance
                _buildInvoiceItemRow(
                  "Previous Balance (Before $monthName)",
                  "Rs. ${provider.getPreviousUnpaidBalance(_activeCustomer, _selectedYear, _selectedMonth).toStringAsFixed(0)}",
                  AppTheme.statusPartial,
                ),
                const Divider(height: 24),
                // Payments in this month
                _buildInvoiceItemRow(
                  "Payments in $monthName",
                  "- Rs. ${provider.getTotalPaidForMonth(_activeCustomer.id, _selectedYear, _selectedMonth).toStringAsFixed(0)}",
                  AppTheme.statusPaid,
                ),
                const Divider(height: 24),
                // Total due for this month
                _buildInvoiceItemRow(
                  "Total Due (This Month)",
                  "Rs. ${provider.getMonthlyBalance(_activeCustomer, _selectedYear, _selectedMonth).toStringAsFixed(0)}",
                  provider.getMonthlyBalance(_activeCustomer, _selectedYear, _selectedMonth) > 0.01 
                      ? AppTheme.statusUnpaid 
                      : AppTheme.statusPaid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ACTIONS ROW
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: totalLiters == 0 
                      ? null 
                      : () async {
                          final pdfBytes = await PdfGenerator.generateInvoice(
                            customer: _activeCustomer,
                            year: _selectedYear,
                            month: _selectedMonth,
                            provider: provider,
                          );
                          await PdfGenerator.shareOrPrintPdf(
                            pdfBytes, 
                            "Invoice_${_activeCustomer.name}_${monthName.replaceAll(' ', '_')}"
                          );
                        },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Download PDF"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: totalLiters == 0
                      ? null
                      : () {
                          WhatsAppHelper.shareInvoiceToWhatsApp(
                            customer: _activeCustomer,
                            year: _selectedYear,
                            month: _selectedMonth,
                            provider: provider,
                          );
                        },
                  icon: const Icon(Icons.share),
                  label: const Text("WhatsApp Bill"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          if (totalLiters == 0) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "No milk deliveries logged in this month range.",
                style: TextStyle(fontSize: 12, color: AppTheme.statusPaused, fontStyle: FontStyle.italic),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInvoiceItemRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }

  // --- CRUD ACTIONS & OTHER DIALOGS ---
  void _showEditCustomerDialog(BuildContext context, MilkProvider provider) {
    final formKey = GlobalKey<FormState>();
    String name = _activeCustomer.name;
    String phone = _activeCustomer.phone;
    String address = _activeCustomer.address;
    double defaultQuantity = _activeCustomer.defaultQuantity;
    double rate = _activeCustomer.rate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 
            24, 
            24, 
            MediaQuery.of(context).viewInsets.bottom + 24
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Customer Profile",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                  validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                  onSaved: (val) => name = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? "Phone number is required" : null,
                  onSaved: (val) => phone = val!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: address,
                  decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.home)),
                  validator: (val) => val == null || val.trim().isEmpty ? "Address is required" : null,
                  onSaved: (val) => address = val!.trim(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: defaultQuantity.toString(),
                        decoration: const InputDecoration(labelText: "Daily Milk (L)", suffixText: "L"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final d = double.tryParse(val ?? '');
                          return (d == null || d <= 0) ? "Must be > 0" : null;
                        },
                        onSaved: (val) => defaultQuantity = double.parse(val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: rate.toString(),
                        decoration: const InputDecoration(labelText: "Rate per L", suffixText: "Rs"),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) {
                          final r = double.tryParse(val ?? '');
                          return (r == null || r <= 0) ? "Must be > 0" : null;
                        },
                        onSaved: (val) => rate = double.parse(val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          
                          final updated = _activeCustomer.copyWith(
                            name: name,
                            phone: phone,
                            address: address,
                            defaultQuantity: defaultQuantity,
                            rate: rate,
                          );

                          provider.updateCustomer(updated);
                          setState(() {
                            _activeCustomer = updated;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Save Changes"),
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

  void _confirmDeleteCustomer(BuildContext context, MilkProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Customer Account"),
        content: Text("Are you sure you want to delete ${_activeCustomer.name}? This will remove all their payment records, schedules, and custom overrides forever!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteCustomer(_activeCustomer.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to customer list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Deleted customer successfully!"),
                  backgroundColor: AppTheme.statusUnpaid,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusUnpaid),
            child: const Text("Delete Account"),
          ),
        ],
      ),
    );
  }
}
