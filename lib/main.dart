import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/milk_provider.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/backup_restore_screen.dart';

void main() {
  // Ensure widget bindings are initialized (needed for path_provider / sqlite / JSON files)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MilkProvider(),
      child: MaterialApp(
        title: 'Milk Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Auto adapt based on device settings
        home: const NavigationShell(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomerListScreen(),
    MonthlyReportScreen(),
    BackupRestoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < _screens.length ? _currentIndex : 0,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index.clamp(0, _screens.length - 1);
            });
          },
          backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: isDark
              ? AppTheme.textSecondaryDark
              : AppTheme.textSecondaryLight,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              activeIcon: Icon(Icons.water_drop),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Customers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Ledgers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.backup_outlined),
              activeIcon: Icon(Icons.backup),
              label: 'Backup',
            ),
          ],
        ),
      ),
    );
  }
}
