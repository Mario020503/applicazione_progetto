import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/session_page.dart';

// ============================================================
// PRE-SESSION SCREEN — Schermata prima dell'inizio della serata.
// Raccoglie due cose, da reinserire OGNI volta (non precompilate,
// perché chi è disponibile ad aiutarti cambia da una sera all'altra):
//
//   1. Contatto di emergenza (nome + telefono) → salvato nel Provider,
//      usato dal pulsante CALL FOR HELP nel layout rosso di SessionScreen.
//   2. Quanto hai mangiato → passato a SessionScreen come LivelloCibo,
//      attiva il coefficiente di attenuazione del BAC.
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
  void dispose() {
    // Libera i controller quando la schermata viene chiusa
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
    // Numero salvato in formato internazionale (+39): serve perché SMS e
    // WhatsApp riconoscano il contatto.
    final telefono = '+39$localPhone';
    if (_livelloCibo == null) {
      _showSnackBar('Tell us how much you have eaten');
      return;
    }

    // Salva il contatto di emergenza nel Provider / SharedPreferences
    final user = Provider.of<UserProvider>(context, listen: false);
    await user.saveEmergencyContact(nome: nome, telefono: telefono);

    if (!mounted) return;

    // Avvia la sessione passando il livello cibo scelto.
    // pushReplacement: la PreSessionScreen viene tolta dallo stack, così
    // "END THE NIGHT" (un solo pop) riporta direttamente alla Home.
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
        backgroundColor: const Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- Sezione contatto di emergenza ---
            const Text(
              'Emergency contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Who should we message if things go wrong tonight?',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),

            _field(nomeController, 'Contact name', 'e.g. Marco'),
            const SizedBox(height: 12),
            _field(telefonoController, 'Phone number', 'e.g. 3331234567',
                phone: true),

            const SizedBox(height: 28),

            // --- Sezione cibo ---
            const Text(
              'Have you eaten?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // Chip per scegliere il livello di cibo
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

  // Helper per i TextField, stesso stile delle altre schermate.
  // Per il telefono accetta solo cifre e il simbolo '+'.
  Widget _field(TextEditingController controller, String label, String hint,
      {bool phone = false}) {
    return TextField(
      controller: controller,
      keyboardType: phone ? TextInputType.phone : TextInputType.text,
      inputFormatters: phone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ]
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        labelText: label,
        hintText: hint,
        // Prefisso fisso +39 per il telefono: l'utente digita solo la parte
        // locale, così il numero salvato è sempre internazionale.
        prefixText: phone ? '+39 ' : null,
      ),
    );
  }
}
