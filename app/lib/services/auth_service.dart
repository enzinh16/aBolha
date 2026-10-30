import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> cadastrar(
    String email,
    String senha,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
  }

  Future<UserCredential> login(
    String email,
    String senha,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
  }

  /// ID do provedor do Discord no Firebase.
  ///
  /// O Discord não é um provedor nativo do Firebase Auth: ele precisa ser
  /// cadastrado no Console (Authentication > Método de login > Novo provedor
  /// > OpenID Connect) com exatamente este ID. Passo a passo em
  /// docs/login-social.md.
  static const String idProvedorDiscord = 'oidc.discord';

  /// Entrar (ou criar conta) com o Google.
  Future<UserCredential> entrarComGoogle() {
    final provedor = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    return _entrarComProvedor(provedor);
  }

  /// Entrar (ou criar conta) com o Discord.
  Future<UserCredential> entrarComDiscord() {
    final provedor = OAuthProvider(idProvedorDiscord)
      ..addScope('openid')
      ..addScope('identify')
      ..addScope('email');
    return _entrarComProvedor(provedor);
  }

  Future<UserCredential> _entrarComProvedor(AuthProvider provedor) {
    // No Android/iOS o Firebase abre o navegador do sistema; na web usa popup.
    if (kIsWeb) {
      return _auth.signInWithPopup(provedor);
    }
    return _auth.signInWithProvider(provedor);
  }

  /// Manda o e-mail de redefinição de senha.
  Future<void> enviarRedefinicaoDeSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get usuarioAtual => _auth.currentUser;
}