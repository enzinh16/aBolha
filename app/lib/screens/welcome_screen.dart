import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import '../widgets/floating_bubbles.dart';
import '../widgets/sketch_button.dart';
import '../widgets/social_login_buttons.dart';
import 'register_screen.dart';

/// Tela de boas-vindas para quem é novo no aBolha.
///
/// Aparece quando a pessoa toca em "Cadastre-se" no login. Mostra o que dá
/// pra fazer no app, com bolhas flutuando atrás, e leva direto para criar a
/// conta (por e-mail ou pelos atalhos Google/Discord).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const List<(String, Color)> _bolhasDeExemplo = [
    ('# Anime & Mangá', BolhaColors.secondary),
    ('# Games', BolhaColors.lilac),
    ('# K-pop', BolhaColors.orchid),
    ('# Teclados Custom', BolhaColors.primary),
    ('# City Pop', BolhaColors.softPink),
    ('# Retro Games', BolhaColors.lilac),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBubbles()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Voltar',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/wordmark_abolha.png',
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Todas as suas bolhas em um só lugar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTitulo,
                          fontSize: 38,
                          height: 1.1,
                          color: BolhaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Games, animes, música, hobbies... Ache a galera que '
                        'curte o mesmo que você e crie e viva sua bolha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontCorpo,
                          fontSize: 20,
                          color: BolhaColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Exemplos de bolhas, como adesivos
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < _bolhasDeExemplo.length; i++)
                            _Adesivo(
                              texto: _bolhasDeExemplo[i].$1,
                              cor: _bolhasDeExemplo[i].$2,
                              variante: i,
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      const _CartaoDestaque(
                        icone: Icons.bubble_chart,
                        titulo: 'Crie sua bolha',
                        texto: 'Monte uma comunidade do seu jeito, com nome, '
                            'descrição e foto.',
                        cor: BolhaColors.primary,
                        rotacao: -0.015,
                        variante: 1,
                      ),
                      const SizedBox(height: 14),
                      const _CartaoDestaque(
                        icone: Icons.favorite,
                        titulo: 'Poste, curta, comente',
                        texto: 'Divida o que está rolando, responda a galera e '
                            'acompanhe tudo em tempo real.',
                        cor: BolhaColors.secondary,
                        rotacao: 0.015,
                        variante: 3,
                      ),
                      const SizedBox(height: 14),
                      const _CartaoDestaque(
                        icone: Icons.chat_bubble,
                        titulo: 'Converse e siga',
                        texto: 'Papo reto no chat privado e perfil com '
                            'seguidores pra fazer amizade de verdade.',
                        cor: BolhaColors.orchid,
                        rotacao: -0.01,
                        variante: 4,
                      ),
                      const SizedBox(height: 30),

                      SketchButton(
                        rotulo: 'Criar minha conta',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      const _DivisorOuCurto(),
                      const SizedBox(height: 22),
                      const SocialLoginButtons(),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tem uma bolha?',
                            style: TextStyle(
                              fontFamily: AppTheme.fontCorpo,
                              fontSize: 18,
                              color: BolhaColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                fontFamily: AppTheme.fontTitulo,
                                fontSize: 20,
                                color: BolhaColors.secondary,
                                decoration: TextDecoration.underline,
                                decorationColor: BolhaColors.secondary,
                                decorationThickness: 2.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de bolha (tipo "# Games") com contorno tremido.
class _Adesivo extends StatelessWidget {
  const _Adesivo({
    required this.texto,
    required this.cor,
    required this.variante,
  });

  final String texto;
  final Color cor;
  final int variante;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: cor.withValues(alpha: 0.18),
        shape: SketchBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cor, width: 2.4),
          variant: variante,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          texto,
          style: const TextStyle(
            fontFamily: AppTheme.fontCorpo,
            fontSize: 18,
            color: BolhaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Cartão de destaque levemente inclinado, como um adesivo colado na tela.
class _CartaoDestaque extends StatelessWidget {
  const _CartaoDestaque({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.cor,
    required this.rotacao,
    required this.variante,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final Color cor;
  final double rotacao;
  final int variante;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotacao,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: BolhaColors.surface,
          shape: SketchBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: BolhaColors.outline, width: 2.8),
            variant: variante,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SketchAvatar(
                radius: 28,
                backgroundColor: cor,
                variant: variante + 1,
                child: Icon(icone, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontTitulo,
                        fontSize: 24,
                        color: BolhaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texto,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontCorpo,
                        fontSize: 17,
                        color: BolhaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivisorOuCurto extends StatelessWidget {
  const _DivisorOuCurto();

  @override
  Widget build(BuildContext context) {
    const linha = Expanded(
      child: Divider(color: BolhaColors.surfaceAlt, thickness: 3, height: 3),
    );

    return const Row(
      children: [
        linha,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou entre rapidinho',
            style: TextStyle(
              fontFamily: AppTheme.fontCorpo,
              fontSize: 17,
              color: BolhaColors.textMuted,
            ),
          ),
        ),
        linha,
      ],
    );
  }
}
