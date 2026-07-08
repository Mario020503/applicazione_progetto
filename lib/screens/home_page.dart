import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/providers/data_provider.dart'; 
import 'package:buzzed_buddy/screens/calendar_page.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';
import 'package:buzzed_buddy/screens/settings_page.dart';
import 'package:buzzed_buddy/screens/pre_session_page.dart';
import 'package:buzzed_buddy/screens/session_page.dart'; 
import 'package:buzzed_buddy/widgets/small_app_logo.dart';
import 'package:buzzed_buddy/widgets/hrv_graphic.dart';
import 'package:buzzed_buddy/widgets/stress_graphic.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Riga di debug in Home (baseline, HRV e stress del giorno): utile per
  // scegliere i giorni da mostrare in demo. Tenere false per la presentazione,
  // rimettere true quando serve individuare i giorni con stress alto.
  static const bool _showDebug = false;

  String _selectedDay = "2026-06-24";
  int _selectedIndex = 0;

  final List<String> _daysRange = [
    "2026-06-24",
    "2026-06-25",
    "2026-06-26",
    "2026-06-27",
    "2026-06-28",
    "2026-06-29",
    "2026-06-30", 
    "2026-07-01",
    "2026-07-02",
    "2026-07-03",
    "2026-07-04",
    "2026-07-05",
    "2026-07-06",
    "2026-07-07",
    "2026-07-08",
    "2026-07-09",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dp = Provider.of<DataProvider>(context, listen: false);
      await dp.fetchLucaHeartDataForDay(_selectedDay);
      await dp.computeBaselineIfNeeded();
    });
  }

  // SPIEGAZIONE SCIENTIFICA AGGIORNATA DELL'HRV
  void _showHrvInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0E9C94)),
                  SizedBox(width: 8),
                  Text(
                    'What is HRV?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Heart Rate Variability (HRV) is the small variation, in milliseconds, in the time between consecutive heartbeats. Higher variability usually reflects a more rested, recovered state.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  'How we estimate it:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                Text(
                  'We use RMSSD, a standard HRV measure that mainly reflects parasympathetic (vagal) activity, the rest and recover side of your nervous system. Since the wearable gives averaged heart rate rather than every single beat, our value is a close estimate, not a clinical measurement.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  'Hourly view:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                Text(
                  'Readings are grouped into short windows and averaged hour by hour, so the chart shows a clean trend instead of noisy single spikes.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // SPIEGAZIONE SCIENTIFICA AGGIORNATA DELLO STRESS STILE GARMIN (FIRSTBEAT)
  void _showStressInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.waves, color: Color(0xFF0E9C94)),
                  SizedBox(width: 8),
                  Text(
                    'What is Stress?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This is our own estimate of your stress level, not a medical measurement.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  'How it works:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                Text(
                  'We look at your heart rate variability and at how much your heart rate is above your resting level, and turn them into a single score, from calm at the low end to high strain at the top.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  '15 minute view:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                Text(
                  'The timeline is split into 15 minute segments. When the device is taken off and there is no data, that segment is left blank instead of showing an invented value.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final storico = Provider.of<StoricoProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context); 

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0
              ? 'Home'
              : _selectedIndex == 1
                  ? 'Calendar'
                  : 'Settings',
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 196, 0),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 196, 0),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: const [SmallAppLogo()],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await dataProvider.fetchLucaHeartDataForDay(_selectedDay);
              await dataProvider.computeBaselineIfNeeded();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Welcome back, ${user.username ?? ''}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDailyNudge(storico),

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
                            child: Text("Data of: $day"),
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
                          "No data recorded for $_selectedDay.",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      )
                    else ...[
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E9C94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Average HRV: ${dataProvider.calculateHRV.toStringAsFixed(1)} ms",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () => _showHrvInfoDialog(context),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E9C94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Resting HR: ${dataProvider.restingHrValue} BPM",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 270,
                        width: MediaQuery.of(context).size.width * 0.92,
                        padding: const EdgeInsets.only(top: 24, bottom: 12, right: 24, left: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomPlotHR(
                          hrData: dataProvider.hrvPoints,
                          selectedDate: DateTime.parse(_selectedDay),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_showDebug)
                        Text(
                          'DEBUG · baseline ${dataProvider.baseline?.toStringAsFixed(1) ?? '—'} ms · ${dataProvider.baselineDaysUsed} days · '
                          'today ${dataProvider.calculateHRV.toStringAsFixed(1)} ms → ${dataProvider.stressForSelectedDay().toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      const SizedBox(height: 12),
                      
                      GestureDetector(
                        onTap: () => _showStressInfoDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E9C94),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Stress Profile',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 230,
                        width: MediaQuery.of(context).size.width * 0.92,
                        padding: const EdgeInsets.only(top: 16, bottom: 8, right: 16, left: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: StressPlot(
                          points: dataProvider.stressPoints,
                          emptyMessage: 'No stress data for this day',
                          isLoading: dataProvider.isBaselineLoading,
                          showEmptyLoading: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      if (userProvider.currentSessionDrinks.isNotEmpty) {
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const SessionScreen(livelloCibo: LivelloCibo.niente),
                          ),
                        );
                        return;
                      }
                      await dataProvider.computeBaselineIfNeeded();
                      final stress = dataProvider.stressForSelectedDay();
                      await userProvider.saveStressLevel(stress);
                      final warnings = <String>[];
                      if (storico.bevutoIeri) {
                        warnings.add('You drank yesterday. Your body may still be recovering.');
                      }
                      if (stress == 'high') {
                        warnings.add('You seem stressed today. Alcohol tends to hit harder when you are stressed.');
                      }
                      if (warnings.isNotEmpty) {
                        final proceed = await _showPreStartWarning(warnings);
                        if (proceed != true) return;
                      }
                      navigator.push(
                        MaterialPageRoute(builder: (_) => const PreSessionScreen()),
                      );
                    },
                    child: const Text(
                      "Let's start",
                      style: TextStyle(color: Color.fromARGB(255, 255, 196, 0), fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const CalendarPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color.fromARGB(255, 255, 196, 0),
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          if (index == 3) {
            _confirmAndLogout(context);
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext ctx) async {
    final doLogout = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Go back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Logout', style: TextStyle(color: Color.fromARGB(255, 255, 196, 0))),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (doLogout == true) {
      _logout(context);
    }
  }

  void _logout(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final storico = Provider.of<StoricoProvider>(context, listen: false);
    await user.logout();
    await storico.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool?> _showPreStartWarning(List<String> messages) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Before you start'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•   ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(m)),
                  ],
                ),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: const Color.fromARGB(255, 255, 196, 0),
              minimumSize: const Size(150, 48),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue anyway', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // Elogio positivo: mostrato SOLO quando la serie pulita è reale e sensata.
  // - storico non vuoto: c'è almeno una serata registrata, quindi i giorni
  //   puliti sono veri (non "zero dati", che darebbe il valore-tetto 366);
  // - < 365: esclude comunque il valore-tetto per sicurezza;
  // - >= 3: elogiamo solo una serie che vale la pena.
  Widget _buildDailyNudge(StoricoProvider storico) {
    final giorni = storico.giorniPuliti;
    if (storico.storico.isEmpty || giorni < 3 || giorni >= 365) {
      return const SizedBox.shrink();
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.92,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$giorni days without drinking, nice work!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
