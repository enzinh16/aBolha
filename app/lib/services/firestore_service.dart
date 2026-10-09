import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> criarUsuario({
    required String uid,
    required String nome,
    required String email,
    required String telefone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}