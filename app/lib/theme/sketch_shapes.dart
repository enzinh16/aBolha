import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Formas "desenhadas à mão" do Bolha.
///
/// Nada aqui é aleatório: cada variante abaixo é uma tabela de pequenos
/// desvios (em pixels) escolhida à mão, como se fossem 5 tentativas
/// diferentes de traçar o mesmo retângulo arredondado com o mouse. Por isso
/// o desenho é sempre igual a cada abertura do app (não "treme" nem muda
/// a cada rebuild), mas cada elemento pode usar uma variante diferente.
///
/// Ordem dos 20 valores de cada variante:
///  0  topo: início (y)        1  topo: curva do meio (y)   2  topo: fim (y)
///  3  canto sup. dir. (x)     4  canto sup. dir. (y)       5  fim do canto (x)
///  6  direita: curva (x)      7  direita: fim (x)
///  8  canto inf. dir. (x)     9  canto inf. dir. (y)      10  fim do canto (y)
/// 11  base: curva (y)        12  base: fim (y)
/// 13  canto inf. esq. (x)    14  canto inf. esq. (y)     15  fim do canto (x)
/// 16  esquerda: curva (x)    17  esquerda: fim (x)
/// 18  canto sup. esq. (x)    19  canto sup. esq. (y)
const List<List<double>> _tremida = [
  [1.2, -1.6, 0.8, 1.4, -1.0, 1.8, -1.2, 1.1, 1.5, 1.2, -0.9, 1.7, -1.1, -1.4, 0.9, -1.6, -1.8, 1.3, -0.8, -1.2],
  [-1.0, 1.4, -0.6, -1.5, 1.1, -1.2, 1.6, -0.9, -1.1, -1.4, 1.3, -1.6, 0.9, 1.2, -1.3, 1.1, 1.4, -1.0, 1.5, 0.8],
  [0.6, -1.1, 1.5, 1.0, 1.6, -0.8, 1.4, 1.3, -0.7, 1.5, -1.2, 1.0, -1.5, -1.0, -0.8, 1.4, -1.3, 0.9, 1.2, -1.5],
  [-1.4, 1.0, 1.1, -0.9, -1.3, 1.5, -1.0, -1.4, 1.2, -1.1, 0.8, -1.3, 1.4, 1.5, 1.0, -0.9, 1.1, -1.5, -1.0, 1.3],
  [1.5, 1.3, -1.2, 1.2, 0.9, -1.4, 1.1, 1.0, -1.4, 0.8, 1.5, 1.4, -0.9, -0.8, -1.5, 1.3, -1.6, 1.4, 0.9, 1.1],
];

/// Monta o caminho de um retângulo arredondado "traçado à mão".
Path caminhoTremido(Rect rect, {double radius = 18, int variant = 0}) {
  final w = rect.width;
  final h = rect.height;
  final r = math.min(radius, math.min(w, h) / 2);
  // Em elementos pequenos o tremido diminui, em grandes não passa de ~2.5px
  final k = (math.min(w, h) / 70).clamp(0.45, 1.6).toDouble();
  final o = _tremida[variant.abs() % _tremida.length];
  double d(int i) => o[i] * k;

  final l = rect.left;
  final t = rect.top;
  final rt = rect.right;
  final b = rect.bottom;
  final cx = (l + rt) / 2;
  final cy = (t + b) / 2;

  return Path()
    ..moveTo(l + r, t + d(0))
    ..quadraticBezierTo(cx, t + d(1), rt - r, t + d(2))
    ..quadraticBezierTo(rt + d(3), t + d(4), rt + d(5), t + r)
    ..quadraticBezierTo(rt + d(6), cy, rt + d(7), b - r)
    ..quadraticBezierTo(rt + d(8), b + d(9), rt - r, b + d(10))
    ..quadraticBezierTo(cx, b + d(11), l + r, b + d(12))
    ..quadraticBezierTo(l + d(13), b + d(14), l + d(15), b - r)
    ..quadraticBezierTo(l + d(16), cy, l + d(17), t + r)
    ..quadraticBezierTo(l + d(18), t + d(19), l + r, t + d(0))
    ..close();
}

double _raio(BorderRadiusGeometry radius) {
  return radius.resolve(TextDirection.ltr).topLeft.x;
}

/// Substituto direto do RoundedRectangleBorder: mesmo formato de uso
/// (borderRadius / side), mas com traço de mão e contorno branco grosso
/// (estilo adesivo) por padrão.
class SketchBorder extends OutlinedBorder {
  const SketchBorder({
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.side = const BorderSide(color: BolhaColors.outline, width: 2.5),
    this.variant = 0,
  });

  final BorderRadiusGeometry borderRadius;
  final int variant;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return caminhoTremido(
      rect.deflate(side.width),
      radius: _raio(borderRadius),
      variant: variant,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return caminhoTremido(rect, radius: _raio(borderRadius), variant: variant);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    // O traço é desenhado sobre a borda EXTERNA da forma (a mesma que recorta
    // o preenchimento) com o dobro da espessura, e recortado para dentro dela.
    // Assim a linha acompanha a borda por inteiro, sem deixar o preenchimento
    // "vazar" por fora nos cantos.
    final externo = caminhoTremido(
      rect,
      radius: _raio(borderRadius),
      variant: variant,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width * 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = side.color;
    canvas.save();
    canvas.clipPath(externo);
    canvas.drawPath(externo, paint);
    canvas.restore();
  }

  @override
  OutlinedBorder copyWith({BorderSide? side}) {
    return SketchBorder(
      borderRadius: borderRadius,
      side: side ?? this.side,
      variant: variant,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return SketchBorder(
      borderRadius: borderRadius * t,
      side: side.scale(t),
      variant: variant,
    );
  }
}

/// Substituto direto do OutlineInputBorder para os campos de texto.
class SketchInputBorder extends InputBorder {
  const SketchInputBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.variant = 2,
  });

  final BorderRadius borderRadius;
  final int variant;

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  InputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    int? variant,
  }) {
    return SketchInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      variant: variant ?? this.variant,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return SketchInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      variant: variant,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return caminhoTremido(
      rect.deflate(borderSide.width),
      radius: borderRadius.topLeft.x,
      variant: variant,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return caminhoTremido(rect, radius: borderRadius.topLeft.x, variant: variant);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderSide.width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = borderSide.color;

    // Mesmo princípio do SketchBorder: traço sobre a borda externa, recortado.
    final path = caminhoTremido(
      rect,
      radius: borderRadius.topLeft.x,
      variant: variant,
    );
    paint.strokeWidth = borderSide.width * 2;

    // Abre um "buraco" no traço onde fica o label flutuando
    if (gapStart != null && gapPercentage > 0) {
      final largura = gapExtent * gapPercentage + 8;
      final buraco = Rect.fromLTWH(
        rect.left + gapStart - 4,
        rect.top - borderSide.width * 2,
        largura,
        borderSide.width * 4,
      );
      canvas.save();
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          path,
          Path()..addRect(buraco),
        ),
      );
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
}

/// Substituto do CircleAvatar: bolha torta com contorno branco grosso.
/// Aceita os mesmos parâmetros usados no projeto (radius, backgroundColor,
/// backgroundImage, child).
class SketchAvatar extends StatelessWidget {
  const SketchAvatar({
    super.key,
    this.radius = 20,
    this.backgroundColor,
    this.backgroundImage,
    this.child,
    this.variant = 6,
    this.outlineColor = BolhaColors.outline,
  });

  final double radius;
  final Color? backgroundColor;
  final ImageProvider? backgroundImage;
  final Widget? child;
  final int variant;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final lado = radius * 2;
    final traco = (radius * 0.12).clamp(1.8, 4.5).toDouble();
    final forma = SketchBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: outlineColor, width: traco),
      variant: variant,
    );

    return SizedBox(
      width: lado,
      height: lado,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: forma,
          color: backgroundColor ?? BolhaColors.primary,
          image: backgroundImage == null
              ? null
              : DecorationImage(image: backgroundImage!, fit: BoxFit.cover),
        ),
        child: Center(child: child),
      ),
    );
  }
}
