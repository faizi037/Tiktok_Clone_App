import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tiktok_app/authentication/home_screen.dart';
import 'package:tiktok_app/authentication/login_screen.dart';


class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If user is logged in, go to HomeScreen
        else if (snapshot.hasData) {
          return const HomeScreen();
        }
        // If not logged in, go to LoginScreen
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
