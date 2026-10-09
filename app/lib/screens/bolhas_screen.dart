import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/bubble_model.dart';
import '../services/bubble_service.dart';
import '../theme/sketch_shapes.dart';
import '../widgets/bubble_card.dart';
import '../widgets/sketch_circle_button.dart';
import 'bubble_detail_screen.dart';
import 'create_bubble_screen.dart';

class BubblesScreen extends StatefulWidget {
  const BubblesScreen({super.key});

  @override
  State<BubblesScreen> createState() => _BubblesScreenState();
}

class _BubblesScreenState extends State<BubblesScreen> {
  final BubbleService _bubbleService = BubbleService();

  // 0 = Minhas Bolhas (padrão), 1 = Todas
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Bolhas'),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bubbleService.ouvirBolhas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar as Bolhas:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bolhas = snapshot.data?.docs
                  .map(
                    (doc) => BubbleModel.fromFirestore(doc),
                  )
                  .toList() ??
              [];

          return Column(
            children: [
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: _seletorDeAbas(),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _abaSelecionada == 0
                    ? _minhasBolhas(bolhas)
                    : _todasBolhas(bolhas),
              ),
            ],
          );
        },
      ),

      floatingActionButton: SketchCircleButton(
        icon: Icons.add,
        tooltip: 'Criar Bolha',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateBubbleScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _todasBolhas(List<BubbleModel> bolhas) {
    if (bolhas.isEmpty) {
      return _estadoVazio(
        'Nenhuma Bolha encontrada',
        'Crie a primeira comunidade.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      itemCount: bolhas.length,
      itemBuilder: (context, index) {
        final bubble = bolhas[index];

        return BubbleCard(
          bubble: bubble,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BubbleDetailScreen(
                  bubbleId: bubble.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _minhasBolhas(List<BubbleModel> bolhas) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _estadoVazio(
        'Usuário não autenticado',
        'Faça login para visualizar suas Bolhas.',
      );
    }

    return FutureBuilder<List<BubbleModel>>(
      future: _buscarMinhasBolhas(
        bolhas,
        uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final minhasBolhas = snapshot.data ?? [];

        if (minhasBolhas.isEmpty) {
          return _estadoVazio(
            'Você ainda não participa de nenhuma Bolha',
            'Explore as Bolhas e entre em uma comunidade.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          itemCount: minhasBolhas.length,
          itemBuilder: (context, index) {
            final bubble = minhasBolhas[index];

            return BubbleCard(
              bubble: bubble,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BubbleDetailScreen(
                      bubbleId: bubble.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<BubbleModel>> _buscarMinhasBolhas(
    List<BubbleModel> bolhas,
    String uid,
  ) async {
    final resultado = <BubbleModel>[];

    for (final bubble in bolhas) {
      final membro = await FirebaseFirestore.instance
          .collection('bubbles')
          .doc(bubble.id)
          .collection('members')
          .doc(uid)
          .get();

      if (membro.exists) {
        resultado.add(bubble);
      }
    }

    return resultado;
  }

  /// Seletor "Minhas Bolhas | Todas". A aba ativa fica destacada por uma
  /// pílula rabiscada (contorno branco) que desliza até a opção escolhida.
  Widget _seletorDeAbas() {
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
            alignment: _abaSelecionada == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
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
              Expanded(
                child: _botaoAba(texto: 'Minhas Bolhas', index: 0),
              ),
              Expanded(
                child: _botaoAba(texto: 'Todas', index: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoAba({
    required String texto,
    required int index,
  }) {
    final selecionada = _abaSelecionada == index;

    return Semantics(
      button: true,
      selected: selecionada,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_abaSelecionada == index) return;
          setState(() {
            _abaSelecionada = index;
          });
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontFamily: AppTheme.fontCorpo,
              fontSize: 16,
              color: selecionada
                  ? BolhaColors.textPrimary
                  : BolhaColors.textMuted,
            ),
            child: Text(texto),
          ),
        ),
      ),
    );
  }

  Widget _estadoVazio(
    String titulo,
    String descricao,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: BolhaColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BolhaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}