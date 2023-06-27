import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        const Text("Vérifiez votre email"),
        TextButton(onPressed: ()async{
          final user = FirebaseAuth.instance.currentUser;
          await user?.sendEmailVerification();
        },
          child: const Text("Envoyer l'email de vérification"),
        )
      ],
    );
  }
}