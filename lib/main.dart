import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/providers/data_provider.dart';
import 'package:buzzed_buddy/screens/splash_page.dart';

TextTheme _boldItalic(TextTheme base) {
  TextStyle? bi(TextStyle? style) =>
      style?.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);

  return base.copyWith(
    displayLarge: bi(base.displayLarge),
    displayMedium: bi(base.displayMedium),
    displaySmall: bi(base.displaySmall),
    headlineLarge: bi(base.headlineLarge),
    headlineMedium: bi(base.headlineMedium),
    headlineSmall: bi(base.headlineSmall),
    titleLarge: bi(base.titleLarge),
    titleMedium: bi(base.titleMedium),
    titleSmall: bi(base.titleSmall),
    bodyLarge: bi(base.bodyLarge),
    bodyMedium: bi(base.bodyMedium),
    bodySmall: bi(base.bodySmall),
    labelLarge: bi(base.labelLarge),
    labelMedium: bi(base.labelMedium),
    labelSmall: bi(base.labelSmall),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_GB', null);
  Intl.defaultLocale = 'en_GB';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StoricoProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()), 
      ],
      child: const MyApp(),
    ),
  );
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuzzedBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 196, 0),
        ),
        textTheme: _boldItalic(GoogleFonts.poppinsTextTheme()),
        useMaterial3: true,
      ),
      home: const AppEntry(),
    );
  }
}
 
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
  @override
  State<AppEntry> createState() => _AppEntryState();
}
 
class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
 
  @override
  void initState() {
    super.initState();
    _init();
  }
 
  Future<void> _init() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final storicoProvider = Provider.of<StoricoProvider>(context, listen: false);

      await userProvider.loadFromSharedPreferences();

      if (userProvider.accountId != null && userProvider.accountId!.isNotEmpty) {
        await storicoProvider.loadForAccount(userProvider.accountId);
      } else {
        await storicoProvider.clear();
      }
    } catch (_) {
      
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }
    return const SplashScreen();
  }
}
