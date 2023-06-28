import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/views/email_verify_view.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'firebase_options.dart';
import 'dart:developer' as devtools show log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    routes: {
      '/login/': (context){
        return const LoginView();
      },
      '/register/': (context){
        return const RegisterView();
      }
    },
    home: const HomePage(),
  ));
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder:(context,snapshot){
          switch (snapshot.connectionState){
            case ConnectionState.done:
              final user = FirebaseAuth.instance.currentUser;
              if (user != null){
                if (user.emailVerified){
                  print("Email Verified");
                }else{
                  return const VerifyEmailView();
                }
              }else{
                return const LoginView();
              }
             return const NotesView();
            default:
              return const CircularProgressIndicator();
          }
        }
    );
  }
}

enum MenuAction {logout}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main UI'),
        actions: [
          PopupMenuButton<MenuAction>( onSelected: (value)async{
            switch (value){
              case MenuAction.logout:
                final shouldLogout = await showLogoutDialog(context);
                if (shouldLogout){
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login/',
                       (_) => false);
                }
                devtools.log(shouldLogout.toString());
                break;
            }
          },
            itemBuilder: (context){
            return const[
               PopupMenuItem<MenuAction>(
              value: MenuAction.logout,
              child: Text("Log out"),)
            ];
            },
          )
        ],
      ),
      body: const Center(
          child: Text("Hello World!")),
    );
  }
}

Future<bool>showLogoutDialog(BuildContext context){
  return showDialog<bool>(context: context, builder: (context){
    return AlertDialog(
      title: const Text("Sign out"),
      content: const Text("Are you sure you want to sign out?"),
      actions: [
        TextButton(onPressed: (){
          Navigator.of(context).pop(false);
        },
            child: const Text("Cancel"),),
        TextButton(onPressed: (){
          Navigator.of(context).pop(true);
        },
            child: const Text("Log out"),)
      ],
    );
  }).then((value) => value ?? false);
}
