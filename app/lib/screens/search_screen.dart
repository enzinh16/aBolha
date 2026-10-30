import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/bubble_model.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import '../widgets/bubble_card.dart';
import '../widgets/post_card.dart';
import 'bubble_detail_screen.dart';
import 'profile_screen.dart';
import 'user_profile_screen.dart';

/// Quantos itens de cada tipo são baixados para a busca. A busca só enxerga
/// esses itens (os mais recentes). Aumente se precisar de mais alcance.
const int _limiteBolhas = 200;
const int _limiteUsuarios = 200;
const int _limitePosts = 100;

/// Põe em minúsculas e tira acentos: "Açaí" -> "acai".
String normalizarBusca(String texto) {
  const comAcento = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
  const semAcento = 'aaaaaaeeeeiiiiooooouuuuyycn';

  var r = texto.toLowerCase().trim();

  for (var i = 0; i < comAcento.length; i++) {
    r = r.replaceAll(comAcento[i], semAcento[i]);
  }

  return r;
}

/// Verdadeiro se TODAS as palavras da busca aparecem em algum dos campos.
bool _combina(String termoNormalizado, List<String> campos) {
  final texto = normalizarBusca(campos.join(' '));
  final palavras =
      termoNormalizado.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);

  return palavras.every(texto.contains);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  // 0 = Bolhas, 1 = Pessoas, 2 = Posts
  int _aba = 0;
  String _termo = '';

  // Cada lista é baixada uma vez, na primeira vez que a aba é aberta.
  List<BubbleModel>? _bolhas;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _usuarios;
  List<PostModel>? _posts;

  final Set<int> _carregando = {};
  final Map<int, String> _erros = {};

  @override
  void initState() {
    super.initState();
    _carregar(_aba);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _aoDigitar(String valor) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _termo = normalizarBusca(valor));
    });
  }

  void _limpar() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _termo = '');
  }

  void _trocarAba(int aba) {
    if (aba == _aba) return;

    setState(() => _aba = aba);
    _carregar(aba);
  }

  bool _jaCarregada(int aba) {
    switch (aba) {
      case 0:
        return _bolhas != null;
      case 1:
        return _usuarios != null;
      default:
        return _posts != null;
    }
  }

  Future<void> _carregar(int aba, {bool forcar = false}) async {
    if (_carregando.contains(aba)) return;
    if (!forcar && _jaCarregada(aba)) return;

    setState(() {
      _carregando.add(aba);
      _erros.remove(aba);
    });

    try {
      final db = FirebaseFirestore.instance;

      if (aba == 0) {
        final snap = await db
            .collection('bubbles')
            .orderBy('criadaEm', descending: true)
            .limit(_limiteBolhas)
            .get();

        _bolhas = snap.docs.map(BubbleModel.fromFirestore).toList();
      } else if (aba == 1) {
        final snap = await db.collection('users').limit(_limiteUsuarios).get();

        _usuarios = snap.docs;
      } else {
        final snap = await db
            .collectionGroup('posts')
            .orderBy('criadaEm', descending: true)
            .limit(_limitePosts)
            .get();

        _posts = snap.docs.map((doc) {
          final bubbleId = doc.reference.parent.parent?.id ?? '';

          return PostModel.fromFirestore(doc, bubbleId);
        }).toList();
      }
    } catch (e) {
      debugPrint('ERRO NA BUSCA (aba $aba): $e');
      _erros[aba] = e.toString();
    }

    if (!mounted) return;

    setState(() => _carregando.remove(aba));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Pesquisa'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _campoDeBusca(),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _seletorDeAbas(),
          ),
          const SizedBox(height: 14),
          Expanded(child: _conteudo()),
        ],
      ),
    );
  }

  Widget _campoDeBusca() {
    return TextField(
      controller: _controller,
      onChanged: _aoDigitar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: _aba == 0
            ? 'Buscar bolhas'
            : _aba == 1
                ? 'Buscar pessoas'
                : 'Buscar posts',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: _limpar,
              ),
        filled: true,
        fillColor: BolhaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: const SketchInputBorder(
          borderSide: BorderSide(
            color: BolhaColors.outline,
            width: 1.6,
          ),
        ),
        enabledBorder: const SketchInputBorder(
          borderSide: BorderSide(
            color: BolhaColors.outline,
            width: 1.6,
          ),
        ),
        focusedBorder: const SketchInputBorder(
          borderSide: BorderSide(
            color: BolhaColors.secondary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _seletorDeAbas() {
    const rotulos = ['Bolhas', 'Pessoas', 'Posts'];

    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: ShapeDecoration(
        color: BolhaColors.background,
        shape: SketchBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: BolhaColors.outline,
            width: 1.6,
          ),
          variant: 2,
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment(_aba - 1.0, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: BolhaColors.surfaceAlt,
                  shape: SketchBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: BolhaColors.outline,
                      width: 2,
                    ),
                    variant: 4,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < rotulos.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _trocarAba(i),
                    child: Center(
                      child: Text(
                        rotulos[i],
                        style: TextStyle(
                          fontSize: 16,
                          color: _aba == i
                              ? BolhaColors.textPrimary
                              : BolhaColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mensagem(String titulo, String subtitulo, {IconData? icone}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone ?? Icons.search,
              size: 48,
              color: BolhaColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BolhaColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando.contains(_aba) && !_jaCarregada(_aba)) {
      return const Center(child: CircularProgressIndicator());
    }

    final erro = _erros[_aba];

    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Erro ao carregar:\n$erro',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _carregar(_aba, forcar: true),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_termo.isEmpty) {
      return _mensagem(
        'O que você procura?',
        'Digite para pesquisar.',
      );
    }

    switch (_aba) {
      case 0:
        return _resultadoBolhas();
      case 1:
        return _resultadoPessoas();
      default:
        return _resultadoPosts();
    }
  }

  Widget _semResultado() {
    return _mensagem(
      'Nada encontrado',
      'Tente outras palavras.',
      icone: Icons.search_off,
    );
  }

  Widget _resultadoBolhas() {
    final lista = (_bolhas ?? [])
        .where((b) => _combina(_termo, [b.nome]))
        .toList();

    if (lista.isEmpty) return _semResultado();

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final bolha = lista[index];

        return BubbleCard(
          bubble: bolha,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BubbleDetailScreen(bubbleId: bolha.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _resultadoPessoas() {
    final lista = (_usuarios ?? []).where((doc) {
      final nome = (doc.data()['nome'] ?? '').toString();

      return _combina(_termo, [nome]);
    }).toList();

    if (lista.isEmpty) return _semResultado();

    final meuUid = FirebaseAuth.instance.currentUser?.uid;

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final doc = lista[index];
        final dados = doc.data();

        final nome = (dados['nome'] ?? 'Usuário').toString();
        final foto = (dados['fotoPerfil'] ?? '').toString().trim();

        Widget inicial() {
          return Text(
            nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return ListTile(
          leading: SketchAvatar(
            radius: 24,
            backgroundColor: BolhaColors.primary,
            child: foto.isEmpty
                ? inicial()
                : SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipOval(
                      child: Image.network(
                        foto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: inicial()),
                      ),
                    ),
                  ),
          ),
          title: Text(nome),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => doc.id == meuUid
                    ? const ProfileScreen()
                    : UserProfileScreen(userId: doc.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _resultadoPosts() {
    final lista = (_posts ?? [])
        .where((p) => _combina(_termo, [p.texto, p.autorNome, p.bubbleNome]))
        .toList();

    if (lista.isEmpty) return _semResultado();

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        return PostCard(
          key: ValueKey('${lista[index].bubbleId}/${lista[index].id}'),
          post: lista[index],
        );
      },
    );
  }
}
