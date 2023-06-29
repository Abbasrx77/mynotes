import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

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
          future: AuthService.firebase().initialize(),
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
                        await AuthService.firebase().logIn(email: email, password: password);
                        final user = AuthService.firebase().currentUser;
                        if (user?.isEmailVerified ?? false){
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            notesRoute,
                                (route) => false,);
                        }else{
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            verifyEmailRoute,
                                (route) => false,);
                        }

                      } on UserNotFoundAuthException{
                        await showErrorDialog(context, "User not found");

                      } on WrongPasswordAuthException{
                        await showErrorDialog(context, "Wrong credentials");

                      } on GenericAuthException{
                        await showErrorDialog(context, "Authentication error");

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

