import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final telefone = _telefoneController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        telefone.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarMensagem('As senhas não são iguais.');
      return;
    }

    if (senha.length < 6) {
      _mostrarMensagem('A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final resultado = await _authService.cadastrar(
        email,
        senha,
      );

      final usuario = resultado.user;

      if (usuario == null) {
        throw Exception('Não foi possível obter o usuário criado.');
      }

      await _firestoreService.criarUsuario(
        uid: usuario.uid,
        nome: nome,
        email: email,
        telefone: telefone,
      );

      if (!mounted) return;

      _mostrarMensagem('Conta criada com sucesso!');

      // O Firebase já deixa o usuário logado após criar a conta; limpa a
      // pilha e vai direto para a MainScreen (sem seta de voltar).
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
        case 'email-already-in-use':
          mensagem = 'Este e-mail já está cadastrado.';
          break;

        case 'invalid-email':
          mensagem = 'Digite um e-mail válido.';
          break;

        case 'weak-password':
          mensagem = 'A senha é muito fraca.';
          break;

        default:
          mensagem = 'Não foi possível criar a conta.';
      }

      _mostrarMensagem(mensagem);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'A conta foi criada, mas não foi possível salvar os dados.',
      );
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
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                border: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                enabledBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                focusedBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.secondary, width: 2.5),
                ),
                labelText: 'Nome',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                enabledBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                focusedBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.secondary, width: 2.5),
                ),
                labelText: 'E-mail',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                enabledBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                focusedBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.secondary, width: 2.5),
                ),
                labelText: 'Telefone',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _senhaController,
              obscureText: !_mostrarSenha,
              decoration: InputDecoration(
                border: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                enabledBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                focusedBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.secondary, width: 2.5),
                ),
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarSenha
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarSenha = !_mostrarSenha;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _confirmarSenhaController,
              obscureText: !_mostrarConfirmarSenha,
              decoration: InputDecoration(
                border: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                enabledBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.textMuted, width: 2),
                ),
                focusedBorder: SketchInputBorder(
                  borderSide: BorderSide(color: BolhaColors.secondary, width: 2.5),
                ),
                labelText: 'Confirmar senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarConfirmarSenha
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarConfirmarSenha =
                          !_mostrarConfirmarSenha;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _carregando ? null : _criarConta,
                child: _carregando
                    ? const CircularProgressIndicator()
                    : const Text('Criar conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}