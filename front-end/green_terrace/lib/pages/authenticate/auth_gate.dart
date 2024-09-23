import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:green_terrace/pages/home/firstpage.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ...
         if (!snapshot.hasData) {
      // ignore: prefer_const_constructors
      return SignInScreen();
    }

    // Render your application if authenticated
    return FirstPage();
      },
    );
  }
}