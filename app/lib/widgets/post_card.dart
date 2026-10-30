import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/bubble_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/user_profile_screen.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final ValueChanged<int>? onLikeChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeChanged,
  });

  String _formatarData(DateTime? data) {
    if (data == null) return 'Agora';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  Widget _avatarUsuario({
    required String userId,
    required String nome,
    required double radius,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final foto = snapshot.data?.data()?['fotoPerfil'];
        final fotoUrl = foto is String ? foto.trim() : '';

        Widget avatarFallback() {
          return Text(
            nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return SketchAvatar(
          radius: radius,
          backgroundColor: BolhaColors.primary,
          child: fotoUrl.isEmpty
              ? avatarFallback()
              : SizedBox(
                  width: radius * 2,
                  height: radius * 2,
                  child: ClipOval(
                    child: Image.network(
                      fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: avatarFallback(),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _abrirPerfilAutor(
    BuildContext context,
  ) async {
    final usuarioAtual =
        FirebaseAuth.instance.currentUser;

    if (usuarioAtual != null &&
        usuarioAtual.uid == post.autorId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: post.autorId,
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Excluir publicação?',
          ),
          content: const Text(
            'Essa publicação será excluída permanentemente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await PostService().excluirPost(
        bubbleId: post.bubbleId,
        postId: post.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publicação excluída.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'ERRO AO EXCLUIR POST: $e',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir a publicação.',
          ),
        ),
      );
    }
  }

  Widget _botaoExcluir(BuildContext context) {
    return PopupMenuButton<String>(
                      onSelected: (valor) {
                        if (valor == 'excluir') {
                          _confirmarExclusao(
                            context,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem<String>(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: BolhaColors.danger,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Excluir publicação',
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    );
  }

  Future<void> _atualizarCurtidas() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bubbles')
          .doc(post.bubbleId)
          .collection('posts')
          .doc(post.id)
          .get();

      if (!doc.exists) {
        return;
      }

      final data = doc.data();

      final likesCount =
          (data?['likesCount'] as num?)?.toInt() ?? 0;

      onLikeChanged?.call(likesCount);
    } catch (e) {
      debugPrint(
        'ERRO AO BUSCAR LIKES COUNT: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario =
        FirebaseAuth.instance.currentUser;

    final postService = PostService();

    final souAutor =
        usuario != null &&
        usuario.uid == post.autorId;

    return Card(
      color: BolhaColors.surface,
      elevation: 1,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: SketchBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                post: post,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _abrirPerfilAutor(
                          context,
                        );
                      },
                      child: Row(
                        children: [
                          _avatarUsuario(
                            userId: post.autorId,
                            nome: post.autorNome,
                            radius: 21,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.autorNome,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatarData(
                                    post.criadaEm,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        BolhaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (souAutor)
                    _botaoExcluir(context)
                  else if (usuario != null)
                    // Criador, líderes e moderadores da Bolha também
                    // podem excluir publicações de outras pessoas.
                    _SoParaEquipe(
                      bubbleId: post.bubbleId,
                      uid: usuario.uid,
                      child: _botaoExcluir(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BubbleDetailScreen(
                        bubbleId: post.bubbleId,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      size: 19,
                      color: BolhaColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.bubbleNome.isNotEmpty
                          ? post.bubbleNome
                          : 'Bolha',
                      style: const TextStyle(
                        color: BolhaColors.primary,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                post.texto,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              if (post.imagemUrl.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.network(
                    post.imagemUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color:
                            BolhaColors.surface,
                        child: const Center(
                          child: Icon(
                            Icons
                                .broken_image_outlined,
                            size: 45,
                            color: BolhaColors.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              // const SizedBox(height: 14),
              // const Divider(height: 1),
              // const SizedBox(height: 8),
              if (usuario != null)
                StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream:
                      postService.ouvirCurtida(
                    bubbleId: post.bubbleId,
                    postId: post.id,
                    uid: usuario.uid,
                  ),
                  builder:
                      (context, snapshot) {
                    final curtiu =
                        snapshot.data?.exists ??
                            false;

                    return Row(
                      children: [
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          onTap: () async {
                            try {
                              if (curtiu) {
                                await postService
                                    .removerCurtida(
                                  bubbleId:
                                      post.bubbleId,
                                  postId: post.id,
                                  uid: usuario.uid,
                                );
                              } else {
                                await postService
                                    .curtirPost(
                                  bubbleId:
                                      post.bubbleId,
                                  postId: post.id,
                                  uid: usuario.uid,
                                );
                              }

                              await _atualizarCurtidas();
                            } catch (e) {
                              debugPrint(
                                'ERRO AO ALTERAR CURTIDA: $e',
                              );
                            }
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              0,
                              14,
                              14,
                              14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  curtiu
                                      ? Icons.favorite
                                      : Icons
                                          .favorite_border,
                                  size: 12,
                                  color: curtiu
                                      ? BolhaColors.danger
                                      : BolhaColors.textMuted,
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  '${post.likesCount}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: curtiu
                                      ? BolhaColors.danger
                                      : BolhaColors.textMuted,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              '${post.commentsCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: BolhaColors.textMuted,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              post.commentsCount ==
                                      1
                                  ? 'comentário'
                                  : 'comentários',
                              style: TextStyle(
                                fontSize: 14,
                                color: BolhaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra o [child] só para quem faz parte da equipe da Bolha da publicação:
/// o criador, líderes ou moderadores.
class _SoParaEquipe extends StatefulWidget {
  final String bubbleId;
  final String uid;
  final Widget child;

  const _SoParaEquipe({
    required this.bubbleId,
    required this.uid,
    required this.child,
  });

  @override
  State<_SoParaEquipe> createState() => _SoParaEquipeState();
}

class _SoParaEquipeState extends State<_SoParaEquipe> {
  // O criador de cada Bolha é buscado uma vez só e reaproveitado por todas
  // as publicações da mesma Bolha (evita uma leitura por publicação).
  static final Map<String, Future<String>> _criadores = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _membro;
  Future<String>? _criadorId;

  static Future<String> _buscarCriador(String bubbleId) {
    return _criadores.putIfAbsent(bubbleId, () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('bubbles')
            .doc(bubbleId)
            .get();

        return (doc.data()?['criadorId'] ?? '').toString();
      } catch (_) {
        _criadores.remove(bubbleId);
        return '';
      }
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.bubbleId.isEmpty) return;

    _membro = FirebaseFirestore.instance
        .collection('bubbles')
        .doc(widget.bubbleId)
        .collection('members')
        .doc(widget.uid)
        .snapshots();

    _criadorId = _buscarCriador(widget.bubbleId);
  }

  @override
  Widget build(BuildContext context) {
    final membro = _membro;
    final criadorId = _criadorId;

    if (membro == null || criadorId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: membro,
      builder: (context, membroSnapshot) {
        final papel =
            (membroSnapshot.data?.data()?['papel'] ?? 'membro')
                .toString();

        final ehEquipe = papel == 'moderador' || papel == 'lider';

        return FutureBuilder<String>(
          future: criadorId,
          builder: (context, criadorSnapshot) {
            final ehCriador = criadorSnapshot.data == widget.uid;

            if (ehCriador || ehEquipe) {
              return widget.child;
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
