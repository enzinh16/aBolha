import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/bubble_service.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'user_profile_screen.dart';

/// Lista de quem faz parte de uma Bolha, com os papéis:
/// criador > líder > moderador > membro.
///
///  - Criador: tudo. Só ele torna alguém líder, tira a liderança ou remove
///    um líder. Ninguém mexe no criador.
///  - Líder: torna membros moderadores, rebaixa moderadores e remove
///    moderadores e membros (não mexe em outros líderes nem no criador).
///  - Moderador: torna membros comuns moderadores e remove membros comuns.
class BubbleMembersScreen extends StatelessWidget {
  final String bubbleId;
  final String criadorId;

  const BubbleMembersScreen({
    super.key,
    required this.bubbleId,
    this.criadorId = '',
  });

  String _papelDe(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return (doc.data()['papel'] ?? papelMembro).toString();
  }

  // 0 = criador, 1 = líder, 2 = moderador, 3 = membro comum
  int _ordem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (doc.id == criadorId) return 0;

    final papel = _papelDe(doc);

    if (papel == papelLider) return 1;
    if (papel == papelModerador) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final meuUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membros'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bubbles')
            .doc(bubbleId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                  'Erro ao carregar membros:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BolhaColors.textMuted,
                  ),
                ),
              ),
            );
          }

          final documentos = [...(snapshot.data?.docs ?? [])];

          if (documentos.isEmpty) {
            return const Center(
              child: Text(
                'Esta Bolha ainda não possui membros.',
                style: TextStyle(
                  color: BolhaColors.textMuted,
                  fontSize: 15,
                ),
              ),
            );
          }

          // Meu papel nesta Bolha
          final souCriador = meuUid.isNotEmpty && meuUid == criadorId;
          var souLider = false;
          var souModerador = false;

          for (final doc in documentos) {
            if (doc.id != meuUid) continue;

            final papel = _papelDe(doc);

            if (papel == papelLider) souLider = true;
            if (papel == papelModerador) souModerador = true;
          }

          // Criador, líderes, moderadores e membros; dentro de cada grupo,
          // do mais antigo para o mais novo.
          documentos.sort((a, b) {
            final porGrupo = _ordem(a).compareTo(_ordem(b));
            if (porGrupo != 0) return porGrupo;

            final dataA = a.data()['entrouEm'];
            final dataB = b.data()['entrouEm'];

            if (dataA is! Timestamp) return 1;
            if (dataB is! Timestamp) return -1;

            return dataA.compareTo(dataB);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: documentos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = documentos[index];
              final uid = doc.id;
              final papel = _papelDe(doc);

              final ehCriador = uid == criadorId;
              final ehLider = !ehCriador && papel == papelLider;
              final ehModerador = !ehCriador && papel == papelModerador;
              final ehMembroComum = !ehCriador && !ehLider && !ehModerador;
              final souEu = uid == meuUid;

              // Torna moderador: criador, líder e moderador, só em
              // membros comuns.
              final podePromover =
                  (souCriador || souLider || souModerador) &&
                      ehMembroComum &&
                      !souEu;

              // Torna líder / tira a liderança: só o criador.
              final podeTornarLider =
                  souCriador && !ehCriador && !ehLider && !souEu;
              final podeRebaixarLider = souCriador && ehLider;

              // Rebaixa moderador a membro: criador e líder.
              final podeRebaixar =
                  (souCriador || souLider) && ehModerador;

              // Remove da Bolha: ninguém remove o criador nem a si mesmo
              // por aqui. Criador remove qualquer um; líder remove
              // moderadores e membros; moderador remove membros comuns.
              final podeRemover = !ehCriador &&
                  !souEu &&
                  (souCriador ||
                      (souLider && !ehLider) ||
                      (souModerador && ehMembroComum));

              return _MembroListaItem(
                key: ValueKey(uid),
                bubbleId: bubbleId,
                userId: uid,
                meuUid: meuUid,
                ehCriador: ehCriador,
                ehLider: ehLider,
                ehModerador: ehModerador,
                podePromover: podePromover,
                podeTornarLider: podeTornarLider,
                podeRebaixar: podeRebaixar,
                podeRebaixarLider: podeRebaixarLider,
                podeRemover: podeRemover,
              );
            },
          );
        },
      ),
    );
  }
}

class _MembroListaItem extends StatefulWidget {
  final String bubbleId;
  final String userId;
  final String meuUid;
  final bool ehCriador;
  final bool ehLider;
  final bool ehModerador;
  final bool podePromover;
  final bool podeTornarLider;
  final bool podeRebaixar;
  final bool podeRebaixarLider;
  final bool podeRemover;

  const _MembroListaItem({
    super.key,
    required this.bubbleId,
    required this.userId,
    required this.meuUid,
    required this.ehCriador,
    required this.ehLider,
    required this.ehModerador,
    required this.podePromover,
    required this.podeTornarLider,
    required this.podeRebaixar,
    required this.podeRebaixarLider,
    required this.podeRemover,
  });

  @override
  State<_MembroListaItem> createState() => _MembroListaItemState();
}

class _MembroListaItemState extends State<_MembroListaItem> {
  final BubbleService _bubbleService = BubbleService();

  // Guardado uma vez só, para o item não piscar "Carregando..." toda vez
  // que a lista de membros atualiza (por exemplo, depois de promover).
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _usuario;

  @override
  void initState() {
    super.initState();

    _usuario = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  void _mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<bool> _confirmar({
    required String titulo,
    required String texto,
    required String botao,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(texto),
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
              child: Text(botao),
            ),
          ],
        );
      },
    );

    return confirmar == true;
  }

  Future<void> _promover(String nome) async {
    try {
      await _bubbleService.promoverModerador(
        bubbleId: widget.bubbleId,
        uid: widget.userId,
        promotorId: widget.meuUid,
      );

      _mensagem('$nome agora é moderador.');
    } catch (e) {
      _mensagem('Não foi possível tornar moderador.\n$e');
    }
  }

  Future<void> _tornarLider(String nome) async {
    final ok = await _confirmar(
      titulo: 'Tornar líder',
      texto: '$nome poderá gerenciar moderadores e membros desta Bolha. '
          'Você pode tirar a liderança depois.',
      botao: 'Tornar líder',
    );

    if (!ok) return;

    try {
      await _bubbleService.promoverLider(
        bubbleId: widget.bubbleId,
        uid: widget.userId,
        promotorId: widget.meuUid,
      );

      _mensagem('$nome agora é líder.');
    } catch (e) {
      _mensagem('Não foi possível tornar líder.\n$e');
    }
  }

  Future<void> _rebaixar(String nome) async {
    final ok = await _confirmar(
      titulo: 'Remover moderador',
      texto: '$nome voltará a ser um membro comum da Bolha.',
      botao: 'Remover',
    );

    if (!ok) return;

    try {
      await _bubbleService.rebaixarModerador(
        bubbleId: widget.bubbleId,
        uid: widget.userId,
      );

      _mensagem('$nome voltou a ser membro.');
    } catch (e) {
      _mensagem('Não foi possível remover o moderador.\n$e');
    }
  }

  Future<void> _rebaixarLider(String nome) async {
    final ok = await _confirmar(
      titulo: 'Remover liderança',
      texto: '$nome deixará de ser líder e voltará a ser moderador.',
      botao: 'Remover',
    );

    if (!ok) return;

    try {
      await _bubbleService.rebaixarLider(
        bubbleId: widget.bubbleId,
        uid: widget.userId,
      );

      _mensagem('$nome voltou a ser moderador.');
    } catch (e) {
      _mensagem('Não foi possível remover a liderança.\n$e');
    }
  }

  Future<void> _remover(String nome) async {
    final ok = await _confirmar(
      titulo: 'Remover da Bolha',
      texto: 'Tem certeza que deseja remover $nome desta Bolha?',
      botao: 'Remover',
    );

    if (!ok) return;

    try {
      await _bubbleService.removerMembro(
        bubbleId: widget.bubbleId,
        uid: widget.userId,
      );

      _mensagem('$nome foi removido da Bolha.');
    } catch (e) {
      _mensagem('Não foi possível remover o membro.\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _usuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: SketchAvatar(
              backgroundColor: BolhaColors.surfaceAlt,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: BolhaColors.primary,
              ),
            ),
            title: Text('Carregando...'),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const ListTile(
            leading: SketchAvatar(
              backgroundColor: BolhaColors.surfaceAlt,
              child: Icon(
                Icons.person_outline,
                color: BolhaColors.primary,
              ),
            ),
            title: Text('Usuário não encontrado'),
          );
        }

        final dados = snapshot.data!.data() ?? {};

        final nome = dados['nome']?.toString().isNotEmpty == true
            ? dados['nome'].toString()
            : 'Usuário do Bolha';

        final foto = dados['fotoPerfil']?.toString() ?? '';

        String? rotulo;

        if (widget.ehCriador) {
          rotulo = 'Criador da Bolha';
        } else if (widget.ehLider) {
          rotulo = 'Líder';
        } else if (widget.ehModerador) {
          rotulo = 'Moderador';
        }

        final temMenu = widget.podePromover ||
            widget.podeTornarLider ||
            widget.podeRebaixar ||
            widget.podeRebaixarLider ||
            widget.podeRemover;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: SketchAvatar(
            radius: 24,
            backgroundColor: BolhaColors.primary,
            backgroundImage:
                foto.isNotEmpty ? NetworkImage(foto) : null,
            child: foto.isEmpty
                ? Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
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
          subtitle: rotulo == null
              ? null
              : Text(
                  rotulo,
                  style: TextStyle(
                    color: widget.ehCriador
                        ? BolhaColors.textMuted
                        : BolhaColors.primary,
                    fontSize: 13,
                  ),
                ),
          trailing: temMenu
              ? PopupMenuButton<String>(
                  tooltip: 'Opções',
                  icon: const Icon(
                    Icons.more_vert,
                    color: BolhaColors.textMuted,
                  ),
                  onSelected: (acao) {
                    switch (acao) {
                      case 'promover':
                        _promover(nome);
                        break;
                      case 'lider':
                        _tornarLider(nome);
                        break;
                      case 'rebaixar':
                        _rebaixar(nome);
                        break;
                      case 'rebaixar_lider':
                        _rebaixarLider(nome);
                        break;
                      case 'remover':
                        _remover(nome);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.podeTornarLider)
                      const PopupMenuItem<String>(
                        value: 'lider',
                        child: Text('Tornar líder'),
                      ),
                    if (widget.podePromover)
                      const PopupMenuItem<String>(
                        value: 'promover',
                        child: Text('Tornar moderador'),
                      ),
                    if (widget.podeRebaixarLider)
                      const PopupMenuItem<String>(
                        value: 'rebaixar_lider',
                        child: Text('Remover liderança'),
                      ),
                    if (widget.podeRebaixar)
                      const PopupMenuItem<String>(
                        value: 'rebaixar',
                        child: Text('Remover moderador'),
                      ),
                    if (widget.podeRemover)
                      const PopupMenuItem<String>(
                        value: 'remover',
                        child: Text('Remover da Bolha'),
                      ),
                  ],
                )
              : const Icon(
                  Icons.chevron_right,
                  color: BolhaColors.textMuted,
                ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                  userId: widget.userId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
