import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/sketch_circle_button.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final usuarioAtual = authService.usuarioAtual;

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar os usuários.',
              ),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          final usuarios = documentos
              .where((doc) => doc.id != usuarioAtual.uid)
              .toList();

          if (usuarios.isEmpty) {
            return const Center(
              child: Text(
                'Não existem outros usuários cadastrados.',
              ),
            );
          }

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              final dados = usuario.data();

              final nome = dados['nome'] ?? 'Usuário';
              final email = dados['email'] ?? '';

              return ListTile(
                leading: SketchAvatar(
                  child: Text(
                    nome.isNotEmpty
                        ? nome[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(nome),
                subtitle: Text(email),
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
        },
      ),
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
        title: Text(widget.outroUsuarioNome),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SketchAvatar(
                radius: 16,
                backgroundColor: BolhaColors.secondary,
                child: Text(
                  widget.outroUsuarioNome.isNotEmpty
                      ? widget.outroUsuarioNome[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
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