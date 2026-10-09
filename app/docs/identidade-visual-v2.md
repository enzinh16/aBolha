# Identidade visual v2 — Bolha (tema escuro, desenhado à mão)

Substitui a identidade azul do CP4. Motivos: sair do azul (parecido com
Twitter), falar com um público muito ligado na internet e assumir um visual
"feito à mão", como um adesivo ou um desenho no Paint.

## Princípios
1. **Escuro primeiro**: o app só tem `AppTheme.dark` (`AppTheme.light` é um alias).
2. **Contorno de adesivo**: tudo importante tem contorno branco grosso (2,5–4,5 px).
3. **Traço tremido, mas fixo**: formas com leves desvios escolhidos à mão
   (`lib/theme/sketch_shapes.dart`). Não são sorteadas, então o desenho não muda a cada abertura.
4. **Cores chapadas**: sem degradê e sem sombra suave. Sem azul e sem verde.

## Paleta
| Papel | Cor | Hex |
|---|---|---|
| Marca (botões, destaques) | Roxo bolha | `#8A4DFF` |
| Acento / ação principal | Rosa choque | `#FF5CAA` |
| Apoio | Orquídea / Rosa suave / Lilás | `#D94FD6` / `#FFA3D1` / `#C9A8FF` |
| Fundo | Roxo quase preto | `#0E0A1A` |
| Superfície / superfície alta | | `#1A1330` / `#2A1F4D` |
| Texto / texto secundário | Branco / lilás-cinza | `#FFFFFF` / `#A99BC9` |
| Erro | Rosa-vermelho | `#FF5C7A` |

Contrastes medidos: branco em `#8A4DFF` = 4,6:1; rosa `#FF5CAA` em `#0E0A1A` = 6,8:1;
texto secundário em `#0E0A1A` = 7,6:1.

## Tipografia
- Títulos e botões de destaque: **BolhaDisplay** (derivada da Erica One, OFL; contornos facetados como as letras do wordmark)
- Corpo: **Patrick Hand** (OFL)

## Componentes (lib/theme/sketch_shapes.dart)
- `SketchBorder`: substitui `RoundedRectangleBorder` (cards, botões, snackbar)
- `SketchInputBorder`: substitui `OutlineInputBorder` (campos de texto)
- `SketchAvatar`: substitui `CircleAvatar` (avatares, ícones da barra inferior)

## Arte
`docs/arte/` (SVG do wordmark "aBolha" e do ícone) e `docs/telas/` (telas de exemplo).
