import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String autorId;
  final String autorNome;
  final String texto;
  final DateTime? criadaEm;
  final String? parentId;

  CommentModel({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    required this.criadaEm,
    required this.parentId,
  });

  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return CommentModel(
      id: doc.id,
      autorId: data['autorId'] ?? '',
      autorNome: data['autorNome'] ?? 'Usuário',
      texto: data['texto'] ?? '',
      criadaEm: (data['criadaEm'] as Timestamp?)?.toDate(),
      parentId: data['parentId'],
    );
  }
}