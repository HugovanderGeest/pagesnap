import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/colors.dart';
import 'screens/library_screen.dart';
import 'l10n/app_localizations.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://mzfunjkzvszwtiqyorsk.supabase.co');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('nl', ''),
      ],
      home: const LibraryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
