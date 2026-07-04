import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';
 
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
 
    final gender = genderController.text.toUpperCase();
    if (gender != 'M' && gender != 'F') {
      _showSnackBar('Sex must be M or F');
      return;
    }
 
    if (passwordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }
 
    final user = Provider.of<UserProvider>(context, listen: false);
    await user.saveUser(
      username: usernameController.text,
      // Se il campo è vuoto non tocchiamo la password (saveUser mantiene l'hash
      // esistente); se compilato, verrà ri-hashata con un nuovo sale.
      password: passwordController.text.isNotEmpty
          ? passwordController.text
          : null,
      name: nameController.text,
      gender: gender,
      weight: double.parse(weightController.text),
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
                    _buildTextField(usernameController, 'Username', 'Modify your username'),
                    _buildTextField(genderController, 'Sex (M/F)', 'M or F'),
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
      {bool isNumber = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
        ),
      ),
    );
  }
}