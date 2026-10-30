import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/main_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

/// Atalhos "Continuar com Google" e "Continuar com Discord".
///
/// Funciona tanto para quem já tem conta (entra) quanto para quem é novo
/// (a conta e o perfil são criados no primeiro acesso). Precisa dos
/// provedores ativados no Firebase: ver docs/login-social.md.
class SocialLoginButtons extends StatefulWidget {
  const SocialLoginButtons({super.key});

  @override
  State<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

enum _Provedor { google, discord }

class _SocialLoginButtonsState extends State<SocialLoginButtons> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  _Provedor? _carregando;

  Future<void> _entrar(_Provedor provedor) async {
    if (_carregando != null) return;

    setState(() => _carregando = provedor);

    final nomeProvedor = provedor == _Provedor.google ? 'o Google' : 'o Discord';

    try {
      final credencial = provedor == _Provedor.google
          ? await _authService.entrarComGoogle()
          : await _authService.entrarComDiscord();

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('Não foi possível obter o usuário.');
      }

      final email = usuario.email ?? '';
      final nome = (usuario.displayName != null &&
              usuario.displayName!.trim().isNotEmpty)
          ? usuario.displayName!.trim()
          : (email.contains('@') ? email.split('@').first : 'Novo por aqui');

      // Primeira vez: cria o perfil no Firestore. Quem já tinha conta não é alterado.
      await _firestoreService.garantirUsuario(
        uid: usuario.uid,
        nome: nome,
        email: email,
        fotoPerfil: usuario.photoURL ?? '',
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Login social falhou: ${e.code} - ${e.message}');
      if (!mounted) return;

      switch (e.code) {
        // A pessoa fechou a janela: não precisa de aviso.
        case 'canceled':
        case 'cancelled-popup-request':
        case 'popup-closed-by-user':
        case 'web-context-canceled':
        case 'web-context-already-presented':
          break;

        case 'account-exists-with-different-credential':
          _mostrarMensagem(
            'Já existe uma conta com esse e-mail, criada de outro jeito. '
            'Entra com e-mail e senha que a gente resolve.',
          );
          break;

        case 'operation-not-allowed':
          _mostrarMensagem(
            'Entrar com $nomeProvedor ainda não foi ativado no Firebase.',
          );
          break;

        case 'network-request-failed':
          _mostrarMensagem('Sem internet? Confere a conexão e tenta de novo.');
          break;

        case 'user-disabled':
          _mostrarMensagem('Esta conta foi desativada.');
          break;

        default:
          _mostrarMensagem(
            'Ops, não rolou entrar com $nomeProvedor. Tenta de novo?',
          );
      }
    } catch (e) {
      debugPrint('Login social falhou: $e');
      if (!mounted) return;
      _mostrarMensagem(
        'Ops, não rolou entrar com $nomeProvedor. Tenta de novo?',
      );
    } finally {
      if (mounted) setState(() => _carregando = null);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BotaoSocial(
          rotulo: 'Continuar com Google',
          logo: _LogoSocial.google,
          variant: 2,
          carregando: _carregando == _Provedor.google,
          onPressed: _carregando == null
              ? () => _entrar(_Provedor.google)
              : null,
        ),
        const SizedBox(height: 14),
        _BotaoSocial(
          rotulo: 'Continuar com Discord',
          logo: _LogoSocial.discord,
          variant: 4,
          carregando: _carregando == _Provedor.discord,
          onPressed: _carregando == null
              ? () => _entrar(_Provedor.discord)
              : null,
        ),
      ],
    );
  }
}

class _BotaoSocial extends StatelessWidget {
  const _BotaoSocial({
    required this.rotulo,
    required this.logo,
    required this.onPressed,
    required this.carregando,
    required this.variant,
  });

  final String rotulo;
  final _LogoSocial logo;
  final VoidCallback? onPressed;
  final bool carregando;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final forma = SketchBorder(
      borderRadius: BorderRadius.circular(27),
      side: const BorderSide(color: BolhaColors.outline, width: 2.5),
      variant: variant,
    );

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: BolhaColors.surface,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: forma,
          onTap: onPressed,
          child: Center(
            child: carregando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: BolhaColors.secondary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(24, 24),
                        painter: _LogoPainter(logo),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        rotulo,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontCorpo,
                          fontSize: 19,
                          color: BolhaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum _LogoSocial { google, discord }

/// Logos simplificados desenhados em código (24x24), para não depender de
/// arquivos de imagem nem de pacotes extras.
class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.logo);

  final _LogoSocial logo;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / 24;
    canvas.save();
    canvas.scale(escala);

    if (logo == _LogoSocial.google) {
      _pintarGoogle(canvas);
    } else {
      _pintarDiscord(canvas);
    }

    canvas.restore();
  }

  void _pintarGoogle(Canvas canvas) {
    const centro = Offset(12, 12);
    const raio = 8.2;
    final retangulo = Rect.fromCircle(center: centro, radius: raio);

    double rad(double graus) => graus * math.pi / 180;

    Paint arco(Color cor) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.butt
      ..color = cor;

    // Ângulos em graus, 0 = direita, sentido horário.
    canvas.drawArc(retangulo, rad(-165), rad(120), false, arco(const Color(0xFFEA4335)));
    canvas.drawArc(retangulo, rad(135), rad(60), false, arco(const Color(0xFFFBBC05)));
    canvas.drawArc(retangulo, rad(45), rad(90), false, arco(const Color(0xFF34A853)));
    canvas.drawArc(retangulo, rad(0), rad(45), false, arco(const Color(0xFF4285F4)));

    // Barra do "G"
    canvas.drawLine(
      const Offset(12.5, 12),
      const Offset(20.2, 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0xFF4285F4),
    );
  }

  void _pintarDiscord(Canvas canvas) {
    final corpo = Paint()..color = const Color(0xFFFFFFFF);
    final olho = Paint()..color = BolhaColors.background;

    // Cabeça arredondada
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2.5, 5.5, 19, 12.5),
        const Radius.circular(6.5),
      ),
      corpo,
    );

    // Pontinhas de baixo
    canvas.drawPath(
      Path()
        ..moveTo(5, 16)
        ..lineTo(3, 20)
        ..lineTo(8.5, 18)
        ..close(),
      corpo,
    );
    canvas.drawPath(
      Path()
        ..moveTo(19, 16)
        ..lineTo(21, 20)
        ..lineTo(15.5, 18)
        ..close(),
      corpo,
    );

    // Olhos
    canvas.drawOval(const Rect.fromLTWH(6.6, 9.4, 3.4, 4.4), olho);
    canvas.drawOval(const Rect.fromLTWH(14, 9.4, 3.4, 4.4), olho);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.logo != logo;
}
