import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding_screen.dart';
import 'main_screen.dart';

/// Decide, toda vez que o app abre, se o usuário já está logado
/// (e manda direto pra MainScreen) ou não (e manda pro Onboarding).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto o Firebase ainda está checando a sessão salva
        // no dispositivo (acontece rapidinho, mas acontece).
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Tem usuário salvo no dispositivo -> pula onboarding/login
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Sem usuário -> fluxo normal de onboarding -> login/registro
        return const OnboardingScreen();
      },
    );
  }
}