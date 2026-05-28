import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/user_provider.dart';
import 'package:buzzed_buddy/screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  TextEditingController nomeController = TextEditingController();
  TextEditingController cognomeController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController etaController = TextEditingController();
  TextEditingController sessoController = TextEditingController();
  TextEditingController altezzaController = TextEditingController();
  TextEditingController pesoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool termsAccepted = false;

  void _mostraCondizioni(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Condizioni di servizio'),
          content: SingleChildScrollView(
            child: Text(
              'Leggendo e accettando queste condizioni, accetti di:\n\n'
              '1. Fornire informazioni personali accurate\n'
              '2. Utilizzare l\'app senza sostituire il giudizio medico\n'
              '3. Non condividere i tuoi dati con terzi\n'
              '4. Proteggere la tua password\n'
              '5. Accettare la privacy policy\n\n'
              'Per maggiori dettagli, contattaci alla email buzzedbuddy@gmail.com.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Rifiuto'),
            ),
            TextButton(
              onPressed: () {
                setState(() => termsAccepted = true);
                Navigator.pop(context);
              },
              child: Text('Accetto'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("REGISTRAZIONE"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              _campo(nomeController, 'Nome', 'Inserisci il tuo nome'),
              _campo(cognomeController, 'Cognome', 'Inserisci il tuo cognome'),
              _campo(usernameController, 'Nome utente', 'Scegli un nome utente'),
              _campo(etaController, 'Età', 'Inserisci la tua età', numbersOnly: true),
              _campo(sessoController, 'Sesso', 'M/F'),
              _campo(altezzaController, 'Altezza (cm)', 'Inserisci la tua altezza', numbersOnly: true),
              _campo(pesoController, 'Peso (kg)', 'Inserisci il tuo peso', numbersOnly: true),
              _campo(emailController, 'Email', 'Inserisci la tua email'),
              _campo(passwordController, 'Password', 'Inserisci la password', obscure: true),
              _campo(confirmPasswordController, 'Conferma Password', 'Conferma la password', obscure: true),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _mostraCondizioni(context),
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
                        onTap: () => _mostraCondizioni(context),
                        child: Text(
                          'Accetto le condizioni di servizio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.yellow,
                  minimumSize: Size(250, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (nomeController.text.isEmpty ||
                      cognomeController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      etaController.text.isEmpty ||
                      sessoController.text.isEmpty ||
                      altezzaController.text.isEmpty ||
                      pesoController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      passwordController.text.isEmpty ||
                      confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Compila tutti i campi')));
                    return;
                  }

                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Le password non corrispondono')));
                    return;
                  }

                  if (!termsAccepted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Devi accettare le condizioni per registrarti')));
                    return;
                  }

                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  await userProvider.salvaUtente(
                    username: usernameController.text,
                    password: passwordController.text,
                    sesso: sessoController.text,
                    peso: double.parse(pesoController.text),
                    altezza: double.parse(altezzaController.text),
                    eta: int.parse(etaController.text),
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Registrazione completata! Accedi ora.')));

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text(
                  'REGISTRATI',
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

  Widget _campo(TextEditingController controller, String label, String hint,
      {bool obscure = false, bool numbersOnly = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: obscure
        ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
        : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}