// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Importação essencial para ler o banco de dados

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   String _nomeUsuario = 'Carregando...';
//   String _emailUsuario = 'Carregando...';
//   bool _deslogando = false;
//   bool _carregandoDados = true;

//   @override
//   void initState() {
//     super.initState();
//     _carregarDadosDiretoDoFirestore();
//   }

//   // Busca as informações direto na coleção 'users' sem depender de arquivos de serviço externos
//   Future<void> _carregarDadosDiretoDoFirestore() async {
//     final User? usuarioAtual = _auth.currentUser;
    
//     if (usuarioAtual != null) {
//       try {
//         // Faz a requisição direta ao Firestore usando a instância global
//         DocumentSnapshot doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(usuarioAtual.uid)
//             .get();

//         if (doc.exists && doc.data() != null) {
//           final dados = doc.data() as Map<String, dynamic>;
          
//           if (mounted) {
//             setState(() {
//               _nomeUsuario = dados['nome'] ?? 'Usuário do Bolha';
//               _emailUsuario = dados['email'] ?? usuarioAtual.email ?? 'E-mail não disponível';
//               _carregandoDados = false;
//             });
//           }
//         } else {
//           // Caso o documento do usuário não exista no Firestore, usa dados do Auth como plano B
//           if (mounted) {
//             setState(() {
//               _nomeUsuario = usuarioAtual.displayName ?? 'Usuário do Bolha';
//               _emailUsuario = usuarioAtual.email ?? 'E-mail não disponível';
//               _carregandoDados = false;
//             });
//           }
//         }
//       } catch (e) {
//         // Em caso de erro na rede ou permissão, preenche com um fallback para o app não quebrar
//         if (mounted) {
//           setState(() {
//             _nomeUsuario = usuarioAtual.displayName ?? 'Usuário do Bolha';
//             _emailUsuario = usuarioAtual.email ?? 'E-mail não disponível';
//             _carregandoDados = false;
//           });
//         }
//       }
//     }
//   }

//   // Função para realizar o logout
//   Future<void> _fazerLogout() async {
//     setState(() {
//       _deslogando = true;
//     });

//     try {
//       await _auth.signOut();
      
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Sessão encerrada com sucesso!')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Erro ao tentar deslogar.')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _deslogando = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Minha Conta',
//           style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: BolhaColors.background,
//         elevation: 0,
//         foregroundColor: BolhaColors.textPrimary,
//       ),
//       backgroundColor: BolhaColors.background,
//       body: SafeArea(
//         child: Center(
//           child: _carregandoDados
//               ? const CircularProgressIndicator(
//                   color: BolhaColors.primary,
//                 )
//               : Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Avatar circular com a primeira letra maiúscula do nome carregado
//                       SketchAvatar(
//                         radius: 50,
//                         backgroundColor: BolhaColors.surfaceAlt,
//                         child: Text(
//                           _nomeUsuario.isNotEmpty ? _nomeUsuario[0].toUpperCase() : 'U',
//                           style: const TextStyle(
//                             fontSize: 40,
//                             fontWeight: FontWeight.w800,
//                             color: BolhaColors.primary,
//                             fontFamily: 'PatrickHand',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Nome de Usuário retornado do banco
//                       Text(
//                         _nomeUsuario,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.w800,
//                           fontFamily: 'PatrickHand',
//                           color: BolhaColors.textPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 8),

//                       // E-mail do usuário retornado do banco
//                       Text(
//                         _emailUsuario,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'PatrickHand',
//                           color: BolhaColors.textMuted,
//                         ),
//                       ),
//                       const SizedBox(height: 48),

//                       // Botão de Deslogar / Sair
//                       SizedBox(
//                         width: 230,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: _deslogando ? null : _fazerLogout,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: BolhaColors.danger,
//                             foregroundColor: Colors.white,
//                             shape: SketchBorder(
//                               borderRadius: BorderRadius.circular(41),
//                             ),
//                           ),
//                           icon: _deslogando 
//                               ? const SizedBox.shrink()
//                               : const Icon(Icons.logout, size: 18),
//                           label: _deslogando
//                               ? const SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : const Text(
//                                   'Sair da Conta',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontFamily: 'PatrickHand',
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   String _nomeUsuario = 'Carregando...';
//   String _emailUsuario = 'Carregando...';
//   bool _deslogando = false;
//   bool _carregandoDados = true;

//   @override
//   void initState() {
//     super.initState();
//     _carregarDadosDiretoDoFirestore();
//   }

//   Future<void> _carregarDadosDiretoDoFirestore() async {
//     final User? usuarioAtual = _auth.currentUser;
    
//     // MODIFICAÇÃO: Se não houver usuário no Auth, interrompe a busca e desliga o loading
//     if (usuarioAtual == null) {
//       if (mounted) {
//         setState(() {
//           _carregandoDados = false;
//         });
//       }
//       return;
//     }
    
//     try {
//       DocumentSnapshot doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(usuarioAtual.uid)
//           .get();

//       if (doc.exists && doc.data() != null) {
//         final dados = doc.data() as Map<String, dynamic>;
        
//         if (mounted) {
//           setState(() {
//             _nomeUsuario = dados['nome'] ?? 'Usuário do Bolha';
//             _emailUsuario = dados['email'] ?? usuarioAtual.email ?? 'E-mail não disponível';
//             _carregandoDados = false;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _nomeUsuario = usuarioAtual.displayName ?? 'Usuário do Bolha';
//             _emailUsuario = usuarioAtual.email ?? 'E-mail não disponível';
//             _carregandoDados = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _nomeUsuario = usuarioAtual.displayName ?? 'Usuário do Bolha';
//           _emailUsuario = usuarioAtual.email ?? 'E-mail não disponível';
//           _carregandoDados = false;
//         });
//       }
//     }
//   }

//   Future<void> _fazerLogout() async {
//     setState(() {
//       _deslogando = true;
//     });

//     try {
//       await _auth.signOut();
      
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Sessão encerrada com sucesso!')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Erro ao tentar deslogar.')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _deslogando = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User? usuario = _auth.currentUser;

//     // MODIFICAÇÃO ADICIONADA: Validação direta de segurança solicitada
//     if (usuario == null) {
//       return const Scaffold(
//         body: Center(
//           child: Text(
//             'Não logado',
//             style: TextStyle(
//               fontSize: 18,
//               fontFamily: 'PatrickHand',
//               fontWeight: FontWeight.w600,
//               color: BolhaColors.textMuted,
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Minha Conta',
//           style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: BolhaColors.background,
//         elevation: 0,
//         foregroundColor: BolhaColors.textPrimary,
//       ),
//       backgroundColor: BolhaColors.background,
//       body: SafeArea(
//         child: Center(
//           child: _carregandoDados
//               ? const CircularProgressIndicator(
//                   color: BolhaColors.primary,
//                 )
//               : Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Avatar circular com a primeira letra maiúscula do nome carregado
//                       SketchAvatar(
//                         radius: 50,
//                         backgroundColor: BolhaColors.surfaceAlt,
//                         child: Text(
//                           _nomeUsuario.isNotEmpty ? _nomeUsuario[0].toUpperCase() : 'U',
//                           style: const TextStyle(
//                             fontSize: 40,
//                             fontWeight: FontWeight.w800,
//                             color: BolhaColors.primary,
//                             fontFamily: 'PatrickHand',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       Text(
//                         _nomeUsuario,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.w800,
//                           fontFamily: 'PatrickHand',
//                           color: BolhaColors.textPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _emailUsuario,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'PatrickHand',
//                           color: BolhaColors.textMuted,
//                         ),
//                       ),
//                       const SizedBox(height: 48),
//                       SizedBox(
//                         width: 230,
//                         height: 50,
//                         child: ElevatedButton.icon(
//                           onPressed: _deslogando ? null : _fazerLogout,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: BolhaColors.danger,
//                             foregroundColor: Colors.white,
//                             shape: SketchBorder(
//                               borderRadius: BorderRadius.circular(41),
//                             ),
//                           ),
//                           icon: _deslogando 
//                               ? const SizedBox.shrink()
//                               : const Icon(Icons.logout, size: 18),
//                           label: _deslogando
//                               ? const SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : const Text(
//                                   'Sair da Conta',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontFamily: 'PatrickHand',
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

import '../screens/onboarding_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers para capturar o texto dos novos campos de edição
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

  // Nova função para buscar o registro atual e preencher os inputs de texto automaticamente
  Future<void> _carregarDadosIniciais() async {
    final User? usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) {
      if (mounted) setState(() => _carregandoDados = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(usuarioAtual.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final dados = doc.data() as Map<String, dynamic>;
        _nomeController.text = dados['nome'] ?? '';
        _telefoneController.text = dados['telefone'] ?? '';
        _bioController.text = dados['bio'] ?? '';
        _fotoController.text = dados['fotoPerfil'] ?? '';
        _bannerController.text = dados['banner'] ?? '';
      }
      
      _emailController.text = usuarioAtual.email ?? '';
    } catch (e) {
      // Caso dê erro ou não ache o documento, usa fallbacks do Auth
      _nomeController.text = usuarioAtual.displayName ?? '';
      _emailController.text = usuarioAtual.email ?? '';
    } finally {
      if (mounted) setState(() => _carregandoDados = false);
    }
  }

  // Função para salvar as modificações feitas pelo usuário no Firestore e Auth
  Future<void> _salvarPerfil() async {
    final User? usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return;

    setState(() => _salvandoDados = true);

    try {
      // 1. Atualiza as informações dentro da sua coleção do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(usuarioAtual.uid)
          .update({
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'fotoPerfil': _fotoController.text.trim(),
        'banner': _bannerController.text.trim(),
      });

      // 2. Se o e-mail mudou, envia a alteração para o FirebaseAuth
      if (_emailController.text.trim() != usuarioAtual.email) {
        await usuarioAtual.verifyBeforeUpdateEmail(_emailController.text.trim());
        _mostrarMensagem('Perfil atualizado! Verifique seu novo e-mail para validar a alteração.');
      } else {
        _mostrarMensagem('Modificações salvas com sucesso!');
      }

      if (!mounted) return;
      Navigator.pop(context); // Retorna para a tela de visualização do perfil
    } catch (e) {
      _mostrarMensagem('Erro ao salvar os dados: $e');
    } finally {
      if (mounted) setState(() => _salvandoDados = false);
    }
  }

  // Função isolada para gerenciar a troca de senha se o campo for preenchido
  Future<void> _alterarSenha() async {
    final User? usuarioAtual = _auth.currentUser;
    if (usuarioAtual == null) return;

    if (_senhaController.text.isEmpty || _senhaController.text.length < 6) {
      _mostrarMensagem('A senha precisa ter no mínimo 6 dígitos.');
      return;
    }

    try {
      await usuarioAtual.updatePassword(_senhaController.text);
      _senhaController.clear();
      _mostrarMensagem('Senha modificada com sucesso!');
    } catch (e) {
      _mostrarMensagem('Erro de segurança. Faça login novamente antes de alterar a senha.');
    }
  }

  // Função original para realizar o logout
  Future<void> _fazerLogout() async {
    setState(() {
      _deslogando = true;
    });

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao tentar deslogar.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deslogando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final User? usuario = _auth.currentUser;

    // Mantida a sua validação direta de segurança solicitada
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
              icon: _salvandoDados
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check, color: BolhaColors.lilac),
              onPressed: _salvandoDados ? null : _salvarPerfil,
            ),
        ],
      ),
      backgroundColor: BolhaColors.background,
      body: SafeArea(
        child: _carregandoDados
            ? const Center(
                child: CircularProgressIndicator(
                  color: BolhaColors.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Nome de Usuário
                    _construirCampoTexto(label: 'Nome de Usuário', controller: _nomeController),
                    const SizedBox(height: 16),

                    // Campo E-mail da Conta
                    _construirCampoTexto(label: 'E-mail da Conta', controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    // Campo Telefone
                    _construirCampoTexto(label: 'Telefone', controller: _telefoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),

                    // Campo Biografia (Bio)
                    _construirCampoTexto(label: 'Biografia (Bio)', controller: _bioController, maxLines: 3),
                    const SizedBox(height: 16),

                    // Campo URL da Foto de Perfil
                    _construirCampoTexto(label: 'URL da Foto de Perfil', controller: _fotoController),
                    const SizedBox(height: 16),

                    // Campo URL do Banner
                    _construirCampoTexto(label: 'URL do Banner', controller: _bannerController),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção de Segurança / Alterar Senha
                    const Text('Segurança', style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold, fontSize: 16)),
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
child: const Text('Alterar', style: TextStyle(fontFamily: 'PatrickHand', fontWeight: FontWeight.bold)),
),
],
),
const SizedBox(height: 48),
// Botão Modificado para Desconectar da Conta
SizedBox(
height: 50,
child: ElevatedButton.icon(
onPressed: _deslogando ? null : _fazerLogout,
style: ElevatedButton.styleFrom(
backgroundColor: BolhaColors.danger,
foregroundColor: Colors.white,
shape: SketchBorder(
borderRadius: BorderRadius.circular(41),
),
),
icon: _deslogando
? const SizedBox.shrink()
: const Icon(Icons.logout, size: 18),
label: _deslogando
? const SizedBox(
width: 16,
height: 16,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
: const Text(
'Desconectar da Conta',
style: TextStyle(
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
// Widget auxiliar para gerar campos estruturados e padronizados
Widget _construirCampoTexto({required String label, required TextEditingController controller, TextInputType? keyboardType, int maxLines = 1}) {
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
}