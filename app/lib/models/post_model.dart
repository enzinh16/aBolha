import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String autorId;
  final String autorNome;
  final String texto;
  final String imagemUrl;
  final DateTime? criadaEm;
  final String bubbleId;
  final String bubbleNome;
  final int likesCount;
  final int commentsCount;

  PostModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.imagemUrl,
    required this.criadaEm,
    required this.bubbleId,
    required this.bubbleNome,
    required this.likesCount,
    required this.commentsCount,
  });

  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String bubbleId,
  ) {
    final data = doc.data() ?? {};

    return PostModel(
      id: doc.id,
      bubbleId: bubbleId,
      bubbleNome: data['bubbleNome'] ?? 'Bolha',
      autorId: data['autorId'] ?? '',
      autorNome: data['autorNome'] ?? 'Usuário',
      texto: data['texto'] ?? '',
      imagemUrl: data['imagemUrl'] ?? '',
      criadaEm: (data['criadaEm'] as Timestamp?)?.toDate(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }
}