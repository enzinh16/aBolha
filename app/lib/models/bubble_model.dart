import 'package:cloud_firestore/cloud_firestore.dart';

class BubbleModel {
  final String id;
  final String nome;
  final String descricao;
  final String fotoUrl;
  final String criadorId;
  final String criadorNome;
  final DateTime? criadaEm;

  BubbleModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.fotoUrl,
    required this.criadorId,
    required this.criadorNome,
    required this.criadaEm,
  });

  factory BubbleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return BubbleModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      criadorId: data['criadorId'] ?? '',
      criadorNome: data['criadorNome'] ?? '',
      criadaEm: (data['criadaEm'] as Timestamp?)?.toDate(),
    );
  }
}