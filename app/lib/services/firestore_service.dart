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

  /// Usado no login social (Google/Discord): cria o documento do usuário só
  /// na primeira vez. Se ele já existe (já tinha conta), não mexe em nada.
  /// Devolve true quando criou um perfil novo.
  Future<bool> garantirUsuario({
    required String uid,
    required String nome,
    required String email,
    String telefone = '',
    String fotoPerfil = '',
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();

    if (doc.exists) return false;

    await ref.set({
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoPerfil': fotoPerfil,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return true;
  }
}
