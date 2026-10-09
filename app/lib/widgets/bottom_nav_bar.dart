import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/sketch_shapes.dart';

/// Barra inferior desenhada à mão: cada aba é uma bolha torta e a aba
/// ativa fica preenchida de rosa com contorno branco grosso.
/// Mantém a mesma API da versão anterior (currentIndex / onTap).
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _itens = [
    _Aba(Icons.person_outline, Icons.person, 'Conta'),
    _Aba(Icons.bubble_chart_outlined, Icons.bubble_chart, 'Bolhas'),
    _Aba(Icons.home_outlined, Icons.home, 'Home'),
    _Aba(Icons.search, Icons.search, 'Pesquisa'),
    _Aba(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BolhaColors.navBackground,
        border: Border(
          top: BorderSide(color: BolhaColors.surfaceAlt, width: 3),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: [
              for (var i = 0; i < _itens.length; i++)
                Expanded(child: _botao(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botao(int i) {
    final ativo = i == currentIndex;
    final aba = _itens[i];

    return InkWell(
      onTap: () => onTap(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SketchAvatar(
            radius: 19,
            variant: i,
            backgroundColor: ativo ? BolhaColors.secondary : Colors.transparent,
            outlineColor: ativo ? BolhaColors.outline : BolhaColors.textMuted,
            child: Icon(
              ativo ? aba.iconeAtivo : aba.icone,
              size: 20,
              color: ativo ? Colors.white : BolhaColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            aba.rotulo,
            style: TextStyle(
              fontFamily: AppTheme.fontCorpo,
              fontSize: 13,
              color: ativo ? BolhaColors.textPrimary : BolhaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Aba {
  final IconData icone;
  final IconData iconeAtivo;
  final String rotulo;

  const _Aba(this.icone, this.iconeAtivo, this.rotulo);
}
