import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';

enum LivelloCibo { niente, spuntino, pasto }

class SessionScreen extends StatefulWidget {
  final LivelloCibo livelloCibo;
  const SessionScreen({super.key, required this.livelloCibo});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  DateTime _sessionStart = DateTime.now();
  double _currentBAC = 0.0;
  String _selectedDrink = 'Small beer (330ml)';
  int _quantity = 1;
  bool _callingForHelp = false;
  Timer? _timer;

  static const _smsChannel = MethodChannel('buzzedbuddy/sms');
  double _peakBAC = 0;
  late final StoricoProvider _storicoProv;

  double _orangeThreshold = 0.5;
  double _redThreshold = 1.5;
  bool _isMinor = false;
  
  late LivelloCibo _currentLivelloCibo;

  // Fattore che riduce l'alcol assorbito in base al cibo. I coefficienti sono
  // EURISTICI (stime ragionevoli, non da letteratura): il cibo rallenta
  // l'assorbimento e abbassa il picco, ma questi numeri sono una nostra scelta.
  double get _foodFactor {
    switch (_currentLivelloCibo) {
      case LivelloCibo.niente:   return 1.0;
      case LivelloCibo.spuntino: return 0.9;
      case LivelloCibo.pasto:    return 0.8;
    }
  }

  final Map<String, Map<String, dynamic>> _drinksDb = {
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
    _storicoProv = Provider.of<StoricoProvider>(context, listen: false);
    _currentLivelloCibo = widget.livelloCibo;
    
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.livelloStress == 'high') {
      _redThreshold = 1.2;
    }
    _isMinor = user.isMinor;
    if (_isMinor) {
      _orangeThreshold = 0.3;
      if (_redThreshold > 1.0) _redThreshold = 1.0;
    }

    _initSessionState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _calculateBAC());
  }

  Future<void> _initSessionState() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    if (user.accountId != null) {
      final savedFood = prefs.getString('saved_food_factor_${user.accountId}');
      if (savedFood != null && widget.livelloCibo == LivelloCibo.niente) {
        setState(() {
          _currentLivelloCibo = LivelloCibo.values.firstWhere(
            (e) => e.toString() == savedFood, 
            orElse: () => LivelloCibo.niente
          );
        });
      } else {
        await prefs.setString('saved_food_factor_${user.accountId}', _currentLivelloCibo.toString());
      }
    }

    if (user.currentSessionDrinks.isNotEmpty) {
      final firstDrinkTimeStr = user.currentSessionDrinks.first['time'];
      if (firstDrinkTimeStr != null) {
        _sessionStart = DateTime.parse(firstDrinkTimeStr);
      }
    }

    _calculateBAC();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_peakBAC > 0) {
      _storicoProv.salvaSerata(_sessionStart, _peakBAC);
    }
    super.dispose();
  }

  void _calculateBAC() {
    final user = Provider.of<UserProvider>(context, listen: false);
    final now = DateTime.now();

    // Fattore di Widmark per sesso (frazione d'acqua corporea) e peso.
    final r = (user.gender?.toUpperCase() == 'M') ? 0.68 : 0.55;
    final w = user.weight ?? 70.0;

    // MODELLO. L'eliminazione dell'alcol e' di ordine zero: il corpo smaltisce
    // circa 0.15 g/L per ora finche' il tasso e' sopra zero, e NON di piu' se
    // hai piu' drink insieme. Quindi integriamo passo passo sugli orari reali
    // dei drink: tra un drink e il successivo sottraiamo l'eliminazione e non
    // scendiamo sotto zero, poi aggiungiamo il nuovo drink. Cosi' i drink presi
    // tardi non vengono sottostimati (vecchio bug dell'unico orologio dal primo
    // drink) e non si "smaltisce" alcol nei periodi in cui il tasso era gia' a
    // zero. L'assorbimento resta considerato istantaneo (semplificazione).
    // Il risultato e' trattato come g/L, di fatto il per mille (il sangue ha
    // densita' circa 1, quindi g/kg e g/L coincidono in pratica).
    final drinks = List<dynamic>.from(user.currentSessionDrinks);
    drinks.sort((a, b) {
      final ta = DateTime.tryParse(a['time'] ?? '') ?? now;
      final tb = DateTime.tryParse(b['time'] ?? '') ?? now;
      return ta.compareTo(tb);
    });

    double bac = 0.0;
    DateTime? lastTime;
    for (final drink in drinks) {
      final drinkTime = DateTime.tryParse(drink['time'] ?? '') ?? now;
      if (lastTime != null) {
        bac -= 0.15 * (drinkTime.difference(lastTime).inMinutes / 60);
        if (bac < 0) bac = 0;
      }
      final grams = (drink['ml'] as num) * (drink['abv'] as num) * 0.789 * _foodFactor;
      bac += grams / (w * r);
      lastTime = drinkTime;
    }
    // Eliminazione dall'ultimo drink fino ad adesso.
    if (lastTime != null) {
      bac -= 0.15 * (now.difference(lastTime).inMinutes / 60);
    }

    final nuovoBac = bac < 0 ? 0.0 : bac;
    setState(() => _currentBAC = nuovoBac);

    if (nuovoBac > _peakBAC) {
      _peakBAC = nuovoBac;
      _storicoProv.salvaSerata(_sessionStart, _peakBAC);
    }
  }

  void _addDrink() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final drink = _drinksDb[_selectedDrink]!;
    
    if (user.currentSessionDrinks.isEmpty) {
      _sessionStart = DateTime.now();
    }

    await user.addDrinkToSession({
      'name': _selectedDrink,
      'ml': drink['ml'] * _quantity,
      'abv': drink['abv'],
      'quantity': _quantity,
      'time': DateTime.now().toIso8601String(),
    });

    setState(() {
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
    if (_isMinor) {
      if (_level == 'green') return 'Reflect on what you\'re doing';
      if (_level == 'orange') {
        return 'Beware of your condition, consider stopping immediately';
      }
      return 'Stop now and ask for help';
    }
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
        ..showSnackBar(const SnackBar(
          content: Text('No emergency contact set. Please set one before your next session.'),
        ));
      return;
    }

    setState(() => _callingForHelp = true);

    String locationLink = 'Location unavailable';
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final permessoOk = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (serviceEnabled && permessoOk) {
        Position? position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
        locationLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      }
    } catch (e) {
      locationLink = 'Location unavailable';
    }

    final messageText =
        'Hi ${user.nomeContatto}, I\'m ${user.name}.\n\n'
        'I\'ve had too much to drink and need help.\n'
        'Can you come pick me up? I\'m here:\n'
        '$locationLink\n\n'
        '- Sent automatically by BuzzedBuddy';

    // INVIO SMS. Su Android proviamo l'invio automatico tramite un canale
    // nativo (richiede il codice nativo lato piattaforma e il permesso SMS);
    // su tutte le altre piattaforme apriamo l'app dei messaggi gia' compilata,
    // da inviare a mano. La posizione e' opzionale: se manca il permesso il
    // messaggio parte comunque con "Location unavailable".
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _smsChannel.invokeMethod('sendSmsViaDefaultApp', {
          'number': user.telefonoContatto,
          'body': messageText,
        });
      } else {
        final smsUri = Uri.parse('sms:${user.telefonoContatto}?body=${Uri.encodeComponent(messageText)}');
        await launchUrl(smsUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
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

  void _endNight() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    if (_peakBAC > 0) {
      _storicoProv.salvaSerata(_sessionStart, _peakBAC);
    }
    
    if (user.accountId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_food_factor_${user.accountId}');
    }

    await user.endTheNight();
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildEndButton() {
    return ElevatedButton.icon(
      onPressed: _endNight,
      icon: const Icon(Icons.nightlight_round),
      label: const Text('END THE NIGHT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: const Color.fromARGB(255, 255, 196, 0),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMinorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Remember, alcohol is not allowed at your age.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenLayout() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tonight'),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 196, 0)),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 196, 0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: const [SmallAppLogo()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isMinor) _buildMinorBanner(),
            _buildBacCard(),
            const SizedBox(height: 20),
            _buildDrinkInput(),
            const SizedBox(height: 20),
            _buildDrinkList(),
            const SizedBox(height: 20),
            _buildEndButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangeLayout() {
    final hoursLeft = _currentBAC > _orangeThreshold ? (_currentBAC - _orangeThreshold) / 0.15 : 0.0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tonight'),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 196, 0)),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 196, 0),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: const [SmallAppLogo()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade700, width: 3),
              ),
              child: _buildBacCard(),
            ),
            const SizedBox(height: 16),
            _isMinor
                ? _buildMinorBanner()
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hoursLeft > 1
                                ? 'You\'ve exceeded the legal driving limit.\nConsider stopping, it\'ll take over an hour to reach the safe zone.'
                                : 'You\'ve exceeded the legal driving limit.\nYou\'re above the safe driving threshold.',
                            style: const TextStyle(
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
            const SizedBox(height: 16),
            _buildDrinkInput(),
            const SizedBox(height: 16),
            _buildDrinkList(),
            const SizedBox(height: 20),
            _buildEndButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRedLayout() {
    // In rosso l'allarme non si scavalca: blocchiamo anche il tasto indietro di
    // sistema. L'unica uscita e' un testo piccolo in fondo alla schermata, che
    // noti solo se sei abbastanza lucido da cercarlo.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'WARNING',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${_currentBAC.toStringAsFixed(2)} g/L',
                        style: const TextStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _timeToSafe,
                        style: const TextStyle(fontSize: 22, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
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
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _callingForHelp ? null : _callForHelp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          minimumSize: const Size(double.infinity, 120),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _callingForHelp
                            ? CircularProgressIndicator(color: Colors.red.shade900)
                            : const Text(
                                'CALL FOR HELP',
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              // Unica via d'uscita, in fondo e volutamente discreta.
              TextButton(
                onPressed: _endNight,
                child: const Text(
                  'End the night',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('CURRENT BAC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(
            '${_currentBAC.toStringAsFixed(2)} g/L',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentBAC / 2.0).clamp(0.0, 1.0),
              minHeight: 16,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _timeToSafe,
            textAlign: TextAlign.center,
            style: _isMinor
                ? TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _level == 'green' ? Colors.black87 : Colors.red,
                  )
                : const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          DropdownButton<String>(
            value: _selectedDrink,
            isExpanded: true,
            items: _drinksDb.keys
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedDrink = val!),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                icon: const Icon(Icons.remove_circle, size: 36),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_quantity', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addDrink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: const Color.fromARGB(255, 255, 196, 0),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ADD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // INTEGRATO DEFINITIVAMENTE: Metodo completo di visualizzazione lista dei drink consumati
  Widget _buildDrinkList() {
    final user = Provider.of<UserProvider>(context);
    
    if (user.currentSessionDrinks.isEmpty) {
      return const Center(
          child: Text('No drinks added yet', style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: user.currentSessionDrinks.length,
      itemBuilder: (context, index) {
        final drink = user.currentSessionDrinks[index];
        final time = DateTime.parse(drink['time']);
        return Dismissible(
          key: ValueKey(drink['time']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove drink'),
                content: const Text('Are you sure? This will affect your BAC calculation.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            await user.removeDrinkFromSession(index);
            _calculateBAC();
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(drink['name']),
              subtitle: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
              trailing: Text('x${drink['quantity']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}
