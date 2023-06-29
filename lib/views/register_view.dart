import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

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

                        await AuthService.firebase().createUser(
                          email: email,
                          password: password,
                        );
                        final user = AuthService.firebase().currentUser;
                        await AuthService.firebase().sendEmailVerification();
                        Navigator.of(context).pushNamed(verifyEmailRoute);
                      } on WeakPasswordAuthException{
                        await showErrorDialog(context, "Weak password");
                      } on EmailAlreadyInUseAuthException{
                        await showErrorDialog(context, "Email already in use");
                      } on InvalidEmailAuthException{
                        await showErrorDialog(context, "This is an invalid email adress");
                      } on GenericAuthException{
                        await showErrorDialog(context, "Failed to register");
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
                return const CircularProgressIndicator();
            }
          }
      ),
    );
  }
}