import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import '../widgets/floating_bubbles.dart';
import '../widgets/sketch_button.dart';
import '../widgets/social_login_buttons.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

/// Tela inicial do app para quem ainda não está logado.
///
/// Segue o mesmo esquema das telas de login de jogos/redes: marca no topo,
/// "Bem-vindo de volta", e-mail e senha, "Entrar", atalhos Google/Discord e
/// o convite para quem é novo ("Cadastre-se").
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Ops, faltou preencher o e-mail e a senha.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await _authService.login(email, senha);

      if (!mounted) return;

      // Limpa a pilha de telas para a MainScreen ser a única rota.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          _mostrarMensagem('Ops, e-mail ou senha não bateram. Tenta de novo?');
          break;
        case 'invalid-email':
          _mostrarMensagem('Esse e-mail parece estranho. Dá uma conferida?');
          break;
        case 'user-disabled':
          _mostrarMensagem('Esta conta foi desativada.');
          break;
        case 'too-many-requests':
          _mostrarMensagem('Muitas tentativas seguidas. Espera um pouquinho e tenta de novo.');
          break;
        case 'network-request-failed':
          _mostrarMensagem('Sem internet? Confere a conexão e tenta de novo.');
          break;
        default:
          _mostrarMensagem('Ops, não rolou entrar agora. Tenta de novo?');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Ops, algo inesperado aconteceu. Tenta de novo?');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciASenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _mostrarMensagem(
        'Digite seu e-mail acima e toque em "Esqueceu a senha?" de novo.',
      );
      return;
    }

    try {
      await _authService.enviarRedefinicaoDeSenha(email);
      if (!mounted) return;
      _mostrarMensagem(
        'Pronto! Mandamos um link para $email. Olha a caixa de entrada (e o spam).',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'invalid-email') {
        _mostrarMensagem('Esse e-mail parece estranho. Dá uma conferida?');
      } else {
        _mostrarMensagem('Não deu pra mandar o link agora. Tenta de novo?');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não deu pra mandar o link agora. Tenta de novo?');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  InputDecoration _decoracao({
    required String dica,
    required IconData icone,
    Widget? sufixo,
    int variante = 2,
  }) {
    SketchInputBorder borda(Color cor, double largura) => SketchInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: cor, width: largura),
          variant: variante,
        );

    return InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(
        fontFamily: AppTheme.fontCorpo,
        fontSize: 18,
        color: BolhaColors.textMuted,
      ),
      prefixIcon: Icon(icone, color: BolhaColors.textMuted),
      suffixIcon: sufixo,
      filled: true,
      fillColor: BolhaColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: borda(BolhaColors.textMuted, 2.5),
      enabledBorder: borda(BolhaColors.textMuted, 2.5),
      focusedBorder: borda(BolhaColors.secondary, 3),
    );
  }

  static const TextStyle _estiloRotulo = TextStyle(
    fontFamily: AppTheme.fontCorpo,
    fontSize: 17,
    color: BolhaColors.textMuted,
  );

  static const TextStyle _estiloCampo = TextStyle(
    fontFamily: AppTheme.fontCorpo,
    fontSize: 19,
    color: BolhaColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bolhas bem de leve no fundo, só para dar vida
          const Positioned.fill(child: FloatingBubbles(opacidade: 0.35)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/wordmark_abolha.png',
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Bem-vindo de volta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTitulo,
                          fontSize: 34,
                          color: BolhaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sua bolha estava com saudade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontCorpo,
                          fontSize: 20,
                          color: BolhaColors.softPink,
                        ),
                      ),
                      const SizedBox(height: 26),

                      const Text('E-mail', style: _estiloRotulo),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: _estiloCampo,
                        decoration: _decoracao(
                          dica: 'Digite seu e-mail',
                          icone: Icons.alternate_email,
                          variante: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Senha', style: _estiloRotulo),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _senhaController,
                        obscureText: !_mostrarSenha,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _fazerLogin(),
                        autofillHints: const [AutofillHints.password],
                        style: _estiloCampo,
                        decoration: _decoracao(
                          dica: 'Digite sua senha',
                          icone: Icons.lock_outline,
                          variante: 4,
                          sufixo: IconButton(
                            icon: Icon(
                              _mostrarSenha
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: BolhaColors.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _mostrarSenha = !_mostrarSenha);
                            },
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _esqueciASenha,
                          child: const Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              fontFamily: AppTheme.fontCorpo,
                              fontSize: 17,
                              color: BolhaColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      SketchButton(
                        rotulo: 'Entrar',
                        carregando: _carregando,
                        onPressed: _fazerLogin,
                      ),

                      const SizedBox(height: 22),
                      const _DivisorOu(),
                      const SizedBox(height: 22),

                      const SocialLoginButtons(),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Não tem uma conta?',
                            style: TextStyle(
                              fontFamily: AppTheme.fontCorpo,
                              fontSize: 18,
                              color: BolhaColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WelcomeScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Cadastre-se',
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

/// Linha "—— OU ——" que separa o login por e-mail dos atalhos sociais.
class _DivisorOu extends StatelessWidget {
  const _DivisorOu();

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
            'OU',
            style: TextStyle(
              fontFamily: AppTheme.fontTitulo,
              fontSize: 18,
              color: BolhaColors.textMuted,
            ),
          ),
        ),
        linha,
      ],
    );
  }
}
