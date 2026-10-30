import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

class _Bolha {
  const _Bolha(
    this.x,
    this.raio,
    this.cor,
    this.variante,
    this.voltas,
    this.fase,
  );

  /// Posição horizontal (0 a 1 da largura da tela).
  final double x;
  final double raio;
  final Color cor;
  final int variante;

  /// Quantas subidas completas a bolha faz por ciclo. Sempre inteiro, para o
  /// loop não dar "pulo" quando recomeça.
  final int voltas;
  final double fase;
}

const List<_Bolha> _bolhas = [
  _Bolha(0.08, 38, BolhaColors.secondary, 1, 1, 0.00),
  _Bolha(0.20, 20, BolhaColors.lilac, 2, 2, 0.35),
  _Bolha(0.34, 52, BolhaColors.primary, 3, 1, 0.70),
  _Bolha(0.47, 15, BolhaColors.softPink, 4, 2, 0.15),
  _Bolha(0.58, 28, BolhaColors.orchid, 0, 1, 0.50),
  _Bolha(0.70, 44, BolhaColors.secondary, 2, 1, 0.85),
  _Bolha(0.82, 18, BolhaColors.lilac, 1, 2, 0.25),
  _Bolha(0.92, 34, BolhaColors.primary, 3, 1, 0.60),
];

/// Fundo com bolhas de sabão desenhadas à mão subindo devagar.
/// Fica atrás do conteúdo e não captura toques.
class FloatingBubbles extends StatefulWidget {
  const FloatingBubbles({super.key, this.opacidade = 1});

  final double opacidade;

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacidade,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BolhasPainter(_controller),
          ),
        ),
      ),
    );
  }
}

class _BolhasPainter extends CustomPainter {
  _BolhasPainter(this.animacao) : super(repaint: animacao);

  final Animation<double> animacao;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animacao.value;

    for (final b in _bolhas) {
      final progresso = (t * b.voltas + b.fase) % 1.0;
      final cy = size.height + b.raio * 2 - (size.height + b.raio * 4) * progresso;
      final cx = size.width * b.x +
          10 * math.sin(2 * math.pi * (t * b.voltas + b.fase * 2));

      final retangulo = Rect.fromCircle(center: Offset(cx, cy), radius: b.raio);
      final caminho = caminhoTremido(
        retangulo,
        radius: b.raio,
        variant: b.variante,
      );

      canvas.drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.fill
          ..color = b.cor.withValues(alpha: 0.14),
      );
      canvas.drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = b.raio > 30 ? 4.5 : 3
          ..strokeJoin = StrokeJoin.round
          ..color = b.cor,
      );

      // Reflexo de luz na bolha
      final brilho = Path()
        ..moveTo(cx - b.raio * 0.5, cy - b.raio * 0.15)
        ..quadraticBezierTo(
          cx - b.raio * 0.45,
          cy - b.raio * 0.55,
          cx - b.raio * 0.1,
          cy - b.raio * 0.62,
        );
      canvas.drawPath(
        brilho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BolhasPainter oldDelegate) => false;
}
