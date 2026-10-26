
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/imgbb_service.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String bubbleId;
  final String bubbleNome;

  const CreatePostScreen({
    super.key,
    required this.bubbleId,
    required this.bubbleNome,
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textoController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final ImgBBService _imgBBService = ImgBBService();
  final PostService _postService = PostService();

  XFile? _imagemSelecionada;

  bool _selecionandoImagem = false;
  bool _publicando = false;

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem(ImageSource origem) async {
    if (_publicando || _selecionandoImagem) return;

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

      if (!mounted) return;

      if (imagem != null) {
        setState(() {
          _imagemSelecionada = imagem;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Erro ao selecionar imagem: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível selecionar a imagem: $e'),
        ),
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
    if (_publicando || _selecionandoImagem) return;

    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
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
    if (_publicando) return;

    setState(() {
      _imagemSelecionada = null;
    });
  }

  Future<void> _publicar() async {
    final texto = _textoController.text.trim();
    final imagem = _imagemSelecionada;
    final usuario = FirebaseAuth.instance.currentUser;

    if (texto.isEmpty && imagem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva algo ou selecione uma imagem.'),
        ),
      );
      return;
    }

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para publicar.'),
        ),
      );
      return;
    }

    setState(() {
      _publicando = true;
    });

    try {
      String nomeUsuario =
          usuario.displayName ?? 'Usuário';

      final usuarioDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(usuario.uid)
          .get();

      final dadosUsuario = usuarioDoc.data();
      final nomeSalvo = dadosUsuario?['nome'];

      if (nomeSalvo is String && nomeSalvo.trim().isNotEmpty) {
        nomeUsuario = nomeSalvo.trim();
      }

      String imagemUrl = '';

      // Primeiro, envia a imagem para o ImgBB, se houver uma.
      if (imagem != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enviando imagem...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final resultado =
            await _imgBBService.enviarImagem(imagem);

        imagemUrl = resultado['url']!;

        debugPrint('Imagem enviada para o ImgBB.');
        debugPrint('URL da imagem: $imagemUrl');
      }

      // Depois, salva a postagem no Firestore usando o serviço existente.
      await _postService.criarPost(
        bubbleId: widget.bubbleId,
        autorId: usuario.uid,
        autorNome: nomeUsuario,
        texto: texto,
        imagemUrl: imagemUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postagem publicada com sucesso!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Erro ao publicar postagem: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível publicar a postagem: $e',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _publicando = false;
        });
      }
    }
  }

  Widget _construirPreviaImagem() {
    final imagem = _imagemSelecionada;

    if (imagem == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Uint8List>(
      future: imagem.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: const Text(
              'Não foi possível exibir a imagem selecionada.',
            ),
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                snapshot.data!,
                width: double.infinity,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: _publicando ? null : _removerImagem,
                tooltip: 'Remover imagem',
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _publicando || _selecionandoImagem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar postagem'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.bubbleNome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _textoController,
                enabled: !_publicando,
                minLines: 5,
                maxLines: 10,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'O que você gostaria de compartilhar?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              if (_imagemSelecionada != null) ...[
                _construirPreviaImagem(),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: ocupado ? null : _mostrarOpcoesImagem,
                icon: _selecionandoImagem
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.image_outlined),
                label: Text(
                  _imagemSelecionada == null
                      ? 'Adicionar imagem'
                      : 'Trocar imagem',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: ocupado ? null : _publicar,
                icon: _publicando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _publicando ? 'Publicando...' : 'Publicar',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
