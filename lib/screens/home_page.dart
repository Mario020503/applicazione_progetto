import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/providers/data_provider.dart'; 
import 'package:buzzed_buddy/screens/calendar_page.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';
import 'package:buzzed_buddy/screens/settings_page.dart';
import 'package:buzzed_buddy/screens/pre_session_page.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';
import 'package:buzzed_buddy/widgets/hr_graphic.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedDay = "2026-06-24";

  final List<String> _daysRange = [
    "2026-06-24",
    "2026-06-25",
    "2026-06-26",
    "2026-06-27",
    "2026-06-28",
    "2026-06-29"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchLucaHeartDataForDay(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context); 

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color.fromARGB(255, 255, 196, 0),
        actions: const [SmallAppLogo()],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome ${user.username ?? ''}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // DROPDOWN SELEZIONE GIORNO (Tradotto in Inglese)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButton<String>(
                  value: _selectedDay,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  items: _daysRange.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text("Data of: $day"), // Tradotto
                    );
                  }).toList(),
                  onChanged: (String? newDay) {
                    if (newDay != null) {
                      setState(() {
                        _selectedDay = newDay;
                      });
                      dataProvider.fetchLucaHeartDataForDay(newDay);
                    }
                  },
                ),
              ),
              const SizedBox(height: 25),

              if (dataProvider.isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else if (dataProvider.heartRates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No data recorded for $_selectedDay.", // Tradotto
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                )
              else ...[
                // Categoria HRV (Tradotto in Inglese)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Daily Average HRV: ${dataProvider.calculateHRV.toStringAsFixed(1)} ms", // Tradotto
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),

                // BOX GRAFICO
                Container(
                  height: 270,
                  width: MediaQuery.of(context).size.width * 0.92,
                  padding: const EdgeInsets.only(top: 24, bottom: 12, right: 24, left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPlotHR(
                    hrData: dataProvider.hrvPoints,
                    selectedDate: DateTime.parse(_selectedDay),
                  ), 
                ),
              ],

              const SizedBox(height: 40),
              Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PreSessionScreen()),
                    );
                  },
                  child: const Text(
                    "Let's start", // Tradotto
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Settings and activities')),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final storico = Provider.of<StoricoProvider>(context, listen: false);
    try { await storico.clear(); } catch (_) {}
    await user.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}