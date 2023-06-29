import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';
import '../firebase_options.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {

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
      appBar: AppBar(title: const Text('Register'),),
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
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email,
                            password: password
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        user?.sendEmailVerification();
                        Navigator.of(context).pushNamed(verifyEmailRoute);
                      } on FirebaseAuthException catch(e){
                        if(e.code == 'weak-password'){
                          await showErrorDialog(context, "Weak password");
                        }else if(e.code == 'email-already-in-use'){
                          await showErrorDialog(context, "Email already in use");
                        }else if(e.code == 'invalid-email'){
                          await showErrorDialog(context, "This is an invalid email");
                        }else{
                          await showErrorDialog(context, "Error: ${e.code}");
                        }
                      }catch(e){
                        await showErrorDialog(context, e.toString());
                      }
                    },child: const Text('Register'),),
                    TextButton(onPressed: (){
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          loginRoute,
                              (route) => false,);
                    }, child: const Text("Already registered? Login here !"))
                  ],
                );
              default:
                return const Text("Chargement...");
            }
          }
      ),
    );
  }
}