import 'package:cloud_firestore/cloud_firestore.dart';

class PostPage {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  PostPage({
    required this.docs,
    required this.lastDocument,
    required this.hasMore,
  });
}

class PostService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _posts(
    String bubbleId,
  ) {
    return _firestore
        .collection('bubbles')
        .doc(bubbleId)
        .collection('posts');
  }

  CollectionReference<Map<String, dynamic>> _comments(
    String bubbleId,
    String postId,
  ) {
    return _posts(bubbleId)
        .doc(postId)
        .collection('comments');
  }

  Future<String> criarPost({
    required String bubbleId,
    required String autorId,
    required String autorNome,
    required String texto,
    String imagemUrl = '',
  }) async {
    final bubbleDoc = await _firestore
        .collection('bubbles')
        .doc(bubbleId)
        .get();

    final bubbleNome =
        bubbleDoc.data()?['nome'] ?? 'Bolha';

    final referencia = _posts(bubbleId).doc();

    await referencia.set({
      'bubbleId': bubbleId,
      'bubbleNome': bubbleNome,
      'autorId': autorId,
      'autorNome': autorNome,
      'texto': texto,
      'imagemUrl': imagemUrl,
      'criadaEm': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
    });

    return referencia.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirPosts(
    String bubbleId,
  ) {
    return _posts(bubbleId)
        .orderBy('criadaEm', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ouvirMeusPosts(
    String uid,
  ) {
    return _firestore
        .collectionGroup('posts')
        .where('autorId', isEqualTo: uid)
        .snapshots();
  }

  Future<PostPage> buscarPostsPagina({
    DocumentSnapshot<Map<String, dynamic>>? ultimoDocumento,
    int limite = 5,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('posts')
        .orderBy('criadaEm', descending: true)
        .limit(limite);

    if (ultimoDocumento != null) {
      query = query.startAfterDocument(
        ultimoDocumento,
      );
    }

    final snapshot = await query.get();

    return PostPage(
      docs: snapshot.docs,
      lastDocument:
          snapshot.docs.isNotEmpty
              ? snapshot.docs.last
              : ultimoDocumento,
      hasMore: snapshot.docs.length == limite,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> ouvirPost({
    required String bubbleId,
    required String postId,
  }) {
    return _posts(bubbleId)
        .doc(postId)
        .snapshots();
  }

  Future<void> curtirPost({
    required String bubbleId,
    required String postId,
    required String uid,
  }) async {
    final postRef = _posts(bubbleId).doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(uid);

    final like = await likeRef.get();

    if (like.exists) {
      return;
    }

    await likeRef.set({
      'criadaEm': FieldValue.serverTimestamp(),
    });

    await postRef.update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> removerCurtida({
    required String bubbleId,
    required String postId,
    required String uid,
  }) async {
    final postRef = _posts(bubbleId).doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(uid);

    final like = await likeRef.get();

    if (!like.exists) {
      return;
    }

    await likeRef.delete();

    await postRef.update({
      'likesCount': FieldValue.increment(-1),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> ouvirCurtida({
    required String bubbleId,
    required String postId,
    required String uid,
  }) {
    return _posts(bubbleId)
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots();
  }

  Future<String> criarComentario({
    required String bubbleId,
    required String postId,
    required String autorId,
    required String autorNome,
    required String texto,
    String? parentId,
  }) async {
    final comentario = _comments(
      bubbleId,
      postId,
    ).doc();

    await comentario.set({
      'autorId': autorId,
      'autorNome': autorNome,
      'texto': texto,
      'criadaEm': FieldValue.serverTimestamp(),
      'parentId': parentId,
    });

    await _posts(bubbleId).doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    return comentario.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      ouvirComentarios({
    required String bubbleId,
    required String postId,
  }) {
    return _comments(
      bubbleId,
      postId,
    )
        .orderBy('criadaEm', descending: false)
        .snapshots();
  }

  Future<void> excluirComentario({
    required String bubbleId,
    required String postId,
    required String commentId,
  }) async {
    final comentarios = _comments(
      bubbleId,
      postId,
    );

    final snapshot = await comentarios.get();

    final comentariosParaExcluir = <String>{
      commentId,
    };

    bool encontrouNovos;

    do {
      encontrouNovos = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final parentId = data['parentId'];

        if (parentId != null &&
            comentariosParaExcluir.contains(parentId) &&
            !comentariosParaExcluir.contains(doc.id)) {
          comentariosParaExcluir.add(doc.id);
          encontrouNovos = true;
        }
      }
    } while (encontrouNovos);

    final batch = _firestore.batch();

    for (final id in comentariosParaExcluir) {
      batch.delete(
        comentarios.doc(id),
      );
    }

    final postRef = _posts(bubbleId).doc(postId);

    batch.update(postRef, {
      'commentsCount': FieldValue.increment(
        -comentariosParaExcluir.length,
      ),
    });

    await batch.commit();
  }

  Future<void> excluirPost({
    required String bubbleId,
    required String postId,
  }) async {
    await _posts(bubbleId).doc(postId).delete();
  }
}