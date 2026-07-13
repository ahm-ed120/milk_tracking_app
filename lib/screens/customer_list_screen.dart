import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/milk_provider.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milkProvider = Provider.of<MilkProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (milkProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredCustomers = milkProvider.customers.where((customer) {
      final nameMatches = customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = customer.phone.contains(_searchQuery);
      return nameMatches || phoneMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Customers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Customer Count Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search customer...",
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer List
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 72,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? "No customers found"
                                : "No customers added yet!\nTap the + button to add one.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return _buildCustomerItem(context, customer, milkProvider);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, milkProvider),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // Builder for customer cards
  Widget _buildCustomerItem(
    BuildContext context,
    Customer customer,
    MilkProvider provider,
  ) {
    final remaining = provider.getRemainingBalanceForCustomer(customer);
    final status = provider.getPaymentStatusForCustomer(customer);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeColor;
    if (status == 'Paid') {
      badgeColor = AppTheme.statusPaid;
    } else if (status == 'Partial') {
      badgeColor = AppTheme.statusPartial;
    } else {
      badgeColor = AppTheme.statusUnpaid;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerDetailScreen(customer: customer),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Avatar representation
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const SizedBox(width: 8),
                          // Status badge
                          _buildBadge(status, badgeColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${customer.phone}  •  ${customer.address}",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop_outlined, 
                            size: 14, 
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${customer.defaultQuantity}L",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.currency_exchange_outlined, 
                            size: 14, 
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "Rs. ${customer.rate.toStringAsFixed(0)}/L",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Balance block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Balance",
                      style: TextStyle(fontSize: 10),
                    ),
                    Text(
                      "Rs. ${remaining.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: remaining > 0 ? AppTheme.statusUnpaid : AppTheme.statusPaid,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Dialog to Add a Customer
  void _showAddCustomerDialog(BuildContext context, MilkProvider provider) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String address = '';
    double defaultQuantity = 1.0;
    double rate = 220.0;
    DateTime joinDate = DateTime.now();

    final dateController = TextEditingController(
      text: DateFormat('d MMMM y').format(joinDate)
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 
                24, 
                24, 
                MediaQuery.of(context).viewInsets.bottom + 24
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Customer",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                        onSaved: (val) => name = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.trim().isEmpty ? "Phone number is required" : null,
                        onSaved: (val) => phone = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Address",
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Address is required" : null,
                        onSaved: (val) => address = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Daily Milk (Liters)",
                                prefixIcon: Icon(Icons.water_drop),
                                suffixText: "L",
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              initialValue: "1.0",
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
                              decoration: const InputDecoration(
                                labelText: "Rate per Liter",
                                prefixIcon: Icon(Icons.currency_exchange),
                                suffixText: "Rs",
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              initialValue: "220",
                              validator: (val) {
                                final r = double.tryParse(val ?? '');
                                return (r == null || r <= 0) ? "Must be > 0" : null;
                              },
                              onSaved: (val) => rate = double.parse(val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Join Date Picker Form field
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Join Date (Start of Billing)",
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: joinDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                              joinDate = picked;
                              dateController.text = DateFormat('d MMMM y').format(joinDate);
                            });
                          }
                        },
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
                                provider.addCustomer(
                                  name: name,
                                  phone: phone,
                                  address: address,
                                  defaultQuantity: defaultQuantity,
                                  rate: rate,
                                  joinDate: joinDate,
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Added Customer $name successfully!"),
                                    backgroundColor: AppTheme.statusPaid,
                                  ),
                                );
                              }
                            },
                            child: const Text("Create Customer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
