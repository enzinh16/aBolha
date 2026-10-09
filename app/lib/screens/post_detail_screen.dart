import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../screens/user_profile_screen.dart';
import '../screens/profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  final PostService _postService = PostService();

  final TextEditingController _comentarioController =
      TextEditingController();

  bool _enviandoComentario = false;

  CommentModel? _respondendo;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Agora';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  void _abrirPerfilUsuario(
    BuildContext context,
    String userId,
  ) {
    final usuarioAtual =
        FirebaseAuth.instance.currentUser;

    if (usuarioAtual != null &&
        usuarioAtual.uid == userId) {
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
          userId: userId,
        ),
      ),
    );
  }

  Future<void> _enviarComentario() async {
    final texto =
        _comentarioController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return;
    }

    setState(() {
      _enviandoComentario = true;
    });

    try {
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(usuario.uid)
              .get();

      final dadosUsuario =
          usuarioDoc.data();

      final nomeUsuario =
          dadosUsuario?['nome'] ??
          usuario.displayName ??
          'Usuário';

      await _postService.criarComentario(
        bubbleId: widget.post.bubbleId,
        postId: widget.post.id,
        autorId: usuario.uid,
        autorNome: nomeUsuario,
        texto: texto,
        parentId: _respondendo?.id,
      );

      if (!mounted) return;

      _comentarioController.clear();

      setState(() {
        _respondendo = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível enviar o comentário.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviandoComentario = false;
        });
      }
    }
  }

  void _responder(CommentModel comentario) {
    setState(() {
      _respondendo = comentario;
    });
  }

  void _cancelarResposta() {
    setState(() {
      _respondendo = null;
    });
  }

  Future<void> _excluirComentario(
    CommentModel comentario,
  ) async {
    final usuario =
        FirebaseAuth.instance.currentUser;

    if (usuario == null ||
        usuario.uid != comentario.autorId) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir comentário',
          ),
          content: const Text(
            'Tem certeza que deseja excluir este comentário e todas as respostas dele?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
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
      await _postService.excluirComentario(
        bubbleId: widget.post.bubbleId,
        postId: widget.post.id,
        commentId: comentario.id,
      );

      if (!mounted) return;

      if (_respondendo?.id == comentario.id) {
        setState(() {
          _respondendo = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível excluir o comentário.\n$e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postagem'),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _postService.ouvirPost(
          bubbleId: widget.post.bubbleId,
          postId: widget.post.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar postagem:\n'
                '${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Esta postagem não existe mais.',
              ),
            );
          }

          final postAtual =
              PostModel.fromFirestore(
            snapshot.data!,
            widget.post.bubbleId,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _postagem(
                        usuario,
                        postAtual,
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _comentarios(),
                    ],
                  ),
                ),
              ),

              _campoComentario(),
            ],
          );
        },
      ),
    );
  }

  Widget _postagem(
    User? usuario,
    PostModel post,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _abrirPerfilUsuario(
                  context,
                  post.autorId,
                );
              },
              child: SketchAvatar(
                radius: 25,
                backgroundColor:
                    BolhaColors.primary,
                child: Text(
                  post.autorNome.isNotEmpty
                      ? post.autorNome[0]
                          .toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: GestureDetector(
                onTap: () {
                  _abrirPerfilUsuario(
                    context,
                    post.autorId,
                  );
                },
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.autorNome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatarData(
                        post.criadaEm,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: BolhaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          post.texto,
          style: const TextStyle(
            fontSize: 17,
            height: 1.5,
          ),
        ),

        if (post.imagemUrl.isNotEmpty) ...[
          const SizedBox(height: 20),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(16),
            child: Image.network(
              post.imagemUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        BolhaColors.surface,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons
                          .broken_image_outlined,
                      size: 50,
                      color: BolhaColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 20),

        const Divider(),

        const SizedBox(height: 8),

        if (usuario != null)
          StreamBuilder<
              DocumentSnapshot<
                  Map<String, dynamic>>>(
            stream: _postService.ouvirCurtida(
              bubbleId: post.bubbleId,
              postId: post.id,
              uid: usuario.uid,
            ),
            builder: (context, snapshot) {
              final curtiu =
                  snapshot.data?.exists ?? false;

              return Row(
                children: [
                  InkWell(
                    borderRadius:
                        BorderRadius.circular(20),
                    onTap: () async {
                      try {
                        if (curtiu) {
                          await _postService
                              .removerCurtida(
                            bubbleId:
                                post.bubbleId,
                            postId:
                                post.id,
                            uid: usuario.uid,
                          );
                        } else {
                          await _postService
                              .curtirPost(
                            bubbleId:
                                post.bubbleId,
                            postId:
                                post.id,
                            uid: usuario.uid,
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Não foi possível alterar a curtida.\n$e',
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            curtiu
                                ? Icons.favorite
                                : Icons
                                    .favorite_border,
                            size: 25,
                            color: curtiu
                                ? BolhaColors.danger
                                : BolhaColors.textMuted,
                          ),

                          const SizedBox(width: 7),

                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  BolhaColors.textMuted,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            post.likesCount == 1
                                ? 'curtida'
                                : 'curtidas',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  BolhaColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 23,
                        color:
                            BolhaColors.textMuted,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              BolhaColors.textMuted,
                        ),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        post.commentsCount == 1
                            ? 'comentário'
                            : 'comentários',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              BolhaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _comentarios() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _postService.ouvirComentarios(
        bubbleId: widget.post.bubbleId,
        postId: widget.post.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Erro ao carregar comentários:\n'
            '${snapshot.error}',
          );
        }

        final comentarios =
            snapshot.data?.docs
                    .map(
                      (doc) =>
                          CommentModel.fromFirestore(
                        doc,
                      ),
                    )
                    .toList() ??
                [];

        if (comentarios.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  BolhaColors.surface,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 42,
                  color: BolhaColors.textMuted,
                ),

                const SizedBox(height: 12),

                Text(
                  'Ainda não existem comentários.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        BolhaColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        final principais = comentarios
            .where(
              (comentario) =>
                  comentario.parentId == null ||
                  comentario.parentId!.isEmpty,
            )
            .toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: principais
              .map(
                (comentario) => _comentario(
                  comentario,
                  comentarios,
                  0,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _comentario(
    CommentModel comentario,
    List<CommentModel> todos,
    int nivel,
  ) {
    final respostas = todos
        .where(
          (item) =>
              item.parentId == comentario.id,
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: nivel * 24.0,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: nivel == 0
                  ? BolhaColors.surfaceAlt
                  : BolhaColors.surface,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: BolhaColors.surfaceAlt,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _abrirPerfilUsuario(
                          context,
                          comentario.autorId,
                        );
                      },
                      child: SketchAvatar(
                        radius: 18,
                        backgroundColor:
                            BolhaColors.primary,
                        child: Text(
                          comentario.autorNome
                                  .isNotEmpty
                              ? comentario
                                  .autorNome[0]
                                  .toUpperCase()
                              : 'U',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _abrirPerfilUsuario(
                            context,
                            comentario.autorId,
                          );
                        },
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              comentario.autorNome,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              _formatarData(
                                comentario.criadaEm,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: BolhaColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (FirebaseAuth
                            .instance
                            .currentUser
                            ?.uid ==
                        comentario.autorId)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                        ),
                        onSelected: (valor) {
                          if (valor ==
                              'excluir') {
                            _excluirComentario(
                              comentario,
                            );
                          }
                        },
                        itemBuilder:
                            (context) => [
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Text(
                              'Excluir',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  comentario.texto,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    _responder(comentario);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,
                  ),
                  child: const Text(
                    'Responder',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (respostas.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(top: 12),
              child: Column(
                children: respostas
                    .map(
                      (resposta) =>
                          _comentario(
                        resposta,
                        todos,
                        nivel + 1,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _campoComentario() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),
        decoration: BoxDecoration(
          color: BolhaColors.navBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_respondendo != null)
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      BolhaColors.surface,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Respondendo a '
                        '${_respondendo!.autorNome}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed:
                          _cancelarResposta,
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _comentarioController,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration:
                        InputDecoration(
                      hintText:
                          _respondendo == null
                              ? 'Escreva um comentário...'
                              : 'Escreva sua resposta...',
                      counterText: '',
                      filled: true,
                      fillColor:
                          BolhaColors.surface,
                      border:
                          SketchInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  decoration:
                      const BoxDecoration(
                    color:
                        BolhaColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed:
                        _enviandoComentario
                            ? null
                            : _enviarComentario,
                    icon: _enviandoComentario
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color:
                                Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}