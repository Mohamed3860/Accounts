import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/products_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.load();
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: 'أمانيا',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'sans-serif',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B6FE2),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            margin: EdgeInsets.zero,
            color: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF3B6FE2)),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const List<Widget> pages = [
    DashboardScreen(),
    CustomersScreen(),
    ProductsScreen(),
    InvoicesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: pages[index],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: index,
          onChanged: (value) => setState(() => index = value),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  static const List<({String label, IconData icon})> items = [
    (label: 'الرئيسية', icon: Icons.grid_view_rounded),
    (label: 'العملاء', icon: Icons.groups_2_rounded),
    (label: 'المنتجات', icon: Icons.shopping_bag_outlined),
    (label: 'الفواتير', icon: Icons.receipt_long_rounded),
    (label: 'الإعدادات', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == currentIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      selected ? const Color(0xFFEAF0FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 31,
                      color: selected
                          ? const Color(0xFF2F5ED7)
                          : const Color(0xFF111827),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
