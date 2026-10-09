import 'package:cloud_firestore/cloud_firestore.dart';

class BubbleService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bubbles =>
      _firestore.collection('bubbles');

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirBolhas() {
    return _bubbles
        .orderBy('criadaEm', descending: true)
        .snapshots();
  }

  Future<String> criarBolha({
    required String nome,
    required String descricao,
    required String criadorId,
    required String criadorNome,
    required String fotoUrl,
  }) async {
    final referencia = _bubbles.doc();

    await referencia.set({
      'nome': nome,
      'descricao': descricao,
      'fotoUrl': fotoUrl,
      'criadorId': criadorId,
      'criadorNome': criadorNome,
      'criadaEm': FieldValue.serverTimestamp(),
    });

    await referencia
        .collection('members')
        .doc(criadorId)
        .set({
      'uid': criadorId,
      'entrouEm': FieldValue.serverTimestamp(),
    });

    return referencia.id;
  }

  Future<void> entrarNaBolha({
    required String bubbleId,
    required String uid,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .set({
      'uid': uid,
      'entrouEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sairDaBolha({
    required String bubbleId,
    required String uid,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .delete();
  }

  Future<bool> usuarioParticipa({
    required String bubbleId,
    required String uid,
  }) async {
    final documento = await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .get();

    return documento.exists;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ouvirMembro({
    required String bubbleId,
    required String uid,
  }) {
    return _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      ouvirMembros(String bubbleId) {
    return _bubbles
        .doc(bubbleId)
        .collection('members')
        .snapshots();
  }
}