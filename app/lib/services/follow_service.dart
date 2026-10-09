import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _followers(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followers');
  }

  CollectionReference<Map<String, dynamic>> _following(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following');
  }

  Stream<bool> ouvirSeSegue({
    required String meuUid,
    required String usuarioUid,
  }) {
    return _following(meuUid)
        .doc(usuarioUid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> ouvirQuantidadeSeguidores(
    String uid,
  ) {
    return _followers(uid)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> ouvirQuantidadeSeguindo(
    String uid,
  ) {
    return _following(uid)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> seguir({
    required String meuUid,
    required String usuarioUid,
  }) async {
    if (meuUid == usuarioUid) {
      return;
    }

    final batch = _firestore.batch();

    final seguindoRef =
        _following(meuUid).doc(usuarioUid);

    final seguidoresRef =
        _followers(usuarioUid).doc(meuUid);

    batch.set(seguindoRef, {
      'criadoEm': FieldValue.serverTimestamp(),
    });

    batch.set(seguidoresRef, {
      'criadoEm': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deixarDeSeguir({
    required String meuUid,
    required String usuarioUid,
  }) async {
    if (meuUid == usuarioUid) {
      return;
    }

    final batch = _firestore.batch();

    final seguindoRef =
        _following(meuUid).doc(usuarioUid);

    final seguidoresRef =
        _followers(usuarioUid).doc(meuUid);

    batch.delete(seguindoRef);
    batch.delete(seguidoresRef);

    await batch.commit();
  }
}