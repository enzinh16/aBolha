import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wordmark "aBolha" desenhado à mão (letras grossas + contorno de adesivo)
              Image.asset(
                'assets/images/wordmark_abolha.png',
                width: 320,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              Text(
                'Crie e viva sua bolha',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 22,
                      color: BolhaColors.softPink,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(
                'Comunidades de nicho para quem quer conversar '
                'sobre o que realmente gosta.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      color: BolhaColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BolhaColors.secondary,
                    shape: SketchBorder(
                      borderRadius: BorderRadius.circular(34),
                      variant: 3,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Entrar na minha bolha',
                    style: TextStyle(
                      fontFamily: AppTheme.fontTitulo,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
