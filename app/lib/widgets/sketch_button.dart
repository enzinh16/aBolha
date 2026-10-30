import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

/// Botão largo "de adesivo": preenchimento chapado, contorno branco grosso e
/// texto na fonte de títulos. Usado nas telas de login e boas-vindas.
class SketchButton extends StatelessWidget {
  const SketchButton({
    super.key,
    required this.rotulo,
    required this.onPressed,
    this.carregando = false,
    this.cor = BolhaColors.secondary,
    this.corTexto = BolhaColors.background,
    this.variant = 3,
    this.altura = 54,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final bool carregando;
  final Color cor;
  final Color corTexto;
  final int variant;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final forma = SketchBorder(
      borderRadius: BorderRadius.circular(altura / 2),
      side: const BorderSide(color: BolhaColors.outline, width: 3),
      variant: variant,
    );

    final desabilitado = onPressed == null && !carregando;

    return SizedBox(
      height: altura,
      width: double.infinity,
      child: Material(
        color: desabilitado ? cor.withValues(alpha: 0.5) : cor,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: forma,
          onTap: carregando ? null : onPressed,
          child: Center(
            child: carregando
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: corTexto,
                    ),
                  )
                : Text(
                    rotulo,
                    style: TextStyle(
                      fontFamily: AppTheme.fontTitulo,
                      fontSize: 24,
                      color: corTexto,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
