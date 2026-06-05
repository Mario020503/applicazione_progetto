import 'package:flutter/material.dart';
import 'package:applicazione_progetto/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nomeController = TextEditingController();
  TextEditingController cognomeController = TextEditingController();
  TextEditingController nomeUtenteController = TextEditingController();
  TextEditingController etaController = TextEditingController();
  TextEditingController sessoController = TextEditingController();
  TextEditingController altezzaController = TextEditingController();
  TextEditingController pesoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 196, 0),
      appBar: AppBar(
        title: Text("Registrazione"),
        backgroundColor: Color.fromARGB(255, 255, 196, 0),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: nomeController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Nome',
                    hintText: 'Inserisci il tuo nome'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: cognomeController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Cognome',
                    hintText: 'Inserisci il tuo cognome'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: nomeUtenteController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Nome utente',
                    hintText: 'Inserisci il tuo nome utente'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: etaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Età',
                    hintText: 'Inserisci la tua età'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: sessoController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Sesso',
                    hintText: 'M/F'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: altezzaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Altezza (cm)',
                    hintText: 'Inserisci la tua altezza'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: pesoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Peso (kg)',
                    hintText: 'Inserisci il tuo peso'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Inserisci la tua email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Inserisci la password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 15),
              child: TextField(
                obscureText: true,
                controller: confirmPasswordController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Conferma Password',
                    hintText: 'Conferma la password'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 20, bottom: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
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
                                onPressed: () {
                                  // Rifiuta le condizioni
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context, MaterialPageRoute(builder: (_) => LoginPage()));
                                },
                                child: Text('Rifiuto'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Accetta le condizioni
                                  setState(() {
                                    termsAccepted = true;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('Accetto'),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                      onTap: () {
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
                                  onPressed: () {
                                    // Rifiuta le condizioni
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                        context, MaterialPageRoute(builder: (_) => LoginPage()));
                                  },
                                  child: Text('Rifiuto'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Accetta le condizioni
                                    setState(() {
                                      termsAccepted = true;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Accetto'),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 196, 0),
                ),
                onPressed: () async {
                  // Validazione campi vuoti
                  if (nomeController.text.isEmpty ||
                      cognomeController.text.isEmpty ||
                      nomeUtenteController.text.isEmpty ||
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

                  // Validazione password uguali
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Le password non corrispondono')));
                    return;
                  }

                  // Validazione condizioni
                  if (!termsAccepted) {
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('Devi accettare le condizioni per registrarti')));
                    return;
                  }

                  // Validazione età
                  showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Condizioni di servizio'),
                              content: SingleChildScrollView(
                                child: Text(
                                  'Anche se sei minorenne puoi lo stesso utilizzare l\'app! \n ma ricorda che è importante bere responsabilmente e seguire sempre le linee guida per un consumo sicuro.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Accetta le condizioni
                                    setState(() {
                                      termsAccepted = true;
                                    }
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Text('Ne sono consapevole '),
                                ),
                              ]);
                          },
                  );
                                           

                  final currentContext = context;
                  // Registrazione avvenuta con successo - Salva credenziali
                  final sharedPreferences = await SharedPreferences.getInstance();
                  await sharedPreferences.setString('username', nomeUtenteController.text);
                  await sharedPreferences.setString('password', passwordController.text);
                  
                  if (!currentContext.mounted) return;

                  // Torna alla login
                  Navigator.pushReplacement(
                      currentContext, MaterialPageRoute(builder: (_) => LoginPage()));
                },
                child: Text('Registrati'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}