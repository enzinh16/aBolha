import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostService _postService = PostService();

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
    final User? usuarioAtual = _auth.currentUser;

    if (usuarioAtual == null) {
      if (mounted) {
        setState(() {
          _carregandoDados = false;
        });
      }

      return;
    }

    try {
      final DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(usuarioAtual.uid)
              .get();

      if (usuarioAtual.metadata.creationTime != null) {
        final data =
            usuarioAtual.metadata.creationTime!;

        _dataCriacao =
            '${data.day.toString().padLeft(2, '0')}/'
            '${data.month.toString().padLeft(2, '0')}/'
            '${data.year}';
      }

      if (doc.exists && doc.data() != null) {
        final dados =
            doc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _nomeUsuario =
                dados['nome'] ?? 'Usuário do Bolha';

            _bioUsuario =
                dados['bio'] != null &&
                        dados['bio']
                            .toString()
                            .isNotEmpty
                    ? dados['bio']
                    : 'Nenhuma biografia adicionada ainda.';

            _fotoPerfilUrl =
                dados['fotoPerfil'] ?? '';

            _bannerUrl =
                dados['banner'] ?? '';

            _carregandoDados = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _nomeUsuario =
                usuarioAtual.displayName ??
                    'Usuário do Bolha';

            _carregandoDados = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nomeUsuario =
              usuarioAtual.displayName ??
                  'Usuário do Bolha';

          _carregandoDados = false;
        });
      }
    }
  }

  void _abrirListaSeguidores() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserListScreen(
          userId: usuario.uid,
          tipo: UserListType.followers,
        ),
      ),
    );
  }

  void _abrirListaSeguindo() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserListScreen(
          userId: usuario.uid,
          tipo: UserListType.following,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? usuario = _auth.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Não logado',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'PatrickHand',
              fontWeight: FontWeight.w600,
              color: BolhaColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
      ),
      backgroundColor: BolhaColors.background,
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
                                      (c, e, s) =>
                                          const SizedBox
                                              .shrink(),
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
                          child: OutlinedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );

                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                _carregandoDados = true;
                              });

                              _carregarDadosDoPerfil();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: BolhaColors.primary,
                              ),
                              shape:
                                  SketchBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Editar Perfil',
                              style: TextStyle(
                                color:
                                    BolhaColors.primary,
                                fontFamily: 'PatrickHand',
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24.0,
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
                            fontWeight: FontWeight.w900,
                            fontFamily: 'PatrickHand',
                            color: BolhaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bioUsuario,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'PatrickHand',
                            color: BolhaColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'PatrickHand',
                                color: BolhaColors.textMuted,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _estatisticasUsuario(
                          usuario.uid,
                        ),

                        const SizedBox(height: 24),

                        const Divider(),

                        const SizedBox(height: 16),

                        const Text(
                          'Minhas Postagens',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'PatrickHand',
                            fontWeight: FontWeight.w800,
                            color: BolhaColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _minhasPostagens(usuario.uid),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _estatisticasUsuario(String uid) {
    return Row(
      children: [
        Expanded(
          child: _botaoEstatistica(
            titulo: 'Seguidores',
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('followers')
                .snapshots(),
            onTap: _abrirListaSeguidores,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _botaoEstatistica(
            titulo: 'Seguindo',
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('following')
                .snapshots(),
            onTap: _abrirListaSeguindo,
          ),
        ),
      ],
    );
  }

  Widget _botaoEstatistica({
    required String titulo,
    required Stream<QuerySnapshot<Map<String, dynamic>>>
        stream,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final quantidade =
            snapshot.data?.docs.length ?? 0;

        return Material(
          color: BolhaColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: BolhaColors.surfaceAlt,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$quantidade',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'PatrickHand',
                      fontWeight: FontWeight.w800,
                      color: BolhaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'PatrickHand',
                      fontWeight: FontWeight.w600,
                      color: BolhaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _minhasPostagens(String uid) {
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
          print('ERRO AO CARREGAR POSTAGENS:');
          print(snapshot.error);

          return Center(
            child: Text(
              'Erro ao carregar suas postagens:\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PatrickHand',
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

            return b.criadaEm!.compareTo(
              a.criadaEm!,
            );
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
                    fontFamily: 'PatrickHand',
                    fontSize: 14,
                    color: BolhaColors.textMuted,
                    fontWeight: FontWeight.w500,
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

  const UserListScreen({
    super.key,
    required this.userId,
    required this.tipo,
  });

  String get _titulo {
    if (tipo == UserListType.followers) {
      return 'Seguidores';
    }

    return 'Seguindo';
  }

  String get _subcolecao {
    if (tipo == UserListType.followers) {
      return 'followers';
    }

    return 'following';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titulo,
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(_subcolecao)
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar lista:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BolhaColors.textMuted,
                  ),
                ),
              ),
            );
          }

          final documentos =
              snapshot.data?.docs ?? [];

          if (documentos.isEmpty) {
            return Center(
              child: Text(
                tipo == UserListType.followers
                    ? 'Você ainda não possui seguidores.'
                    : 'Você ainda não segue ninguém.',
                style: const TextStyle(
                  color: BolhaColors.textMuted,
                  fontSize: 15,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            itemCount: documentos.length,
            separatorBuilder: (_, __) =>
                const Divider(
              height: 1,
            ),
            itemBuilder: (context, index) {
              final documento =
                  documentos[index];

              final outroUsuarioId =
                  documento.id;

              return _UsuarioListaItem(
                userId: outroUsuarioId,
              );
            },
          );
        },
      ),
    );
  }
}

class _UsuarioListaItem extends StatelessWidget {
  final String userId;

  const _UsuarioListaItem({
    required this.userId,
  });

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _buscarUsuario() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: _buscarUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const ListTile(
            leading: SketchAvatar(
              backgroundColor:
                  BolhaColors.surfaceAlt,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BolhaColors.primary,
              ),
            ),
            title: Text(
              'Carregando...',
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const ListTile(
            leading: SketchAvatar(
              backgroundColor:
                  BolhaColors.surfaceAlt,
              child: Icon(
                Icons.person_outline,
                color: BolhaColors.primary,
              ),
            ),
            title: Text(
              'Usuário não encontrado',
            ),
          );
        }

        final dados =
            snapshot.data!.data() ?? {};

        final nome =
            dados['nome']?.toString().isNotEmpty ==
                    true
                ? dados['nome'].toString()
                : 'Usuário do Bolha';

        final foto =
            dados['fotoPerfil']?.toString() ?? '';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: SketchAvatar(
            radius: 24,
            backgroundColor:
                BolhaColors.primary,
            backgroundImage: foto.isNotEmpty
                ? NetworkImage(foto)
                : null,
            child: foto.isEmpty
                ? Text(
                    nome.isNotEmpty
                        ? nome[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            nome,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: BolhaColors.textMuted,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                  userId: userId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}