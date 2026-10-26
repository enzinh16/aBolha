import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/sketch_circle_button.dart';
import 'user_profile_screen.dart';

/// Resumo da última mensagem de uma conversa.
class _UltimaMensagem {
  final String texto;
  final String senderId;
  final DateTime? data;

  const _UltimaMensagem({
    required this.texto,
    required this.senderId,
    required this.data,
  });

  /// Procura o primeiro campo do tipo Timestamp do documento, assim não
  /// depende do nome do campo usado no ChatService.
  static DateTime? _extrairData(Map<String, dynamic> dados) {
    for (final valor in dados.values) {
      if (valor is Timestamp) {
        return valor.toDate();
      }
    }
    return null;
  }

  /// Escolhe a mensagem mais recente entre os documentos da conversa.
  static _UltimaMensagem? deDocumentos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return null;

    QueryDocumentSnapshot<Map<String, dynamic>>? maisRecente;
    DateTime? maiorData;

    for (final doc in docs) {
      // Mensagem recém-enviada ainda sem o horário do servidor.
      final data = doc.metadata.hasPendingWrites
          ? DateTime.now()
          : _extrairData(doc.data());

      if (data != null &&
          (maiorData == null || data.isAfter(maiorData))) {
        maiorData = data;
        maisRecente = doc;
      }
    }

    // Se nenhuma mensagem tiver horário, usa a última da lista.
    maisRecente ??= docs.last;

    final dados = maisRecente.data();

    return _UltimaMensagem(
      texto: (dados['text'] ?? '').toString(),
      senderId: (dados['senderId'] ?? '').toString(),
      data: maiorData,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _usuariosSubscription;

  // Uma assinatura por conversa, para acompanhar a última mensagem.
  final Map<String,
          StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _mensagensSubscriptions = {};

  final Map<String, _UltimaMensagem> _ultimasMensagens = {};

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _usuarios;
  bool _erroAoCarregar = false;

  @override
  void initState() {
    super.initState();

    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual == null) return;

    _usuariosSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen(
      (snapshot) {
        final outros = snapshot.docs
            .where((doc) => doc.id != usuarioAtual.uid)
            .toList();

        _sincronizarConversas(usuarioAtual.uid, outros);

        if (!mounted) return;

        setState(() {
          _usuarios = outros;
          _erroAoCarregar = false;
        });
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _erroAoCarregar = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _usuariosSubscription?.cancel();

    for (final assinatura in _mensagensSubscriptions.values) {
      assinatura.cancel();
    }

    super.dispose();
  }

  void _sincronizarConversas(
    String meuUid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> outros,
  ) {
    final idsAtuais = outros.map((doc) => doc.id).toSet();

    // Cancela as conversas de usuários que não existem mais.
    final removidos = _mensagensSubscriptions.keys
        .where((id) => !idsAtuais.contains(id))
        .toList();

    for (final id in removidos) {
      _mensagensSubscriptions.remove(id)?.cancel();
      _ultimasMensagens.remove(id);
    }

    // Começa a acompanhar as conversas novas.
    for (final id in idsAtuais) {
      if (_mensagensSubscriptions.containsKey(id)) continue;

      final conversationId = _chatService.gerarConversationId(
        meuUid,
        id,
      );

      _mensagensSubscriptions[id] =
          _chatService.ouvirMensagens(conversationId).listen(
        (snapshot) {
          final ultima =
              _UltimaMensagem.deDocumentos(snapshot.docs);

          if (!mounted) return;

          setState(() {
            if (ultima == null) {
              _ultimasMensagens.remove(id);
            } else {
              _ultimasMensagens[id] = ultima;
            }
          });
        },
        onError: (_) {},
      );
    }
  }

  /// Conversas com mensagem primeiro (da mais recente para a mais antiga),
  /// depois os usuários sem conversa em ordem alfabética.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordenar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> usuarios,
  ) {
    final lista = [...usuarios];

    lista.sort((a, b) {
      final ultimaA = _ultimasMensagens[a.id];
      final ultimaB = _ultimasMensagens[b.id];

      if (ultimaA != null && ultimaB != null) {
        final dataA =
            ultimaA.data ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dataB =
            ultimaB.data ?? DateTime.fromMillisecondsSinceEpoch(0);

        return dataB.compareTo(dataA);
      }

      if (ultimaA != null) return -1;
      if (ultimaB != null) return 1;

      final nomeA = (a.data()['nome'] ?? '').toString().toLowerCase();
      final nomeB = (b.data()['nome'] ?? '').toString().toLowerCase();

      return nomeA.compareTo(nomeB);
    });

    return lista;
  }

  String _textoDaUltimaMensagem(
    _UltimaMensagem? ultima,
    String meuUid,
  ) {
    if (ultima == null) {
      return 'Nenhuma mensagem ainda';
    }

    final texto = ultima.texto.replaceAll('\n', ' ').trim();

    if (ultima.senderId == meuUid) {
      return 'Você: $texto';
    }

    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
      ),
      body: _corpo(usuarioAtual.uid),
    );
  }

  Widget _corpo(String meuUid) {
    if (_erroAoCarregar) {
      return const Center(
        child: Text(
          'Não foi possível carregar os usuários.',
        ),
      );
    }

    final usuariosCarregados = _usuarios;

    if (usuariosCarregados == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (usuariosCarregados.isEmpty) {
      return const Center(
        child: Text(
          'Não existem outros usuários cadastrados.',
        ),
      );
    }

    final usuarios = _ordenar(usuariosCarregados);

    return ListView.builder(
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final dados = usuario.data();

        final nome = (dados['nome'] ?? 'Usuário').toString();
        final fotoPerfil = (dados['fotoPerfil'] ?? '').toString();

        final ultima = _ultimasMensagens[usuario.id];

        return ListTile(
          leading: _AvatarUsuario(
            userId: usuario.id,
            nome: nome,
            radius: 24,
            fotoPerfilUrl: fotoPerfil,
          ),
          title: Text(nome),
          subtitle: Text(
            _textoDaUltimaMensagem(ultima, meuUid),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.chat_bubble_outline,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversaScreen(
                  outroUsuarioId: usuario.id,
                  outroUsuarioNome: nome,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ConversaScreen extends StatefulWidget {
  final String outroUsuarioId;
  final String outroUsuarioNome;

  const ConversaScreen({
    super.key,
    required this.outroUsuarioId,
    required this.outroUsuarioNome,
  });

  @override
  State<ConversaScreen> createState() => _ConversaScreenState();
}

class _ConversaScreenState extends State<ConversaScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  final TextEditingController _mensagemController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late String _conversationId;

  @override
  void initState() {
    super.initState();

    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual != null) {
      _conversationId = _chatService.gerarConversationId(
        usuarioAtual.uid,
        widget.outroUsuarioId,
      );

      _criarConversa();
    }
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _criarConversa() async {
    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual == null) return;

    print('USUÁRIO LOGADO: ${usuarioAtual.uid}');
    print('OUTRO USUÁRIO: ${widget.outroUsuarioId}');

    try {
      await _chatService.criarConversa(
        uid1: usuarioAtual.uid,
        uid2: widget.outroUsuarioId,
      );

      print('CONVERSA CRIADA COM SUCESSO');
    } catch (e) {
      print('ERRO AO CRIAR CONVERSA: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
        ),
      );
    }
  }

  void _abrirPerfilDoOutroUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: widget.outroUsuarioId,
        ),
      ),
    );
  }

  Future<void> _enviarMensagem() async {
    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual == null) return;

    final texto = _mensagemController.text.trim();

    if (texto.isEmpty) return;

    _mensagemController.clear();

    try {
      await _chatService.enviarMensagem(
        conversationId: _conversationId,
        senderId: usuarioAtual.uid,
        texto: texto,
      );

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível enviar a mensagem.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAtual = _authService.usuarioAtual;

    if (usuarioAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não autenticado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: _abrirPerfilDoOutroUsuario,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _AvatarUsuario(
                  userId: widget.outroUsuarioId,
                  nome: widget.outroUsuarioNome,
                  radius: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _abrirPerfilDoOutroUsuario,
                child: Text(
                  widget.outroUsuarioNome,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.ouvirMensagens(
                _conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Não foi possível carregar as mensagens.',
                    ),
                  );
                }

                final mensagens =
                    snapshot.data?.docs ?? [];

                if (mensagens.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\n'
                      'Envie uma mensagem para começar.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final dados = mensagens[index].data();

                    final senderId =
                        dados['senderId'] ?? '';

                    final texto =
                        dados['text'] ?? '';

                    final souEu =
                        senderId == usuarioAtual.uid;

                    return Align(
                      alignment: souEu
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width *
                                  0.75,
                        ),
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: ShapeDecoration(
                          color: souEu
                              ? BolhaColors.primary
                              : BolhaColors.surface,
                          shape: SketchBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            side: const BorderSide(
                              color: BolhaColors.outline,
                              width: 1.8,
                            ),
                            // Varia o traço de uma mensagem para outra
                            variant: index,
                          ),
                        ),
                        child: Text(
                          texto,
                          style: const TextStyle(
                            color: BolhaColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: BolhaColors.background,
                        shape: SketchBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          side: const BorderSide(
                            color: BolhaColors.primary,
                            width: 2.5,
                          ),
                          variant: 3,
                        ),
                      ),
                      child: TextField(
                        controller: _mensagemController,
                        textInputAction:
                            TextInputAction.send,
                        onSubmitted: (_) {
                          _enviarMensagem();
                        },
                        style: const TextStyle(
                          color: BolhaColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          hintStyle: TextStyle(
                            color: BolhaColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SketchCircleButton(
                    icon: Icons.send_rounded,
                    tooltip: 'Enviar',
                    onPressed: _enviarMensagem,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarUsuario extends StatelessWidget {
  final String userId;
  final String nome;
  final double radius;
  final String? fotoPerfilUrl;

  const _AvatarUsuario({
    required this.userId,
    required this.nome,
    required this.radius,
    this.fotoPerfilUrl,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final dados = snapshot.data?.data();
        final foto = (dados?['fotoPerfil'] ?? fotoPerfilUrl ?? '')
            .toString()
            .trim();
        final nomeAtual = (dados?['nome'] ?? nome).toString();

        return SketchAvatar(
          radius: radius,
          backgroundColor: BolhaColors.primary,
          backgroundImage:
              foto.isNotEmpty ? NetworkImage(foto) : null,
          child: foto.isEmpty
              ? Text(
                  nomeAtual.trim().isNotEmpty
                      ? nomeAtual.trim()[0].toUpperCase()
                      : '?',
                  // Estilo explícito para a letra ficar igual na lista e
                  // dentro da conversa (o AppBar impõe um estilo mais grosso)
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: radius * 0.8,
                      ),
                )
              : null,
        );
      },
    );
  }
}