import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String gerarConversationId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();

    return '${ids[0]}_${ids[1]}';
  }

  Future<void> enviarMensagem({
    required String conversationId,
    required String senderId,
    required String texto,
  }) async {
    final mensagem = texto.trim();

    if (mensagem.isEmpty) return;

    final conversaRef =
        _firestore.collection('conversations').doc(conversationId);

    final conversa = await conversaRef.get();

    if (!conversa.exists) {
      throw Exception('Conversa não encontrada.');
    }

    await conversaRef.collection('messages').add({
      'senderId': senderId,
      'text': mensagem,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await conversaRef.update({
      'lastMessage': mensagem,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> criarConversa({
    required String uid1,
    required String uid2,
  }) async {
    final conversationId = gerarConversationId(uid1, uid2);

    final conversaRef =
        _firestore.collection('conversations').doc(conversationId);

    final conversa = await conversaRef.get();

    if (!conversa.exists) {
      await conversaRef.set({
        'participants': [uid1, uid2],
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirMensagens(
    String conversationId,
  ) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirConversas(
    String uid,
  ) {
    return _firestore
        .collection('conversations')
        .where(
          'participants',
          arrayContains: uid,
        )
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}