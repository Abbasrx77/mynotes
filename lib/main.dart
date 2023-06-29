import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/views/email_verify_view.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/notes_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'dart:developer' as devtools show log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    routes: {
      loginRoute: (context) {
        return const LoginView();
      },
      registerRoute: (context) {
        return const RegisterView();
      },
      notesRoute: (context){
        return const NotesView();
      },
      verifyEmailRoute: (context){
        return const VerifyEmailView();
      }
    },
    home: const HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: AuthService.firebase().initialize(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final user = AuthService.firebase().currentUser;
              if (user != null) {
                if (user.isEmailVerified) {
                  devtools.log("Email Verified");
                } else {
                  return const VerifyEmailView();
                }
              } else {
                return const LoginView();
              }
              return const NotesView();
            default:
              return const CircularProgressIndicator();
          }
        });
  }
}
