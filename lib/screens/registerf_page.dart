import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/loginf_page.dart';
import 'package:buzzed_buddy/widgets/small_app_logo.dart';
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool termsAccepted = false;
  String? selectedGender;
  DateTime? _birthDate;
 
  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Terms & Conditions'),
          content: SingleChildScrollView(
            child: Text(
              'By accepting these terms, you agree to:\n\n'
              '1. Provide accurate personal information, including your age, weight, and profile details.\n'
              '2. Understand that Buzzed Buddy is for awareness and educational purposes only. It is not a medical device, not a certified breathalyzer, and the BAC estimate is approximate.\n'
              '3. Not rely on this app to decide whether it is safe to drive, operate machinery, or take any other risky action. The only safe level for driving is zero alcohol.\n'
              '4. Understand that the help feature does not replace emergency services. In a real emergency, call your local emergency number immediately.\n'
              '5. Take responsibility for your own alcohol consumption and comply with local laws, age restrictions, and safety guidance. The app does not encourage excessive drinking or underage drinking.\n'
              '6. Understand that your data is handled only for the purpose of providing the app experience, and it remains on the device unless otherwise stated.\n'
              '7. Understand that the app authors are not responsible for decisions made based on the app, and location access is only used to support emergency assistance if you enable it.\n\n'
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Decline'),
            ),
            TextButton(
              onPressed: () {
                setState(() => termsAccepted = true);
                Navigator.pop(context);
              },
              child: Text('Accept'),
            ),
          ],
        );
      },
    );
  }
 
  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Create your account"),
        backgroundColor: Colors.black,
        foregroundColor: Color.fromARGB(255, 255, 196, 0),
        elevation: 0,
        actions: const [SmallAppLogo()],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
 
              _field(nameController, 'Full name', 'Enter your real name'),
              _field(usernameController, 'Username', 'Choose a username'),
              _field(weightController, 'Weight (kg)', 'Enter your weight', numbersOnly: true),
              _genderSelector(),
              _birthDatePicker(),
              _field(passwordController, 'Password', 'Choose a password', obscure: true),
              _field(confirmPasswordController, 'Confirm password', 'Repeat your password', obscure: true),
 
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showTerms(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: termsAccepted ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: termsAccepted ? Colors.green : Colors.white,
                        ),
                        child: termsAccepted
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTerms(context),
                        child: Text(
                          'I accept the Terms & Conditions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
 
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Color.fromARGB(255, 255, 196, 0),
                  minimumSize: Size(250, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      weightController.text.isEmpty ||
                      passwordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Please fill in all fields')));
                    return;
                  }
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  final sesso = selectedGender;
                  if (sesso == null) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Please select M or F')));
                    return;
                  }
                  if (!termsAccepted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('You must accept the Terms & Conditions')));
                    return;
                  }
                  if (_birthDate == null) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Please select your birth date')));
                    return;
                  }

                  final username = usernameController.text.trim();
                  if (username.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Please enter a username')));
                    return;
                  }

                  final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
                  if (weight == null || weight < 20 || weight > 400) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Enter a valid weight in kg')));
                    return;
                  }

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final userProvider = Provider.of<UserProvider>(context, listen: false);

                  if (userProvider.usernameExists(username)) {
                    messenger
                      ..removeCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('This username is already taken')));
                    return;
                  }

                  await userProvider.saveUser(
                    username: username,
                    password: passwordController.text,
                    name: nameController.text,
                    gender: sesso,
                    weight: weight,
                    birthDate: _birthDate!.toIso8601String(),
                  );

                  await _requestLocationPermission();

                  if (context.mounted && _isUnder18(_birthDate!)) {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('A quick note'),
                        content: const Text(
                          'You are under 18. This app is here for awareness, not to '
                          'encourage drinking. Alcohol is not allowed at your age.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('I understand'),
                          ),
                        ],
                      ),
                    );
                  }

                  messenger
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Account created! Please log in.')));
 
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: Text(
                  'SIGN UP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
 
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _field(TextEditingController controller, String label, String hint,
      {bool obscure = false, bool numbersOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: obscure
            ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
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
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: DropdownButtonFormField<String>(
        initialValue: selectedGender,
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
          labelText: 'Sex',
          hintText: 'Choose M or F',
        ),
        items: const [
          DropdownMenuItem(value: 'M', child: Text('M')),
          DropdownMenuItem(value: 'F', child: Text('F')),
        ],
        onChanged: (value) => setState(() => selectedGender = value),
      ),
    );
  }

  bool _isUnder18(DateTime b) {
    final now = DateTime.now();
    int age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) age--;
    return age < 18;
  }

  Widget _birthDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year - 20),
            firstDate: DateTime(now.year - 100),
            lastDate: now,
          );
          if (picked != null) setState(() => _birthDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 3),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 3),
            ),
            labelText: 'Birth date',
          ),
          child: Text(
            _birthDate == null
                ? 'Select your birth date'
                : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
            style: TextStyle(
              color: _birthDate == null ? Colors.grey.shade600 : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
