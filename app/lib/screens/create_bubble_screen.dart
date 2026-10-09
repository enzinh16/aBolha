import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/bubble_service.dart';
import 'bubble_detail_screen.dart';

class CreateBubbleScreen extends StatefulWidget {
  const CreateBubbleScreen({super.key});

  @override
  State<CreateBubbleScreen> createState() =>
      _CreateBubbleScreenState();
}

class _CreateBubbleScreenState
    extends State<CreateBubbleScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _fotoUrlController = TextEditingController();

  final _bubbleService = BubbleService();

  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _criarBolha() async {
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final fotoUrl = _fotoUrlController.text.trim();

    if (nome.isEmpty) {
      _mostrarMensagem('Digite o nome da Bolha.');
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensagem(
        'Você precisa estar logado.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(usuario.uid)
          .get();

      final dadosUsuario = usuarioDoc.data();

      final nomeCriador =
          dadosUsuario?['nome'] ?? 'Usuário';

      final bubbleId = await _bubbleService.criarBolha(
        nome: nome,
        descricao: descricao,
        fotoUrl: fotoUrl,
        criadorId: usuario.uid,
        criadorNome: nomeCriador,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BubbleDetailScreen(
            bubbleId: bubbleId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível criar a Bolha.\n$e',
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
        title: const Text('Criar Bolha'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewImagem(),

            const SizedBox(height: 12),

            TextField(
              controller: _fotoUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL da foto',
                hintText: 'https://...',
                prefixIcon: const Icon(
                  Icons.link,
                ),
                border: SketchInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _nomeController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Nome da Bolha',
                hintText: 'Ex.: Programação',
                border: SketchInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _descricaoController,
              maxLength: 300,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descrição',
                hintText: 'Sobre o que é essa comunidade?',
                alignLabelWithHint: true,
                border: SketchInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _carregando
                    ? null
                    : _criarBolha,
                child: _carregando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Criar Bolha',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewImagem() {
    final url = _fotoUrlController.text.trim();

    if (url.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: BolhaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BolhaColors.secondary,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 42,
              color: BolhaColors.primary,
            ),
            SizedBox(height: 10),
            Text(
              'Adicione uma URL de imagem',
              style: TextStyle(
                color: BolhaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 180,
            color: BolhaColors.surface,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'Não foi possível carregar a imagem',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}