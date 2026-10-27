import 'package:cloud_firestore/cloud_firestore.dart';

/// Papéis possíveis de um membro dentro de uma Bolha.
///
/// Hierarquia: criador > líder > moderador > membro.
/// O criador não tem papel próprio: ele é identificado pelo campo
/// `criadorId` da Bolha. Membros antigos, sem o campo `papel`, contam como
/// [papelMembro].
const String papelMembro = 'membro';
const String papelModerador = 'moderador';
const String papelLider = 'lider';

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
      'papel': papelMembro,
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
      'papel': papelMembro,
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

  /// Remove outro membro da Bolha. O criador remove qualquer pessoa (menos
  /// ele mesmo); líderes removem moderadores e membros; moderadores removem
  /// apenas membros comuns (as Security Rules conferem isso no servidor).
  Future<void> removerMembro({
    required String bubbleId,
    required String uid,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .delete();
  }

  /// Edita nome, descrição e foto da Bolha. Pode ser chamado pelo criador ou
  /// por moderadores (as Security Rules conferem isso no servidor).
  Future<void> atualizarBolha({
    required String bubbleId,
    required String nome,
    required String descricao,
    required String fotoUrl,
  }) async {
    await _bubbles.doc(bubbleId).update({
      'nome': nome,
      'descricao': descricao,
      'fotoUrl': fotoUrl,
    });
  }

  /// Torna alguém líder. Só o criador pode (as Security Rules conferem isso
  /// no servidor). Pode haver mais de um líder.
  Future<void> promoverLider({
    required String bubbleId,
    required String uid,
    required String promotorId,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .update({
      'papel': papelLider,
      'promovidoPor': promotorId,
      'promovidoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Tira a liderança: o líder volta a ser moderador. Só o criador pode.
  Future<void> rebaixarLider({
    required String bubbleId,
    required String uid,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .update({
      'papel': papelModerador,
    });
  }

  /// O criador só pode sair se existir pelo menos um líder na Bolha (ou se
  /// ele for o único membro, já que não haveria quem escolher).
  Future<bool> criadorPodeSair({
    required String bubbleId,
    required String criadorId,
  }) async {
    final membros = await _bubbles
        .doc(bubbleId)
        .collection('members')
        .get();

    var outrosMembros = 0;

    for (final doc in membros.docs) {
      if (doc.id == criadorId) continue;

      outrosMembros++;

      final papel = (doc.data()['papel'] ?? papelMembro).toString();

      if (papel == papelLider) return true;
    }

    return outrosMembros == 0;
  }

  /// Torna um membro comum moderador. Pode ser chamado pelo criador, por
  /// líderes ou por moderadores (as Security Rules conferem isso no servidor).
  Future<void> promoverModerador({
    required String bubbleId,
    required String uid,
    required String promotorId,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .update({
      'papel': papelModerador,
      'promovidoPor': promotorId,
      'promovidoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Volta um moderador a membro comum. Só o criador e os líderes podem
  /// (as Security Rules conferem isso no servidor).
  Future<void> rebaixarModerador({
    required String bubbleId,
    required String uid,
  }) async {
    await _bubbles
        .doc(bubbleId)
        .collection('members')
        .doc(uid)
        .update({
      'papel': papelMembro,
      'promovidoPor': FieldValue.delete(),
      'promovidoEm': FieldValue.delete(),
    });
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
