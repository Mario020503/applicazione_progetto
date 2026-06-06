import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  
  // Controller per tutti i campi modificabili
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
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
      // Recupera i dati
      nameController.text = sharedPreferences.getString('name') ?? '';
      surnameController.text = sharedPreferences.getString('surname') ?? '';
      usernameController.text = sharedPreferences.getString('username') ?? '';
      ageController.text = sharedPreferences.getString('age') ?? '';
      genderController.text = sharedPreferences.getString('gender') ?? '';
      heightController.text = sharedPreferences.getString('height') ?? '';
      weightController.text = sharedPreferences.getString('weight') ?? '';
      emailController.text = sharedPreferences.getString('email') ?? '';
      _isLoading = false;
    });
  }

  // Metodo per salvare i dati modificati
  Future<void> _saveUserData() async {
    // Validazione campi vuoti (stessa logica della registrazione)
    if (nameController.text.isEmpty ||
        surnameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        ageController.text.isEmpty ||
        genderController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        emailController.text.isEmpty) {
      _showSnackBar('Every field must be filled!');
      return;
    }

    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('name', nameController.text);
    await sharedPreferences.setString('surname', surnameController.text);
    await sharedPreferences.setString('username', usernameController.text);
    await sharedPreferences.setString('age', ageController.text);
    await sharedPreferences.setString('gender', genderController.text);
    await sharedPreferences.setString('height', heightController.text);
    await sharedPreferences.setString('weight', weightController.text);
    await sharedPreferences.setString('email', emailController.text);

    _showSnackBar('Saved successfully!');
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
        title: const Text("Profile Settings"),
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
                    _buildTextField(nameController, 'Name', 'Modify your name'),
                    _buildTextField(surnameController, 'Surname', 'Modify your surname'),
                    _buildTextField(usernameController, 'Username', 'Modify your username'),
                    _buildTextField(ageController, 'Age', 'Modify your age', isNumber: true),
                    _buildTextField(genderController, 'Gender', 'M/F'),
                    _buildTextField(heightController, 'Height (cm)', 'Modify your height', isNumber: true),
                    _buildTextField(weightController, 'Weight (kg)', 'Modify your weight', isNumber: true),
                    _buildTextField(emailController, 'Email', 'Modify your email'),
                    
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
                          side: const BorderSide(color: Colors.white, width: 1), 
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
