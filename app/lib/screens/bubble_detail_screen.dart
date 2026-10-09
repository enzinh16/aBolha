import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/bubble_model.dart';
import '../models/post_model.dart';
import '../services/bubble_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class BubbleDetailScreen extends StatefulWidget {
  final String bubbleId;

  const BubbleDetailScreen({
    super.key,
    required this.bubbleId,
  });

  @override
  State<BubbleDetailScreen> createState() =>
      _BubbleDetailScreenState();
}

class _BubbleDetailScreenState
    extends State<BubbleDetailScreen> {
  final BubbleService _bubbleService = BubbleService();
  final PostService _postService = PostService();

  bool _processando = false;

  Future<void> _entrarOuSair(
    BubbleModel bubble,
    bool participa,
  ) async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return;

    if (participa) {
      final sair = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sair da Bolha'),
            content: Text(
              'Tem certeza que deseja sair de "${bubble.nome}"?',
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
                child: const Text('Sair'),
              ),
            ],
          );
        },
      );

      if (sair != true) return;
    }

    setState(() {
      _processando = true;
    });

    try {
      if (participa) {
        await _bubbleService.sairDaBolha(
          bubbleId: bubble.id,
          uid: usuario.uid,
        );
      } else {
        await _bubbleService.entrarNaBolha(
          bubbleId: bubble.id,
          uid: usuario.uid,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível realizar a operação.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Data não disponível';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuário não autenticado.',
          ),
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bubbles')
          .doc(widget.bubbleId)
          .snapshots(),
      builder: (context, bubbleSnapshot) {
        if (bubbleSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (bubbleSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar a Bolha:\n'
                  '${bubbleSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!bubbleSnapshot.hasData ||
            !bubbleSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Essa Bolha não existe mais.',
              ),
            ),
          );
        }

        final bubble = BubbleModel.fromFirestore(
          bubbleSnapshot.data!,
        );

        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: _bubbleService.ouvirMembro(
            bubbleId: bubble.id,
            uid: usuario.uid,
          ),
          builder: (context, memberSnapshot) {
            final participa =
                memberSnapshot.data?.exists ?? false;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Bolha'),
              ),
              body: _conteudo(
                bubble,
                participa,
              ),
              floatingActionButton: participa
                  ? FloatingActionButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreatePostScreen(
                              bubbleId: bubble.id,
                              bubbleNome: bubble.nome,
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _conteudo(
    BubbleModel bubble,
    bool participa,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(bubble),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bubble.nome,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  bubble.descricao.isEmpty
                      ? 'Essa Bolha não possui descrição.'
                      : bubble.descricao,
                  style: TextStyle(
                    fontSize: 15,
                    color: BolhaColors.textMuted,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                _informacao(
                  Icons.calendar_today_outlined,
                  'Criada em',
                  _formatarData(bubble.criadaEm),
                ),

                const SizedBox(height: 12),

                _informacao(
                  Icons.person_outline,
                  'Criada por',
                  bubble.criadorNome,
                ),

                const SizedBox(height: 12),

                StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _bubbleService.ouvirMembros(
                    bubble.id,
                  ),
                  builder: (context, snapshot) {
                    final quantidade =
                        snapshot.data?.docs.length ?? 0;

                    return _informacao(
                      Icons.people_outline,
                      'Membros',
                      '$quantidade',
                    );
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _processando
                        ? null
                        : () {
                            _entrarOuSair(
                              bubble,
                              participa,
                            );
                          },
                    child: _processando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            participa
                                ? 'Sair da Bolha'
                                : 'Entrar na Bolha',
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                const Divider(),

                const SizedBox(height: 20),

                const Text(
                  'Postagens',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _postagens(bubble, participa),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postagens(
    BubbleModel bubble,
    bool participa,
  ) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _postService.ouvirPosts(
        bubble.id,
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
            'Erro ao carregar postagens:\n'
            '${snapshot.error}',
          );
        }

        final posts = snapshot.data?.docs
                .map(
                  (doc) => PostModel.fromFirestore(
                    doc,
                    bubble.id,
                  ),
                )
                .toList() ??
            [];

        if (posts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BolhaColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 44,
                  color: BolhaColors.textMuted,
                ),

                const SizedBox(height: 12),

                Text(
                  'Ainda não existem postagens nesta Bolha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BolhaColors.textMuted,
                  ),
                ),

                if (participa) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Seja o primeiro a publicar!',
                    style: TextStyle(
                      color: BolhaColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: posts
              .map(
                (post) => PostCard(
                  post: post,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _cabecalho(BubbleModel bubble) {
    if (bubble.fotoUrl.isEmpty) {
      return Container(
        height: 230,
        color: BolhaColors.surfaceAlt,
        child: const Center(
          child: Icon(
            Icons.groups,
            size: 90,
            color: BolhaColors.primary,
          ),
        ),
      );
    }

    return Image.network(
      bubble.fotoUrl,
      height: 230,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: 230,
          color: BolhaColors.surfaceAlt,
          child: const Center(
            child: Icon(
              Icons.groups,
              size: 90,
              color: BolhaColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _informacao(
    IconData icone,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [
        Icon(
          icone,
          size: 21,
          color: BolhaColors.primary,
        ),

        const SizedBox(width: 10),

        Text(
          '$titulo: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        Expanded(
          child: Text(
            valor,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}