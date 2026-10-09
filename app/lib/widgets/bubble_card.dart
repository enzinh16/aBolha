import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:flutter/material.dart';

import '../models/bubble_model.dart';

class BubbleCard extends StatelessWidget {
  final BubbleModel bubble;
  final VoidCallback onTap;

  const BubbleCard({
    super.key,
    required this.bubble,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: BolhaColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: SketchBorder(
        borderRadius: BorderRadius.circular(16),
        variant: bubble.id.hashCode.abs() % 5,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imagem(),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      bubble.nome,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      bubble.descricao.isEmpty
                          ? 'Sem descrição'
                          : bubble.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: BolhaColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 10),

                    StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bubbles')
                          .doc(bubble.id)
                          .collection('members')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final quantidade =
                            snapshot.data?.docs.length ?? 0;

                        return Text(
                          '$quantidade '
                          '${quantidade == 1 ? 'membro' : 'membros'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: BolhaColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cores das bolhinhas usadas quando a Bolha não tem foto.
  static const _coresBolha = [
    BolhaColors.primary,
    BolhaColors.secondary,
    BolhaColors.orchid,
    BolhaColors.lilac,
  ];

  Widget _imagem() {
    if (bubble.fotoUrl.isEmpty) {
      // Mesma bolha sempre com a mesma cor (baseada no id).
      final cor = _coresBolha[bubble.id.hashCode.abs() % _coresBolha.length];

      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: BolhaColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: SketchAvatar(
            radius: 20,
            backgroundColor: cor,
            variant: bubble.id.hashCode.abs() % 5,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        bubble.fotoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 64,
            height: 64,
            color: BolhaColors.surfaceAlt,
            child: const Icon(
              Icons.groups,
              color: BolhaColors.lilac,
            ),
          );
        },
      ),
    );
  }
}
