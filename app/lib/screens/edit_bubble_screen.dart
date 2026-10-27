import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/bubble_model.dart';
import '../services/bubble_service.dart';
import '../services/imgbb_service.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

/// Edição de uma Bolha (nome, descrição e imagem).
/// Disponível para o criador e para os moderadores.
class EditBubbleScreen extends StatefulWidget {
  final BubbleModel bubble;

  const EditBubbleScreen({
    super.key,
    required this.bubble,
  });

  @override
  State<EditBubbleScreen> createState() =>
      _EditBubbleScreenState();
}

class _EditBubbleScreenState extends State<EditBubbleScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;

  final _bubbleService = BubbleService();
  final _imgBBService = ImgBBService();
  final ImagePicker _picker = ImagePicker();

  // Imagem nova escolhida agora (ainda não enviada)
  XFile? _novaImagem;
  Uint8List? _novaImagemBytes;

  // O usuário pediu para ficar sem imagem
  bool _removerFoto = false;

  bool _selecionandoImagem = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _nomeController =
        TextEditingController(text: widget.bubble.nome);
    _descricaoController =
        TextEditingController(text: widget.bubble.descricao);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  bool get _ocupado => _salvando || _selecionandoImagem;

  bool get _temImagem {
    if (_novaImagemBytes != null) return true;
    if (_removerFoto) return false;
    return widget.bubble.fotoUrl.isNotEmpty;
  }

  Future<void> _selecionarImagem(ImageSource origem) async {
    if (_ocupado) return;

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
        _novaImagem = imagem;
        _novaImagemBytes = bytes;
        _removerFoto = false;
      });
    } catch (e) {
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
    if (_ocupado) return;

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
    if (_salvando) return;

    setState(() {
      _novaImagem = null;
      _novaImagemBytes = null;
      _removerFoto = true;
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();

    if (nome.isEmpty) {
      _mostrarMensagem('Digite o nome da Bolha.');
      return;
    }

    final mudouNome = nome != widget.bubble.nome;
    final mudouDescricao = descricao != widget.bubble.descricao;
    final mudouImagem = _novaImagem != null ||
        (_removerFoto && widget.bubble.fotoUrl.isNotEmpty);

    // Nada mudou: só volta.
    if (!mudouNome && !mudouDescricao && !mudouImagem) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      var fotoUrl = widget.bubble.fotoUrl;

      final novaImagem = _novaImagem;

      if (novaImagem != null) {
        final resultado =
            await _imgBBService.enviarImagem(novaImagem);

        fotoUrl = resultado['url']!;
      } else if (_removerFoto) {
        fotoUrl = '';
      }

      await _bubbleService.atualizarBolha(
        bubbleId: widget.bubble.id,
        nome: nome,
        descricao: descricao,
        fotoUrl: fotoUrl,
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context, true);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Bolha atualizada.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível salvar as alterações.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
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
        title: const Text('Editar Bolha'),
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
              enabled: !_salvando,
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
              enabled: !_salvando,
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
                onPressed: _ocupado ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
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

  Widget _imagemQuebrada() {
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
  }

  Widget _previewImagem() {
    // Sem imagem: área clicável para escolher uma.
    if (!_temImagem) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _ocupado ? null : _mostrarOpcoesImagem,
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

    final bytes = _novaImagemBytes;

    final Widget imagem = bytes != null
        ? Image.memory(
            bytes,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagemQuebrada(),
          )
        : Image.network(
            widget.bubble.fotoUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagemQuebrada(),
          );

    // Com imagem: toque para trocar, X para remover.
    return Stack(
      children: [
        GestureDetector(
          onTap: _ocupado ? null : _mostrarOpcoesImagem,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: imagem,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: _salvando ? null : _removerImagem,
            tooltip: 'Remover imagem',
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
