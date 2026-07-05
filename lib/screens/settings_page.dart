import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Libera i controller quando la schermata viene distrutta, per non lasciarli
  // appesi in memoria.
  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    genderController.dispose();
    weightController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      nameController.text = user.name ?? '';
      usernameController.text = user.username ?? '';
      genderController.text = user.gender ?? '';
      weightController.text = user.weight?.toString() ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        weightController.text.isEmpty ||
        genderController.text.isEmpty) {
      _showSnackBar('Name, username, weight and sex are required!');
      return;
    }

    if (passwordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    // Peso: conversione sicura (accetta la virgola) e controllo di plausibilita'.
    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 400) {
      _showSnackBar('Enter a valid weight in kg');
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false);

    // Se stai cambiando la password, quella nuova deve essere diversa da quella
    // attuale: altrimenti non e' un cambio, e dire "salvato" sarebbe fuorviante.
    if (passwordController.text.isNotEmpty &&
        user.matchesCurrentPassword(passwordController.text)) {
      _showSnackBar('The new password must be different from the current one');
      return;
    }

    await user.saveUser(
      // Username e sesso non sono modificabili qui: passiamo i valori correnti.
      // Lo username e' la chiave dell'account, il sesso e' un parametro
      // fisiologico fisso del modello del tasso alcolemico.
      username: usernameController.text,
      // Se il campo e' vuoto non tocchiamo la password (saveUser mantiene
      // l'hash esistente); se compilato, verra' ri-hashata con un nuovo sale.
      password: passwordController.text.isNotEmpty
          ? passwordController.text
          : null,
      name: nameController.text,
      gender: genderController.text,
      weight: weight,
      setAsCurrentUser: true,
    );

    _showSnackBar('Saved successfully!');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    _buildTextField(nameController, 'Full name', 'Modify your name'),
                    // Username in sola lettura: e' la chiave dell'account.
                    _buildTextField(usernameController, 'Username', 'Cannot be changed', readOnly: true),
                    // Sesso in sola lettura: parametro fisiologico fisso, non una preferenza.
                    _buildTextField(genderController, 'Sex', 'Set at sign up', readOnly: true),
                    _buildTextField(weightController, 'Weight (kg)', 'Modify your weight', isNumber: true),
                    _buildTextField(passwordController, 'New password', 'Leave blank to keep current', obscure: true),
                    _buildTextField(confirmPasswordController, 'Confirm new password', 'Repeat new password', obscure: true),
                    const SizedBox(height: 25),
                    Container(
                      height: 50,
                      width: 250,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                        ),
                        onPressed: _saveUserData,
                        child: const Text(
                          'Save Changes',
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

  Widget _buildTextField(TextEditingController controller, String label, String hint,
      {bool isNumber = false, bool obscure = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          filled: true,
          // Il campo di sola lettura ha un fondo grigio per segnalare che non si tocca.
          fillColor: readOnly ? Colors.grey.shade300 : Colors.white,
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
        ),
      ),
    );
  }
}
