import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'theme/app_theme.dart';
// import 'screens/onboarding_screen.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBSIta_QfgbUsrE1EfLv_Bz1PZWI6C-ecY",
      authDomain: "abolha-9ab85.firebaseapp.com",
      projectId: "abolha-9ab85",
      storageBucket: "abolha-9ab85.firebasestorage.app",
      messagingSenderId: "1050639872165",
      appId: "1:1050639872165:web:66a43fd30b7e6dab1c1d4c",
    ),
  );
  } else {
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