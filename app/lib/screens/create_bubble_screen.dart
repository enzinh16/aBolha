import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/bubble_service.dart';
import '../services/imgbb_service.dart';
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

  final _bubbleService = BubbleService();
  final _imgBBService = ImgBBService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imagemSelecionada;
  Uint8List? _imagemBytes;

  bool _selecionandoImagem = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem(ImageSource origem) async {
    if (_carregando || _selecionandoImagem) return;

    setState(() {
      _selecionandoImagem = true;
    });

    try {
      final imagem = await _picker.pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagemSelecionada = imagem;
        _imagemBytes = bytes;
      });
    } catch (e, stackTrace) {
      debugPrint('Erro ao selecionar imagem: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível selecionar a imagem: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _selecionandoImagem = false;
        });
      }
    }
  }

  Future<void> _mostrarOpcoesImagem() async {
    if (_carregando || _selecionandoImagem) return;

    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tirar uma foto'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (origem != null && mounted) {
      await _selecionarImagem(origem);
    }
  }

  void _removerImagem() {
    if (_carregando) return;

    setState(() {
      _imagemSelecionada = null;
      _imagemBytes = null;
    });
  }

  Future<void> _criarBolha() async {
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();

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

      // Primeiro envia a imagem escolhida (se houver) para o ImgBB
      // e usa a URL devolvida como foto da Bolha.
      String fotoUrl = '';

      final imagem = _imagemSelecionada;

      if (imagem != null) {
        final resultado =
            await _imgBBService.enviarImagem(imagem);

        fotoUrl = resultado['url']!;
      }

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
                onPressed: (_carregando || _selecionandoImagem)
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
    final bytes = _imagemBytes;

    // Nenhuma imagem escolhida ainda: área clicável para abrir o seletor.
    if (bytes == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: (_carregando || _selecionandoImagem)
            ? null
            : _mostrarOpcoesImagem,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: BolhaColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BolhaColors.secondary,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selecionandoImagem)
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 42,
                  color: BolhaColors.primary,
                ),
              const SizedBox(height: 10),
              const Text(
                'Toque para escolher uma imagem',
                style: TextStyle(
                  color: BolhaColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Imagem escolhida: mostra a prévia, toque para trocar e X para remover.
    return Stack(
      children: [
        GestureDetector(
          onTap: (_carregando || _selecionandoImagem)
              ? null
              : _mostrarOpcoesImagem,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              bytes,
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
                        'Não foi possível exibir a imagem',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: _carregando ? null : _removerImagem,
            tooltip: 'Remover imagem',
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}