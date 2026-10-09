import 'sketch_shapes.dart';
import 'package:flutter/material.dart';

/// Paleta Bolha v2 — tema escuro, roxo + rosa (sem azul, sem verde).
/// Ver docs/identidade-visual-v2.md
class BolhaColors {
  // Marca
  static const primary = Color(0xFF8A4DFF); // roxo bolha
  static const primaryDark = Color(0xFF5B2BC4); // roxo profundo
  static const secondary = Color(0xFFFF5CAA); // rosa choque
  static const orchid = Color(0xFFD94FD6); // magenta/orquídea
  static const lilac = Color(0xFFC9A8FF); // lilás claro
  static const softPink = Color(0xFFFFA3D1); // rosa suave

  // Superfícies (do mais fundo para o mais alto)
  static const background = Color(0xFF0E0A1A);
  static const navBackground = Color(0xFF0A0713);
  static const surface = Color(0xFF1A1330);
  static const surfaceAlt = Color(0xFF2A1F4D);

  // Linhas e texto
  static const outline = Color(0xFFFFFFFF); // contorno de "adesivo"
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFA99BC9);
  static const danger = Color(0xFFFF5C7A);

  // Nomes antigos mantidos para não quebrar código existente
  static const backgroundLight = background;
  static const backgroundDark = background;
}

class AppTheme {
  /// Fonte de títulos (BolhaDisplay: pesada e facetada, como as letras do
  /// wordmark) e de corpo (letra de mão).
  static const fontTitulo = 'BolhaDisplay';
  static const fontCorpo = 'PatrickHand';

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: BolhaColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: BolhaColors.primary,
      secondary: BolhaColors.secondary,
      surface: BolhaColors.surface,
      error: BolhaColors.danger,
      onSurface: BolhaColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontCorpo,
      scaffoldBackgroundColor: BolhaColors.background,
      colorScheme: scheme,

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: fontTitulo,
          color: BolhaColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontTitulo,
          color: BolhaColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontCorpo,
          fontSize: 16,
          color: BolhaColors.textPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: BolhaColors.background,
        foregroundColor: BolhaColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontTitulo,
          fontSize: 20,
          color: BolhaColors.textPrimary,
        ),
      ),

      dividerColor: BolhaColors.surfaceAlt,

      iconTheme: const IconThemeData(color: BolhaColors.textPrimary),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BolhaColors.secondary,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BolhaColors.secondary,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BolhaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontFamily: fontCorpo, fontSize: 18),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: SketchBorder(
            borderRadius: BorderRadius.circular(30),
            variant: 1,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BolhaColors.secondary,
          textStyle: const TextStyle(fontFamily: fontCorpo, fontSize: 16),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: BolhaColors.surfaceAlt,
        contentTextStyle: const TextStyle(
          fontFamily: fontCorpo,
          fontSize: 16,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: SketchBorder(
          borderRadius: BorderRadius.circular(18),
          variant: 3,
        ),
      ),
    );
  }

  /// Mantido por compatibilidade: o app agora é escuro por padrão.
  static ThemeData get light => dark;
}
