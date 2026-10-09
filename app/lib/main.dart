import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'theme/app_theme.dart';
// import 'screens/onboarding_screen.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // As chaves ficam em firebase_options.dart (fora do Git).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
  } else {
    // Android/iOS leem a configuração do google-services.json (fora do Git).
    await Firebase.initializeApp();
  }

  runApp(const BolhaApp());
}

class BolhaApp extends StatelessWidget {
  const BolhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}