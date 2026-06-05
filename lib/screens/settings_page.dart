import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  
  // Controller per tutti i campi modificabili
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cognomeController = TextEditingController();
  final TextEditingController nomeUtenteController = TextEditingController();
  final TextEditingController etaController = TextEditingController();
  final TextEditingController sessoController = TextEditingController();
  final TextEditingController altezzaController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carica i dati non appena la pagina viene aperta
  }

  // Metodo per caricare i dati salvati in SharedPreferences
  Future<void> _loadUserData() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      // Recupera i dati (se non esistono, lascia il campo vuoto)
      nomeController.text = sharedPreferences.getString('nome') ?? '';
      cognomeController.text = sharedPreferences.getString('cognome') ?? '';
      nomeUtenteController.text = sharedPreferences.getString('username') ?? '';
      etaController.text = sharedPreferences.getString('eta') ?? '';
      sessoController.text = sharedPreferences.getString('sesso') ?? '';
      altezzaController.text = sharedPreferences.getString('altezza') ?? '';
      pesoController.text = sharedPreferences.getString('peso') ?? '';
      emailController.text = sharedPreferences.getString('email') ?? '';
      _isLoading = false;
    });
  }

  // Metodo per salvare i dati modificati
  Future<void> _saveUserData() async {
    // Validazione campi vuoti (stessa logica della registrazione)
    if (nomeController.text.isEmpty ||
        cognomeController.text.isEmpty ||
        nomeUtenteController.text.isEmpty ||
        etaController.text.isEmpty ||
        sessoController.text.isEmpty ||
        altezzaController.text.isEmpty ||
        pesoController.text.isEmpty ||
        emailController.text.isEmpty) {
      _showSnackBar('Tutti i campi devono essere compilati');
      return;
    }

    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('nome', nomeController.text);
    await sharedPreferences.setString('cognome', cognomeController.text);
    await sharedPreferences.setString('username', nomeUtenteController.text);
    await sharedPreferences.setString('eta', etaController.text);
    await sharedPreferences.setString('sesso', sessoController.text);
    await sharedPreferences.setString('altezza', altezzaController.text);
    await sharedPreferences.setString('peso', pesoController.text);
    await sharedPreferences.setString('email', emailController.text);

    _showSnackBar('Modifiche salvate con successo!');
  }

  void _showSnackBar(String messaggio) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(messaggio)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text("Impostazioni Profilo"),
        backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    _buildTextField(nomeController, 'Nome', 'Modifica il tuo nome'),
                    _buildTextField(cognomeController, 'Cognome', 'Modifica il tuo cognome'),
                    _buildTextField(nomeUtenteController, 'Nome utente', 'Modifica il tuo nome utente'),
                    _buildTextField(etaController, 'Età', 'Modifica la tua età', isNumber: true),
                    _buildTextField(sessoController, 'Sesso', 'M/F'),
                    _buildTextField(altezzaController, 'Altezza (cm)', 'Modifica la tua altezza', isNumber: true),
                    _buildTextField(pesoController, 'Peso (kg)', 'Modifica il tuo peso', isNumber: true),
                    _buildTextField(emailController, 'Email', 'Modifica la tua email'),
                    
                    const SizedBox(height: 25),
                    
                    // Pulsante Salva Modifiche
                    Container(
                      height: 50,
                      width: 250,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 196, 0),
                          side: const BorderSide(color: Colors.white, width: 1), // Un tocco di stacco grafico
                        ),
                        onPressed: _saveUserData,
                        child: const Text(
                          'Salva Modifiche',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget per evitare di ripetere 8 volte lo stesso identico blocco di Padding/TextField
  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            labelText: label,
            hintText: hint),
      ),
    );
  }
}
