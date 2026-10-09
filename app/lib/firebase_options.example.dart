// MODELO do firebase_options.dart
//
// Para rodar o projeto em outra máquina:
//   1. Copie este arquivo para lib/firebase_options.dart
//   2. Troque os valores SEU_... pelos do seu projeto no Console do Firebase
//      (ou rode `flutterfire configure`, que gera o arquivo real).
//
// O lib/firebase_options.dart real está no .gitignore e não deve ser enviado.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SEU_API_KEY',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.firebasestorage.app',
    messagingSenderId: 'SEU_SENDER_ID',
    appId: 'SEU_APP_ID_WEB',
  );
}
