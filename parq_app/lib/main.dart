import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;

  InputDecoration buildInputDecoration(String hintText, String labelText) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      filled: true,
      fillColor: Color.fromARGB(100, 240, 246, 246),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create your account")),
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Center(
                child: SizedBox(
                  height: 500,
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextField(
                        controller: _username,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: buildInputDecoration(
                            'Enter your username here', 'Username'),
                      ),
                      TextField(
                        controller: _email,
                        enableSuggestions: false,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: buildInputDecoration(
                            'Enter your email here', 'Email'),
                      ),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: buildInputDecoration(
                            'Enter your password here', 'Password'),
                      ),
                      TextField(
                        controller: _confirmPassword,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: buildInputDecoration(
                            'Enter your confirm password here',
                            'Confirm Password'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final username = _username.text;
                          final email = _email.text;
                          final password = _password.text;
                          final confirmPassword = _confirmPassword.text;

                          if (password != confirmPassword) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Error'),
                                  content: const Text(
                                    'Passwords do not match',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          final userCredential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          await userCredential.user
                              ?.updateDisplayName(username);

                          print(userCredential);
                        },
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blue),
                        ),
                        child: Text(
                          'Create your account',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            default:
              return const Text('Loading...');
          }
        },
      ),
    );
  }
}
