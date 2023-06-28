import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';
import 'dart:developer' as devtools show log;
import '../firebase_options.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'),),
      body: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder:(context,snapshot){
            switch (snapshot.connectionState){
              case ConnectionState.done:
                return Column(
                  children: [
                    TextField(
                      controller: _email,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          hintText: 'Entrez votre email'
                      ),
                    ),
                    TextField(
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      controller: _password,
                      decoration: const InputDecoration(
                          hintText: 'Entrez votre mot de passe'
                      ),
                    ),
                    TextButton(onPressed: () async{
                      final email = _email.text;
                      final password = _password.text;
                      try{
                        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                        );
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            notesRoute,
                                (route) => false,);
                      } on FirebaseAuthException catch(e){
                        if(e.code == "user-not-found"){
                          await showErrorDialog(
                            context,
                            "User not found",
                          );
                        }else if (e.code == "wrong-password"){
                          await showErrorDialog(
                            context,
                            "Wrong Credentials",
                          );
                        }else{
                          await showErrorDialog(
                              context,
                              "Error: ${e.code}",
                          );
                        }
                      }
                      catch(e){
                        await showErrorDialog(
                          context,
                          e.toString(),
                        );
                      }
                    },child: const Text('Login'),),
                    TextButton(onPressed: (){
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          registerRoute,
                              (route) => false);
                    },
                        child: const Text("Not registered yet? Register here!")),
                  ],
                );
              default:
                return const CircularProgressIndicator();
            }
          }
      ),
    );
  }
}

