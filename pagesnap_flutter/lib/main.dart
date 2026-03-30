import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme/colors.dart';
import 'screens/library_screen.dart';
import 'screens/account_screen.dart';

const supabaseUrl = const String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://mzfunjkzvszwtiqyorsk.supabase.co');
const supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16ZnVuamt6dnN6d3RpcXlvcnNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMTc5NTMsImV4cCI6MjA4NzY5Mzk1M30.e4deWQ5W3s0Nwa-t8fhL-UGANSVG70IGqN81JBERk7o');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const PeruseApp());
}

class PeruseApp extends StatelessWidget {
  const PeruseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peruse',
      theme: AppTheme.lightTheme,
      home: const MainTabs(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({Key? key}) : super(key: key);

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    LibraryScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textDim,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.library),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
