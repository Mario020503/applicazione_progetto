import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/session_page.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';

// ============================================================
// PRE-SESSION SCREEN — Schermata prima dell'inizio della serata.
// ============================================================

class PreSessionScreen extends StatefulWidget {
  const PreSessionScreen({super.key});

  @override
  State<PreSessionScreen> createState() => _PreSessionScreenState();
}

class _PreSessionScreenState extends State<PreSessionScreen> {

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();

  // null = nessuna scelta ancora fatta → obbliga l'utente a decidere
  LivelloCibo? _livelloCibo;

  @override
  void initState() {
    super.initState();
    // CONTROLLO DI SICUREZZA PER SINO-CORSO DELLA SERATA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Se ci sono già dei drink registrati sul telefono, salta tutto!
      if (userProvider.currentSessionDrinks.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SessionScreen(livelloCibo: LivelloCibo.niente),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    nomeController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  // Valida i dati, salva il contatto e avvia la sessione
  Future<void> _startSession() async {
    final nome = nomeController.text.trim();
    final localPhone = telefonoController.text.trim();

    if (nome.isEmpty || localPhone.isEmpty) {
      _showSnackBar('Enter your emergency contact name and phone number');
      return;
    }
    if (localPhone.length < 9) {
      _showSnackBar('Enter a valid phone number');
      return;
    }
    
    final telefono = '+39$localPhone';
    if (_livelloCibo == null) {
      _showSnackBar('Tell us how much you have eaten');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm emergency contact',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Please confirm that the emergency contact you entered is correct. We will only use it to reach that person if you ask for help tonight, and it will be deleted automatically when you end the night.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I confirm'),
          ),
        ],

      ),
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    // Salva il contatto di emergenza nel Provider / SharedPreferences
    final user = Provider.of<UserProvider>(context, listen: false);
    await user.saveEmergencyContact(nome: nome, telefono: telefono);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionScreen(livelloCibo: _livelloCibo!),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text('Before you start'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- Sezione contatto di emergenza ---
            const Text(
              'Emergency contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Who should we message if things go wrong tonight?',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),

            _field(nomeController, 'Contact name', 'e.g. Marco'),
            const SizedBox(height: 12),
            _field(telefonoController, 'Phone number', 'e.g. 3331234567', phone: true),

            const SizedBox(height: 28),

            // --- Sezione cibo ---
            const Text(
              'Have you eaten?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Food slows alcohol absorption and lowers your peak.',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              children: [
                _foodChip('Nothing', LivelloCibo.niente),
                _foodChip('A snack', LivelloCibo.spuntino),
                _foodChip('Full meal', LivelloCibo.pasto),
              ],
            ),

            const SizedBox(height: 36),

            // --- Pulsante di avvio ---
            Center(
              child: ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                  minimumSize: const Size(250, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'START THE NIGHT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _foodChip(String label, LivelloCibo livello) {
    final selected = _livelloCibo == livello;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _livelloCibo = livello),
      selectedColor: Colors.black,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint, {bool phone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        inputFormatters: phone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3),
          ),
          labelText: label,
          hintText: hint,
          prefixText: phone ? '+39 ' : null,
        ),
      ),
    );
  }
}
