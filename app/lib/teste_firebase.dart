import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class TesteFirebase extends StatelessWidget {
  TesteFirebase({super.key});

  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  Future<void> cadastrar() async {
    try {
      final resultado = await authService.cadastrar(
        'teste@bolha.com',
        '123456',
      );

      print('Usuário criado com sucesso!');
      print('UID: ${resultado.user?.uid}');
      print('Email: ${resultado.user?.email}');
    } on FirebaseAuthException catch (e) {
      print('Erro no cadastro');
      print('Código: ${e.code}');
      print('Mensagem: ${e.message}');
    } catch (e) {
      print('Erro inesperado: $e');
    }
  }

  Future<void> login() async {
    try {
      final resultado = await authService.login(
        'teste@bolha.com',
        '123456',
      );

      print('Login realizado com sucesso!');
      print('UID: ${resultado.user?.uid}');
      print('Email: ${resultado.user?.email}');
    } on FirebaseAuthException catch (e) {
      print('Erro no login');
      print('Código: ${e.code}');
      print('Mensagem: ${e.message}');
    } catch (e) {
      print('Erro inesperado: $e');
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();

      print('Logout realizado com sucesso!');
    } catch (e) {
      print('Erro no logout: $e');
    }
  }

  Future<void> salvarDados() async {
    try {
      final usuario = authService.usuarioAtual;

      if (usuario == null) {
        print('Nenhum usuário está logado.');
        return;
      }

      await firestoreService.criarUsuario(
        uid: usuario.uid,
        nome: 'Enzo',
        email: usuario.email ?? '',
        telefone: '11999999999',
      );

      print('Dados salvos no Firestore!');
      print('UID: ${usuario.uid}');
    } catch (e) {
      print('Erro ao salvar dados no Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: cadastrar,
              child: const Text('Cadastrar'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: salvarDados,
              child: const Text('Salvar dados no Firestore'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: logout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}