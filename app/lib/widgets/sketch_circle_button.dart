import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

/// Botão redondo "rabiscado": bolha rosa com contorno branco grosso e um
/// ícone no centro. Usado no botão de criar Bolha e no de enviar mensagem.
class SketchCircleButton extends StatelessWidget {
  const SketchCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.color = BolhaColors.secondary,
    this.variant = 6,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final int variant;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final forma = SketchBorder(
      borderRadius: BorderRadius.circular(size / 2),
      side: BorderSide(
        color: BolhaColors.outline,
        width: (size * 0.05).clamp(2.0, 3.0).toDouble(),
      ),
      variant: variant,
    );

    final botao = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: forma,
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return botao;
    return Tooltip(message: tooltip!, child: botao);
  }
}
