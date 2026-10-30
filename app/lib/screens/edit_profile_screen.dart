import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';
import '../services/imgbb_service.dart';
import '../screens/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final ImgBBService _imgBBService = ImgBBService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();
  final TextEditingController _bannerController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _deslogando = false;
  bool _salvandoDados = false;
  bool _carregandoDados = true;
  bool _enviandoFoto = false;
  bool _enviandoBanner = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _bioController.dispose();
    _fotoController.dispose();
    _bannerController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) {
      if (mounted) setState(() => _carregandoDados = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(usuarioAtual.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final dados = doc.data()!;
        _nomeController.text = dados['nome']?.toString() ?? '';
        _telefoneController.text = dados['telefone']?.toString() ?? '';
        _bioController.text = dados['bio']?.toString() ?? '';
        _fotoController.text = dados['fotoPerfil']?.toString() ?? '';
        _bannerController.text = dados['banner']?.toString() ?? '';
      }

      _emailController.text = usuarioAtual.email ?? '';
    } catch (e) {
      _nomeController.text = usuarioAtual.displayName ?? '';
      _emailController.text = usuarioAtual.email ?? '';
      _mostrarMensagem('Não foi possível carregar todos os dados do perfil.');
      debugPrint('Erro ao carregar dados do perfil: $e');
    } finally {
      if (mounted) setState(() => _carregandoDados = false);
    }
  }

  Future<void> _selecionarEEnviarImagem({required bool ehBanner}) async {
    if (ehBanner) {
      if (_enviandoBanner) return;
    } else if (_enviandoFoto) {
      return;
    }

    final XFile? imagem;
    try {
      imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      _mostrarMensagem('Não foi possível abrir a galeria de imagens.');
      debugPrint('Erro ao selecionar imagem: $e');
      return;
    }

    if (imagem == null || !mounted) return;

    setState(() {
      if (ehBanner) {
        _enviandoBanner = true;
      } else {
        _enviandoFoto = true;
      }
    });

    try {
      final resultado = await _imgBBService.enviarImagem(imagem);
      final url = resultado['url'];

      if (url == null || url.trim().isEmpty) {
        throw Exception('O serviço de imagens não retornou uma URL válida.');
      }

      if (!mounted) return;

      setState(() {
        if (ehBanner) {
          _bannerController.text = url;
        } else {
          _fotoController.text = url;
        }
      });

      _mostrarMensagem(
        ehBanner
            ? 'Banner enviado! Toque no ✓ para salvar as alterações do perfil.'
            : 'Foto enviada! Toque no ✓ para salvar as alterações do perfil.',
      );
    } catch (e) {
      debugPrint('Erro ao enviar imagem para o ImgBB: $e');
      _mostrarMensagem('Não foi possível enviar a imagem. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          if (ehBanner) {
            _enviandoBanner = false;
          } else {
            _enviandoFoto = false;
          }
        });
      }
    }
  }

  Future<void> _salvarPerfil() async {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return;

    if (_enviandoFoto || _enviandoBanner) {
      _mostrarMensagem('Aguarde o envio das imagens terminar.');
      return;
    }

    setState(() => _salvandoDados = true);

    try {
      await _firestore.collection('users').doc(usuarioAtual.uid).set({
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'fotoPerfil': _fotoController.text.trim(),
        'banner': _bannerController.text.trim(),
      }, SetOptions(merge: true));

      final novoEmail = _emailController.text.trim();
      var mensagem = 'Modificações salvas com sucesso!';

      if (novoEmail.isNotEmpty && novoEmail != usuarioAtual.email) {
        await usuarioAtual.verifyBeforeUpdateEmail(novoEmail);
        mensagem = 'Perfil atualizado! Verifique seu novo e-mail para validar a alteração.';
      }

      if (!mounted) return;
      _mostrarMensagem(mensagem);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erro ao salvar perfil: $e');
      _mostrarMensagem('Erro ao salvar os dados. Verifique sua conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _salvandoDados = false);
    }
  }

  Future<void> _alterarSenha() async {
    final usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return;

    if (_senhaController.text.isEmpty || _senhaController.text.length < 6) {
      _mostrarMensagem('A senha precisa ter no mínimo 6 caracteres.');
      return;
    }

    try {
      await usuarioAtual.updatePassword(_senhaController.text);
      _senhaController.clear();
      _mostrarMensagem('Senha modificada com sucesso!');
    } catch (e) {
      debugPrint('Erro ao alterar senha: $e');
      _mostrarMensagem('Não foi possível alterar a senha. Faça login novamente e tente outra vez.');
    }
  }

  Future<void> _fazerLogout() async {
    setState(() => _deslogando = true);

    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao tentar desconectar da conta.');
    } finally {
      if (mounted) setState(() => _deslogando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Widget _construirPreviewImagem({required bool ehBanner}) {
    final url = ehBanner ? _bannerController.text.trim() : _fotoController.text.trim();
    final enviando = ehBanner ? _enviandoBanner : _enviandoFoto;

    if (ehBanner) {
      return Container(
        height: 135,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: BolhaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BolhaColors.textMuted.withOpacity(0.2)),
        ),
        child: enviando
            ? const Center(child: CircularProgressIndicator(color: BolhaColors.primary))
            : url.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.panorama_outlined, size: 34, color: BolhaColors.textMuted),
                        SizedBox(height: 6),
                        Text('Nenhum banner selecionado'),
                      ],
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Não foi possível carregar o banner'),
                    ),
                  ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: BolhaColors.surfaceAlt,
            backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
            child: url.isEmpty
                ? const Icon(Icons.person_outline, size: 48, color: BolhaColors.textMuted)
                : null,
            onBackgroundImageError: url.isNotEmpty ? (_, __) {} : null,
          ),
          if (enviando)
            const CircleAvatar(
              radius: 52,
              backgroundColor: Color(0x99000000),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _construirSecaoImagem({required bool ehBanner}) {
    final titulo = ehBanner ? 'Banner do perfil' : 'Foto de perfil';
    final descricao = ehBanner
        ? 'Escolha uma imagem horizontal para o topo do seu perfil.'
        : 'Escolha a imagem que aparecerá ao lado do seu nome.';
    final enviando = ehBanner ? _enviandoBanner : _enviandoFoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontFamily: 'PatrickHand',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: BolhaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          descricao,
          style: const TextStyle(fontSize: 12, color: BolhaColors.textMuted),
        ),
        const SizedBox(height: 12),
        _construirPreviewImagem(ehBanner: ehBanner),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: (enviando || _salvandoDados)
              ? null
              : () => _selecionarEEnviarImagem(ehBanner: ehBanner),
          icon: enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(
            enviando ? 'Enviando imagem...' : 'Escolher imagem na galeria',
            style: const TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: BolhaColors.primary,
            side: const BorderSide(color: BolhaColors.primary),
            shape: SketchBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _construirCampoTexto({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'PatrickHand', color: BolhaColors.textMuted),
        filled: true,
        fillColor: BolhaColors.surfaceAlt.withOpacity(0.4),
        border: SketchInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: SketchInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BolhaColors.primary, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Não logado',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'PatrickHand',
              fontWeight: FontWeight.w600,
              color: BolhaColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: BolhaColors.background,
        elevation: 0,
        foregroundColor: BolhaColors.textPrimary,
        actions: [
          if (!_carregandoDados)
            IconButton(
              tooltip: 'Salvar alterações',
              icon: _salvandoDados
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, color: BolhaColors.lilac),
              onPressed: (_salvandoDados || _enviandoFoto || _enviandoBanner)
                  ? null
                  : _salvarPerfil,
            ),
        ],
      ),
      backgroundColor: BolhaColors.background,
      body: SafeArea(
        child: _carregandoDados
            ? const Center(child: CircularProgressIndicator(color: BolhaColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirSecaoImagem(ehBanner: false),
                    const SizedBox(height: 28),
                    _construirSecaoImagem(ehBanner: true),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    _construirCampoTexto(
                      label: 'Nome de Usuário',
                      controller: _nomeController,
                    ),
                    const SizedBox(height: 16),
                    _construirCampoTexto(
                      label: 'E-mail da Conta',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _construirCampoTexto(
                      label: 'Telefone',
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _construirCampoTexto(
                      label: 'Biografia (Bio)',
                      controller: _bioController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Segurança',
                      style: TextStyle(
                        fontFamily: 'PatrickHand',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: BolhaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              labelStyle: const TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                              border: SketchInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _alterarSenha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BolhaColors.primary,
                            foregroundColor: Colors.white,
                            shape: SketchBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Alterar',
                            style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _deslogando ? null : _fazerLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BolhaColors.danger,
                          foregroundColor: Colors.white,
                          shape: SketchBorder(borderRadius: BorderRadius.circular(41)),
                        ),
                        icon: _deslogando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.logout, size: 18),
                        label: Text(
                          _deslogando ? 'Desconectando...' : 'Desconectar da Conta',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'PatrickHand',
                            fontWeight: FontWeight.bold,
                          ),
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
