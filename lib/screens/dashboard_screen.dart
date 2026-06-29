import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _MockCustomer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double defaultQuantity;
  final List<DateTime> joinedDates;
  final List<DateTime> pausedDates;

  const _MockCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.defaultQuantity,
    required this.joinedDates,
    required this.pausedDates,
  });

  bool hasJoinedOn(DateTime date) {
    return joinedDates.any((item) => _sameDay(item, date));
  }

  bool isPausedOn(DateTime date) {
    return pausedDates.any((item) => _sameDay(item, date));
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_MockCustomer> _customers = [
    _MockCustomer(
      id: '1',
      name: 'Asha Khan',
      phone: '9876543210',
      address: 'Main Road',
      defaultQuantity: 2.0,
      joinedDates: [DateTime(2026, 6, 1)],
      pausedDates: [],
    ),
    _MockCustomer(
      id: '2',
      name: 'Ravi Sharma',
      phone: '9123456780',
      address: 'Park Street',
      defaultQuantity: 1.5,
      joinedDates: [DateTime(2026, 6, 1)],
      pausedDates: [DateTime(2026, 6, 15)],
    ),
    _MockCustomer(
      id: '3',
      name: 'Neha Verma',
      phone: '9988776655',
      address: 'Lake View',
      defaultQuantity: 3.0,
      joinedDates: [DateTime(2026, 6, 1)],
      pausedDates: [],
    ),
    _MockCustomer(
      id: '4',
      name: 'Kiran Patel',
      phone: '9765432109',
      address: 'Old Town',
      defaultQuantity: 2.5,
      joinedDates: [DateTime(2026, 6, 1)],
      pausedDates: [],
    ),
  ];

  final Map<String, double> _overrides = {};
  final Set<String> _delivered = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _itemKey(String customerId, DateTime date) {
    return '$customerId-${_dateKey(date)}';
  }

  double _getQuantityForDate(_MockCustomer customer, DateTime date) {
    final key = _itemKey(customer.id, date);
    if (_overrides.containsKey(key)) {
      return _overrides[key]!;
    }

    if (customer.hasJoinedOn(date) && !customer.isPausedOn(date)) {
      return customer.defaultQuantity;
    }

    return 0.0;
  }

  bool _isDeliveredOnDate(String customerId, DateTime date) {
    return _delivered.contains(_itemKey(customerId, date));
  }

  void _toggleDelivery(_MockCustomer customer, DateTime date) {
    setState(() {
      final key = _itemKey(customer.id, date);
      if (_delivered.contains(key)) {
        _delivered.remove(key);
      } else {
        _delivered.add(key);
      }
    });
  }

  void _recordOverride(_MockCustomer customer, DateTime date, double value) {
    setState(() {
      final key = _itemKey(customer.id, date);
      if (value <= 0) {
        _overrides.remove(key);
      } else {
        _overrides[key] = value;
      }
    });
  }

  void _markAllDeliveredForDate(DateTime date) {
    setState(() {
      for (final customer in _customers) {
        final qty = _getQuantityForDate(customer, date);
        final hasJoined = customer.hasJoinedOn(date);
        final isPaused = customer.isPausedOn(date);
        if (hasJoined && !isPaused && qty > 0) {
          _delivered.add(_itemKey(customer.id, date));
        }
      }
    });
  }

  double _getTotalDemand(DateTime date) {
    double total = 0.0;
    for (final customer in _customers) {
      final qty = _getQuantityForDate(customer, date);
      final hasJoined = customer.hasJoinedOn(date);
      final isPaused = customer.isPausedOn(date);
      if (hasJoined && !isPaused) {
        total += qty;
      }
    }
    return total;
  }

  int _getDeliveredCountForDate(DateTime date) {
    int count = 0;
    for (final customer in _customers) {
      if (_isDeliveredOnDate(customer.id, date)) {
        count++;
      }
    }
    return count;
  }

  int _getTotalActiveDeliveriesForDate(DateTime date) {
    int count = 0;
    for (final customer in _customers) {
      final hasJoined = customer.hasJoinedOn(date);
      final isPaused = customer.isPausedOn(date);
      if (hasJoined && !isPaused) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((customer) {
      final nameMatches = customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = customer.phone.contains(_searchQuery);
      return nameMatches || phoneMatches;
    }).toList();

    final totalDemand = _getTotalDemand(_selectedDate);
    final deliveredCount = _getDeliveredCountForDate(_selectedDate);
    final totalActive = _getTotalActiveDeliveriesForDate(_selectedDate);
    final allDelivered = totalActive > 0 && deliveredCount >= totalActive;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: AppTheme.gradientHeader(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY DISTRIBUTION',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Milk Tracker',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (totalActive > 0)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton.icon(
                            onPressed: allDelivered ? null : () => _markAllDeliveredForDate(_selectedDate),
                            icon: Icon(
                              allDelivered ? Icons.check_circle : Icons.done_all,
                              size: 18,
                            ),
                            label: Text(
                              allDelivered ? 'All Done!' : 'Mark All',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allDelivered
                                  ? AppTheme.statusPaid
                                  : Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeDate(-1),
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                          label: Text(
                            DateFormat('EEE, d MMM y').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeDate(1),
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.water_drop,
                          title: 'Total Litres',
                          value: '${totalDemand.toStringAsFixed(1)} L',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDeliveryProgressCard(
                          delivered: deliveredCount,
                          total: totalActive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search customer...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(context, filteredCustomers[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProgressCard({required int delivered, required int total}) {
    final progress = total == 0 ? 0.0 : delivered / total;
    final allDone = total > 0 && delivered >= total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.check_circle : Icons.local_shipping_outlined,
                color: allDone ? AppTheme.statusPaid : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                allDone ? 'All Delivered!' : 'Delivered',
                style: TextStyle(
                  color: allDone ? AppTheme.statusPaid : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$delivered',
                style: TextStyle(
                  color: allDone ? AppTheme.statusPaid : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ' / $total',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppTheme.statusPaid : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No customers match your search'
                : 'No customers yet.\nGo to Customers tab to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, _MockCustomer customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = _getQuantityForDate(customer, _selectedDate);
    final normDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final hasJoined = customer.hasJoinedOn(normDate);
    final isPaused = customer.isPausedOn(normDate);
    final hasOverride = _overrides.containsKey(_itemKey(customer.id, normDate));
    final isDelivered = _isDeliveredOnDate(customer.id, _selectedDate);
    final canDeliver = hasJoined && !isPaused && qty > 0;

    final cardDecoration = canDeliver && isDelivered
        ? BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.statusPaid.withOpacity(0.6), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.statusPaid.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : AppTheme.glassCard(context) as BoxDecoration;

    Widget statusBadge;
    Color qtyColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    if (!hasJoined) {
      statusBadge = _badge('Not Joined', AppTheme.statusPaused);
      qtyColor = AppTheme.statusPaused;
    } else if (isPaused) {
      statusBadge = _badge('Paused', AppTheme.statusPaused);
      qtyColor = AppTheme.statusPaused;
    } else if (hasOverride) {
      statusBadge = _badge('Edited', AppTheme.statusPartial);
      qtyColor = AppTheme.statusPartial;
    } else {
      statusBadge = _badge('Default', AppTheme.statusPaid);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          statusBadge,
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${customer.phone}  •  ${customer.address}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${qty.toStringAsFixed(1)} L',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: qtyColor,
                      ),
                    ),
                    if (hasOverride && !isPaused && hasJoined)
                      Text(
                        'Def: ${customer.defaultQuantity.toStringAsFixed(1)}L',
                        style: const TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                if (canDeliver)
                  GestureDetector(
                    onTap: () => _toggleDelivery(customer, _selectedDate),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? AppTheme.statusPaid
                            : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isDelivered
                            ? [
                                BoxShadow(
                                  color: AppTheme.statusPaid.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        isDelivered ? Icons.check_rounded : Icons.local_shipping_outlined,
                        color: isDelivered ? Colors.white : Colors.grey,
                        size: 22,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.block,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (canDeliver) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isDelivered
                          ? Row(
                              key: const ValueKey('delivered'),
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppTheme.statusPaid),
                                const SizedBox(width: 5),
                                const Text(
                                  'Milk delivered ✓',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.statusPaid,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('pending'),
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pending delivery — tap ✓ to confirm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
            if (hasJoined) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isPaused)
                    const Text(
                      'Paused — no delivery this period',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.statusPaused,
                      ),
                    )
                  else ...[
                    TextButton.icon(
                      onPressed: () {
                        if (qty > 0) {
                          _recordOverride(customer, _selectedDate, 0.0);
                        } else {
                          _recordOverride(customer, _selectedDate, customer.defaultQuantity);
                        }
                      },
                      icon: Icon(
                        qty > 0 ? Icons.cancel_outlined : Icons.restore,
                        size: 15,
                        color: qty > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid,
                      ),
                      label: Text(
                        qty > 0 ? 'Skip' : 'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          color: qty > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    Row(
                      children: [
                        _adjustBtn(Icons.remove, () {
                          final newQty = (qty - 0.5 < 0) ? 0.0 : qty - 0.5;
                          _recordOverride(customer, _selectedDate, newQty);
                        }),
                        const SizedBox(width: 6),
                        _adjustBtn(Icons.add, () {
                          _recordOverride(customer, _selectedDate, qty + 0.5);
                        }),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => _showExactQtySheet(context, customer, qty),
                          icon: const Icon(Icons.edit_note, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            padding: const EdgeInsets.all(6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          tooltip: 'Set exact quantity',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: const Text(
                  "Customer hasn't joined yet on this date.",
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.statusPaused,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _adjustBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }

  void _showExactQtySheet(BuildContext context, _MockCustomer customer, double currentQty) {
    final controller = TextEditingController(text: currentQty.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Custom Delivery',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Quantity for ${customer.name} on ${DateFormat('d MMMM').format(_selectedDate)}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (Liters)',
                      suffixText: 'L',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _recordOverride(customer, _selectedDate, 0.0);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusUnpaid,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  ),
                  child: const Text('Set 0L'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null && val >= 0) {
                      _recordOverride(customer, _selectedDate, val);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
