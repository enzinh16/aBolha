import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  final ScrollController _scrollController =
      ScrollController();

  final List<PostModel> _posts = [];

  dynamic _ultimoDocumento;

  bool _carregando = true;
  bool _carregandoMais = false;
  bool _temMais = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(
      _verificarScroll,
    );

    _carregarPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _verificarScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final posicao = _scrollController.position;

    if (posicao.pixels >=
        posicao.maxScrollExtent - 300) {
      _carregarMais();
    }
  }

  Future<void> _carregarPosts() async {
    if (_carregandoMais) {
      return;
    }

    setState(() {
      _carregando = true;
      _temMais = true;
      _ultimoDocumento = null;
      _posts.clear();
    });

    try {
      final pagina =
          await _postService.buscarPostsPagina(
        limite: 5,
      );

      final novosPosts = pagina.docs.map(
        (doc) {
          final bubbleId =
              doc.reference.parent.parent?.id ?? '';

          return PostModel.fromFirestore(
            doc,
            bubbleId,
          );
        },
      ).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts.addAll(novosPosts);
        _ultimoDocumento =
            pagina.lastDocument;
        _temMais = pagina.hasMore;
        _carregando = false;
      });
    } catch (e) {
      print('ERRO HOME: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar publicações: $e',
          ),
        ),
      );
    }
  }

  Future<void> _carregarMais() async {
    if (_carregando ||
        _carregandoMais ||
        !_temMais ||
        _ultimoDocumento == null) {
      return;
    }

    setState(() {
      _carregandoMais = true;
    });

    try {
      final pagina =
          await _postService.buscarPostsPagina(
        ultimoDocumento: _ultimoDocumento,
        limite: 5,
      );

      final novosPosts = pagina.docs.map(
        (doc) {
          final bubbleId =
              doc.reference.parent.parent?.id ?? '';

          return PostModel.fromFirestore(
            doc,
            bubbleId,
          );
        },
      ).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts.addAll(novosPosts);
        _ultimoDocumento =
            pagina.lastDocument;
        _temMais = pagina.hasMore;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregandoMais = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar mais publicações: $e',
          ),
        ),
      );
    }
  }

  void _atualizarCurtidas(
    String postId,
    int novoValor,
  ) {
    final index = _posts.indexWhere(
      (post) => post.id == postId,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      final postAtual = _posts[index];

      _posts[index] = PostModel(
        id: postAtual.id,
        autorId: postAtual.autorId,
        autorNome: postAtual.autorNome,
        texto: postAtual.texto,
        imagemUrl: postAtual.imagemUrl,
        criadaEm: postAtual.criadaEm,
        bubbleId: postAtual.bubbleId,
        bubbleNome: postAtual.bubbleNome,
        likesCount: novoValor,
        commentsCount: postAtual.commentsCount,
      );
    });
  }

  Future<void> recarregar() async {
    await _carregarPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _carregarPosts,
              child: _posts.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'Nenhuma publicação encontrada.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller:
                          _scrollController,
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        30,
                      ),
                      itemCount:
                          _posts.length +
                              (_carregandoMais
                                  ? 1
                                  : 0),
                      itemBuilder:
                          (context, index) {
                        if (index >=
                            _posts.length) {
                          return const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          );
                        }

                        return PostCard(
                          post: _posts[index],
                          onLikeChanged:
                              (novoValor) {
                            _atualizarCurtidas(
                              _posts[index].id,
                              novoValor,
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}