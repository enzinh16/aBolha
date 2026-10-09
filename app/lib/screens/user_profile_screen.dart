import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

import '../models/post_model.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final PostService _postService =
      PostService();

  final FollowService _followService =
      FollowService();

  String _nomeUsuario = 'Carregando...';

  String _bioUsuario =
      'Nenhuma biografia adicionada ainda.';

  String _fotoPerfilUrl = '';

  String _bannerUrl = '';

  String _dataCriacao = '';

  bool _carregandoDados = true;

  @override
  void initState() {
    super.initState();

    _carregarDadosDoPerfil();
  }

  Future<void> _carregarDadosDoPerfil() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) {
        return;
      }

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _nomeUsuario = 'Usuário do Bolha';
          _carregandoDados = false;
        });

        return;
      }

      final dados = doc.data()!;

      String dataCriacao = '';

      final createdAt = dados['criadoEm'];

      if (createdAt is Timestamp) {
        final data = createdAt.toDate();

        dataCriacao =
            '${data.day.toString().padLeft(2, '0')}/'
            '${data.month.toString().padLeft(2, '0')}/'
            '${data.year}';
      }

      setState(() {
        _nomeUsuario =
            dados['nome'] ?? 'Usuário do Bolha';

        _bioUsuario =
            dados['bio'] != null &&
                    dados['bio']
                        .toString()
                        .isNotEmpty
                ? dados['bio'].toString()
                : 'Nenhuma biografia adicionada ainda.';

        _fotoPerfilUrl =
            dados['fotoPerfil'] ?? '';

        _bannerUrl =
            dados['banner'] ?? '';

        _dataCriacao = dataCriacao;

        _carregandoDados = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nomeUsuario = 'Usuário do Bolha';
        _carregandoDados = false;
      });

      debugPrint(
        'ERRO AO CARREGAR PERFIL: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAtual =
        _auth.currentUser;

    if (usuarioAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Não logado',
          ),
        ),
      );
    }

    // Perfil próprio: mostra a tela "Meu perfil" (a mesma da aba Minha conta).
    if (usuarioAtual.uid == widget.userId) {
      return const ProfileScreen();
    }

    return Scaffold(
      backgroundColor:
          BolhaColors.background,
      appBar: AppBar(
        backgroundColor:
            BolhaColors.background,
        elevation: 0,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: BolhaColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(
          color: BolhaColors.textPrimary,
        ),
      ),
      body: _carregandoDados
          ? const Center(
              child: CircularProgressIndicator(
                color: BolhaColors.primary,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 220,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 160,
                          color:
                              BolhaColors.surfaceAlt,
                          child: _bannerUrl.isNotEmpty
                              ? Image.network(
                                  _bannerUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) {
                                    return const SizedBox
                                        .shrink();
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons
                                        .wb_cloudy_outlined,
                                    color: BolhaColors.secondary,
                                    size: 40,
                                  ),
                                ),
                        ),
                        Positioned(
                          left: 24,
                          top: 110,
                          child: SketchAvatar(
                            radius: 45,
                            backgroundColor: BolhaColors.primary,
                            backgroundImage: _fotoPerfilUrl.isNotEmpty
                                ? NetworkImage(_fotoPerfilUrl)
                                : null,
                            child: _fotoPerfilUrl.isEmpty
                                ? Text(
                                    _nomeUsuario.isNotEmpty
                                        ? _nomeUsuario[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFamily: 'PatrickHand',
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 24,
                          top: 175,
                          child: StreamBuilder<bool>(
                            stream: _followService
                                .ouvirSeSegue(
                              meuUid:
                                  usuarioAtual.uid,
                              usuarioUid:
                                  widget.userId,
                            ),
                            builder:
                                (context, snapshot) {
                              final seguindo =
                                  snapshot.data ??
                                      false;

                              return OutlinedButton(
                                onPressed: () async {
                                  try {
                                    if (seguindo) {
                                      await _followService
                                          .deixarDeSeguir(
                                        meuUid:
                                            usuarioAtual
                                                .uid,
                                        usuarioUid:
                                            widget.userId,
                                      );
                                    } else {
                                      await _followService
                                          .seguir(
                                        meuUid:
                                            usuarioAtual
                                                .uid,
                                        usuarioUid:
                                            widget.userId,
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger
                                            .of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Não foi possível alterar o seguimento.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton
                                    .styleFrom(
                                  side:
                                      const BorderSide(
                                    color:
                                        BolhaColors.primary,
                                  ),
                                  backgroundColor:
                                      seguindo
                                          ? BolhaColors.primary
                                          : Colors
                                              .transparent,
                                  shape:
                                      SketchBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  seguindo
                                      ? 'Seguindo'
                                      : 'Seguir',
                                  style: TextStyle(
                                    color: seguindo
                                        ? Colors.white
                                        : BolhaColors.primary,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          _nomeUsuario,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w900,
                            color: BolhaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bioUsuario,
                          style: const TextStyle(
                            fontSize: 14,
                            color: BolhaColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_dataCriacao.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .calendar_today_outlined,
                                size: 14,
                                color: BolhaColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Conta criada em: '
                                '$_dataCriacao',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color: BolhaColors.textMuted,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        _estatisticasUsuario(),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Postagens',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                            color: BolhaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _postagensUsuario(
                          widget.userId,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _estatisticasUsuario() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius:
                BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserListScreen(
                    userId: widget.userId,
                    tipo: UserListType.followers,
                    titulo: 'Seguidores',
                  ),
                ),
              );
            },
            child: StreamBuilder<int>(
              stream: _followService
                  .ouvirQuantidadeSeguidores(
                widget.userId,
              ),
              builder:
                  (context, snapshot) {
                return _estatistica(
                  valor: '${snapshot.data ?? 0}',
                  texto: 'Seguidores',
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius:
                BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserListScreen(
                    userId: widget.userId,
                    tipo: UserListType.following,
                    titulo: 'Seguindo',
                  ),
                ),
              );
            },
            child: StreamBuilder<int>(
              stream: _followService
                  .ouvirQuantidadeSeguindo(
                widget.userId,
              ),
              builder:
                  (context, snapshot) {
                return _estatistica(
                  valor: '${snapshot.data ?? 0}',
                  texto: 'Seguindo',
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _estatistica({
    required String valor,
    required String texto,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: BolhaColors.surface,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: BolhaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postagensUsuario(String uid) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _postService.ouvirMeusPosts(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: BolhaColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar postagens:\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: BolhaColors.textMuted,
              ),
            ),
          );
        }

        final posts = snapshot.data?.docs
                .map(
                  (doc) {
                    final bubbleId =
                        doc.reference.parent.parent?.id ??
                            '';

                    return PostModel.fromFirestore(
                      doc,
                      bubbleId,
                    );
                  },
                )
                .toList() ??
            [];

        posts.sort(
          (a, b) {
            if (a.criadaEm == null) return 1;
            if (b.criadaEm == null) return -1;

            return b.criadaEm!
                .compareTo(a.criadaEm!);
          },
        );

        if (posts.isEmpty) {
          return const Center(
            child: Column(
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 48,
                  color: BolhaColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'Nenhuma postagem realizada ainda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: BolhaColors.textMuted,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
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
}

enum UserListType {
  followers,
  following,
}

class UserListScreen extends StatelessWidget {
  final String userId;
  final UserListType tipo;
  final String titulo;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.tipo,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    final collection = tipo ==
            UserListType.followers
        ? 'followers'
        : 'following';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collection)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: BolhaColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar lista:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final documentos =
              snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return Center(
              child: Text(
                tipo ==
                        UserListType.followers
                    ? 'Nenhum seguidor ainda.'
                    : 'Não segue ninguém ainda.',
              ),
            );
          }

          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final uid =
                  documentos[index].id;

              return _UsuarioListaItem(
                uid: uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _UsuarioListaItem
    extends StatelessWidget {
  final String uid;

  const _UsuarioListaItem({
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: SketchAvatar(
              backgroundColor:
                  BolhaColors.primary,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Carregando...',
            ),
          );
        }

        final dados =
            snapshot.data!.data() ?? {};

        final nome =
            dados['nome'] ??
                'Usuário do Bolha';

        final foto =
            dados['fotoPerfil'] ?? '';

        return ListTile(
          leading: SketchAvatar(
            backgroundColor:
                BolhaColors.primary,
            backgroundImage:
                foto.toString().isNotEmpty
                    ? NetworkImage(
                        foto.toString(),
                      )
                    : null,
            child:
                foto.toString().isEmpty
                    ? Text(
                        nome.toString()
                                .isNotEmpty
                            ? nome
                                .toString()[0]
                                .toUpperCase()
                            : 'U',
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      )
                    : null,
          ),
          title: Text(
            nome.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UserProfileScreen(
                  userId: uid,
                ),
              ),
            );
          },
        );
      },
    );
  }
}