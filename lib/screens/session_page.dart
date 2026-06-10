import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
<<<<<<< HEAD
import 'package:buzzed_buddy/screens/provider_page.dart';


// SESSION SCREEN — Schermata principale durante la serata.
// Traccia il BAC in tempo reale usando la formula di Widmark.
// Legge peso e sesso dal UserProvider (salvati durante la registrazione).
//
// SOGLIE DI PERICOLO (si adattano al livello di stress del giorno):
//   Stress normale → arancione a 0.5 g/L, rosso a 1.5 g/L
//   Stress alto    → arancione a 0.3 g/L, rosso a 1.2 g/L
//  Livello di stress verrà impostato dopo aver creato la HomePage
//
// PULSANTE CHIAMA AIUTO:
//   Legge nomeContatto e telefonoContatto dal Provider.
//   Questi dovranno essere impostati negli schermi appositi 


=======
import 'package:buzzed_buddy/providers/user_provider.dart';
 
>>>>>>> 306e06eafbed07d0e6b4835e46da1e1c11796a74
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
 
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}
 
class _SessionScreenState extends State<SessionScreen> {
 
  DateTime _sessionStart = DateTime.now();
  final List<Map<String, dynamic>> _drinks = [];
 
  double _currentBAC = 0.0;
  String _selectedDrink = 'Small beer (330ml)';
  int _quantity = 1;
  bool _callingForHelp = false;
  Timer? _timer;
 
  double _orangeThreshold = 0.5;
  double _redThreshold = 1.5;
 
  final Map<String, Map<String, dynamic>> _drinks_db = {
    'Small beer (330ml)':       {'ml': 330.0, 'abv': 0.05},
    'Medium beer (500ml)':      {'ml': 500.0, 'abv': 0.05},
    'Large beer (660ml)':       {'ml': 660.0, 'abv': 0.05},
    'Strong beer (330ml)':      {'ml': 330.0, 'abv': 0.08},
    'Wine (125ml glass)':       {'ml': 125.0, 'abv': 0.12},
    'Prosecco (120ml glass)':   {'ml': 120.0, 'abv': 0.11},
    'Aperol Spritz':            {'ml': 200.0, 'abv': 0.11},
    'Gin Tonic / Gin Lemon':    {'ml': 250.0, 'abv': 0.10},
    'Vodka Lemon / Vodka Soda': {'ml': 250.0, 'abv': 0.10},
    'Negroni':                  {'ml': 100.0, 'abv': 0.25},
    'Shot (40ml)':              {'ml': 40.0,  'abv': 0.40},
  };
 
  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.livelloStress == 'high') {
      _orangeThreshold = 0.3;
      _redThreshold = 1.2;
    }
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _calculateBAC());
  }
 
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
 
  // Formula di Widmark: BAC = (grammi alcol / (weight × r)) - (0.15 × ore)
  void _calculateBAC() {
    final user = Provider.of<UserProvider>(context, listen: false);
    final hoursElapsed = DateTime.now().difference(_sessionStart).inMinutes / 60;
 
    // Fattore r di Widmark: 0.68 per M, 0.55 per F
    final r = (user.gender?.toUpperCase() == 'M') ? 0.68 : 0.55;
    final w = user.weight ?? 70.0;
 
    // 0.789 = densità dell'alcol etilico in g/ml
    double totalGrams = 0;
    for (final drink in _drinks) {
      totalGrams += drink['ml'] * drink['abv'] * 0.789;
    }
 
    if (totalGrams == 0) {
      setState(() => _currentBAC = 0);
      return;
    }
 
    double bac = (totalGrams / (w * r)) - (0.15 * hoursElapsed);
    setState(() => _currentBAC = bac < 0 ? 0 : bac);
  }
 
  void _addDrink() {
    final drink = _drinks_db[_selectedDrink]!;
    setState(() {
      if (_drinks.isEmpty) _sessionStart = DateTime.now();
      _drinks.add({
        'name': _selectedDrink,
        'ml': drink['ml'] * _quantity,
        'abv': drink['abv'],
        'quantity': _quantity,
        'time': DateTime.now(),
      });
      _quantity = 1;
    });
    _calculateBAC();
  }
 
  String get _level {
    if (_currentBAC < _orangeThreshold) return 'green';
    if (_currentBAC < _redThreshold) return 'orange';
    return 'red';
  }
 
  String get _timeToSafe {
    if (_currentBAC <= _orangeThreshold) return 'You\'re in the safe zone';
    final hoursLeft = (_currentBAC - _orangeThreshold) / 0.15;
    final hours = hoursLeft.floor();
    final minutes = ((hoursLeft - hours) * 60).round();
    return 'Safe zone in ${hours}h ${minutes}min';
  }
 
  Future<void> _callForHelp() async {
    final user = Provider.of<UserProvider>(context, listen: false);
 
    if (user.telefonoContatto == null || user.nomeContatto == null) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('No emergency contact set. Please set one before your next session.'),
        ));
      return;
    }
 
    setState(() => _callingForHelp = true);
 
    String locationLink = 'Location unavailable';
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
      locationLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (e) {
      locationLink = 'Location unavailable';
    }
 
    final message = Uri.encodeComponent(
      'Hi ${user.nomeContatto}, I\'m ${user.name}.\n\n'
      'I\'ve had too much to drink and need help.\n'
      'Can you come pick me up? I\'m here:\n'
      '$locationLink\n\n'
      '- Sent automatically by BuzzedBuddy',
    );
 
    final smsUri = Uri.parse('sms:${user.telefonoContatto}?body=$message');
 
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not open SMS app')));
      }
    }
 
    if (mounted) setState(() => _callingForHelp = false);
  }
 
  @override
  Widget build(BuildContext context) {
    if (_level == 'red') return _buildRedLayout();
    if (_level == 'orange') return _buildOrangeLayout();
    return _buildGreenLayout();
  }
 
  Widget _buildGreenLayout() {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text('Tonight'),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBacCard(),
            SizedBox(height: 20),
            _buildDrinkInput(),
            SizedBox(height: 20),
            _buildDrinkList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
 
  Widget _buildOrangeLayout() {
    final hoursLeft = _currentBAC > _orangeThreshold
        ? (_currentBAC - _orangeThreshold) / 0.15
        : 0.0;
 
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text('Tonight'),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade700, width: 3),
              ),
              child: _buildBacCard(),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hoursLeft > 1
                          ? 'You\'ve exceeded the legal driving limit.\nConsider stopping — it\'ll take over an hour to reach the safe zone.'
                          : 'You\'ve exceeded the legal driving limit.\nYou\'re above the safe driving threshold.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildDrinkInput(),
            SizedBox(height: 16),
            _buildDrinkList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
 
  Widget _buildRedLayout() {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WARNING',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '${_currentBAC.toStringAsFixed(2)} g/L',
                  style: TextStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  _timeToSafe,
                  style: TextStyle(fontSize: 22, color: Colors.white70),
                ),
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'STOP DRINKING IMMEDIATELY.\nAsk someone you trust for help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _callingForHelp ? null : _callForHelp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    minimumSize: Size(double.infinity, 120),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _callingForHelp
                      ? CircularProgressIndicator(color: Colors.red.shade900)
                      : Text(
                          'CALL FOR HELP',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildBacCard() {
    Color cardColor = _level == 'green' ? Colors.green.shade100 : Colors.orange.shade100;
    Color barColor = _level == 'green' ? Colors.green : Colors.orange;
 
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('CURRENT BAC',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(
            '${_currentBAC.toStringAsFixed(2)} g/L',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentBAC / 2.0).clamp(0.0, 1.0),
              minHeight: 16,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          SizedBox(height: 8),
          Text(_timeToSafe, style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
 
  Widget _buildDrinkInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          DropdownButton<String>(
            value: _selectedDrink,
            isExpanded: true,
            items: _drinks_db.keys
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedDrink = val!),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                icon: Icon(Icons.remove_circle, size: 36),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_quantity',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: Icon(Icons.add_circle, size: 36),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addDrink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Color.fromARGB(255, 255, 196, 0),
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('ADD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
 
  Widget _buildDrinkList() {
    if (_drinks.isEmpty) {
      return Center(
          child: Text('No drinks added yet', style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _drinks.length,
      itemBuilder: (context, index) {
        final drink = _drinks[index];
        final time = drink['time'] as DateTime;
        return Dismissible(
          key: Key('$index-${time.toString()}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Remove drink'),
                content: Text('Are you sure? This will affect your BAC calculation.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            setState(() => _drinks.removeAt(index));
            _calculateBAC();
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(drink['name']),
              subtitle: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}'),
              trailing: Text('x${drink['quantity']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}