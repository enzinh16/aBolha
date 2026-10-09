import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'main_screen.dart';

import '../services/auth_service.dart';

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
      _mostrarMensagem('Preencha o e-mail e a senha.');
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await _authService.login(email, senha);

      if (!mounted) return;

      _mostrarMensagem('Login realizado com sucesso!');
      
      // Limpa toda a pilha de telas (onboarding, login...) para que a
      // MainScreen seja a única rota e nenhuma tela mostre seta de voltar.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensagem;

      switch (e.code) {
        case 'invalid-credential':
          mensagem = 'E-mail ou senha incorretos.';
          break;

        case 'invalid-email':
          mensagem = 'Digite um e-mail válido.';
          break;

        case 'user-disabled':
          mensagem = 'Esta conta foi desativada.';
          break;

        case 'user-not-found':
          mensagem = 'Usuário não encontrado.';
          break;

        case 'wrong-password':
          mensagem = 'Senha incorreta.';
          break;

        default:
          mensagem = 'Não foi possível realizar o login.';
      }

      _mostrarMensagem(mensagem);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 321,
            height: 329,
            child: Stack(
              children: [
                // Fundo do card
                Container(
                  width: 321,
                  height: 329,
                  decoration: ShapeDecoration(
                    color: BolhaColors.surface,
                    shape: SketchBorder(
                      side: BorderSide(
                        width: 1,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(52),
                    ),
                  ),
                ),

                // Título
                const Positioned(
                  left: 117,
                  top: 37,
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: BolhaColors.textPrimary,
                      fontSize: 32,
                      fontFamily: 'PatrickHand',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Campo de e-mail
                Positioned(
                  left: 46,
                  top: 115,
                  child: SizedBox(
                    width: 230,
                    height: 29,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        color: BolhaColors.textPrimary,
                        fontSize: 15,
                        fontFamily: 'PatrickHand',
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: 'email@example.com',
                        hintStyle: const TextStyle(
                          color: BolhaColors.textMuted,
                          fontSize: 15,
                          fontFamily: 'PatrickHand',
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: BolhaColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        border: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: const BorderSide(
                            color: BolhaColors.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Campo de senha
                Positioned(
                  left: 46,
                  top: 165,
                  child: SizedBox(
                    width: 230,
                    height: 29,
                    child: TextField(
                      controller: _senhaController,
                      obscureText: !_mostrarSenha,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _fazerLogin(),
                      style: const TextStyle(
                        color: BolhaColors.textPrimary,
                        fontSize: 15,
                        fontFamily: 'PatrickHand',
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: 'senha',
                        hintStyle: const TextStyle(
                          color: BolhaColors.textMuted,
                          fontSize: 15,
                          fontFamily: 'PatrickHand',
                          fontWeight: FontWeight.w800,
                        ),
                        filled: true,
                        fillColor: BolhaColors.surfaceAlt,
                        contentPadding: const EdgeInsets.only(
                          left: 12,
                          right: 8,
                          top: 0,
                          bottom: 0,
                        ),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: BolhaColors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                        ),
                        border: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: SketchInputBorder(
                          borderRadius: BorderRadius.circular(41),
                          borderSide: const BorderSide(
                            color: BolhaColors.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Botão Avançar
                Positioned(
                  left: 107,
                  top: 233,
                  child: SizedBox(
                    width: 108,
                    height: 29,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _fazerLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BolhaColors.primary,
                        disabledBackgroundColor: BolhaColors.primary,
                        padding: EdgeInsets.zero,
                        shape: SketchBorder(
                          borderRadius: BorderRadius.circular(41),
                        ),
                        elevation: 0,
                      ),
                      child: _carregando
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Avançar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'PatrickHand',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 255,
                child: SizedBox(
                  width: 230,
                  height: 48,
                child: TextButton( 
                  onPressed: () { 
                    Navigator.push( 
                      context, 
                      MaterialPageRoute( 
                        builder: (context) => const RegisterScreen(), 
                        ), 
                        ); 
                        }, 
                        child: const Text(
                          'Não possui uma conta? Crie uma já!',
                          style: TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                          decorationColor: BolhaColors.primary,
                          decorationThickness: 2.5,
                          ), 
                        ),
                    )
                  )
                ),
                Positioned(
                  left: 22,
                  top: 24,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}