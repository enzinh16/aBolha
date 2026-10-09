# Pitch — aBolha 🫧

<p align="center">
  <img src="../assets/readme/gifs/hero.gif" width="640" alt="aBolha — crie e viva sua bolha">
</p>

## Por que esse app existiria no mercado

O Amino, principal app de comunidades por nicho da última década, está abandonado/descontinuado, e nenhum concorrente direto ocupou esse espaço da forma certa: Discord exige buscar o servidor por fora do app, e Reddit tem barreira de entrada alta para o público mais jovem e mais visual, além de diversas réplicas malsucedidas do Amino (como o "Project Z").
Existe uma lacuna clara para um app **mobile-first, em português, com descoberta de comunidade como funcionalidade central**, não como algo secundário dentro de um app de propósito geral.

## O que já existe hoje

Não é só uma ideia: o aBolha já roda como app Flutter com Firebase. Quem baixa hoje consegue:

- **Criar conta e entrar**, com a sessão salva no aparelho;
- **Criar, entrar e sair de bolhas**, cada uma com a própria página;
- **Postar, curtir e comentar** (com respostas aninhadas), num feed de rolagem infinita;
- **Conversar em privado** em tempo real;
- **Seguir pessoas** e ter um perfil com seguidores e seguindo.

Isso entrega o núcleo da proposta (entrar numa comunidade e participar dela) antes de qualquer monetização. O que falta para fechar o MVP completo, como pesquisa, onboarding por interesses e gamificação, está no roadmap do [README](../README.md).

## Identidade que ninguém confunde

O público é muito ligado na internet, e o visual foi pensado para ele: **tema escuro**, **roxo e rosa** e um traço de **adesivo desenhado à mão**. Isso afasta o app do azul de rede social tradicional e dá uma cara própria, reconhecível até em um print recortado. Detalhes em [`iden-visual.md`](iden-visual.md).

## Modelo de negócio

Modelo **freemium**, com o core do produto (participar de bolhas, postar, conversar) sempre gratuito, e monetização em cima de camadas opcionais:

- **Bolhas Premium**: criadores de comunidade pagam para desbloquear customizações visuais (capa animada, cores da bolha, badges exclusivos e etc).
- **Moedas virtuais**: compra de itens cosméticos de perfil (molduras de avatar, efeitos de balão de chat, escolha de fontes diferentes para o nickname do usuário e etc). O estilo de adesivo do app facilita esses itens: molduras e contornos já fazem parte da linguagem visual.
- **Publicidade nativa segmentada por nicho**: marcas relevantes para cada comunidade (ex.: marca de games dentro de bolhas de games), em vez de anúncios genéricos.
- **Parcerias de marca**: bolhas oficiais patrocinadas por marcas/criadores de conteúdo do próprio nicho.

> A monetização ainda não está implementada; ela entra depois que o núcleo social estiver completo.

## Diferencial competitivo

| aBolha | Discord | Reddit | Amino |
|---|---|---|---|
| Comunidades por afinidade como centro do app (onboarding por interesses no roadmap) | ❌ (precisa achar o servidor fora do app) | Parcial (subreddits, mas pouco visual) | ✅ (mas app abandonado) |
| Visual mobile-first, escuro e autoral (adesivo desenhado à mão) | Parcial | ❌ | ❌ (desatualizado) |
| Foco e curadoria em português/Brasil | ❌ | ❌ | Parcial |
| Feed, comentários com respostas, chat e seguidores no mesmo app | Parcial (chat forte, feed fraco) | Parcial (feed forte, chat fraco) | ✅ |
| Moderação simplificada por criador de comunidade | ✅ | Parcial | ✅ |

aBolha não compete tentando ser "melhor Discord" ou "melhor Reddit": ele ocupa o nicho de **entrada fácil em comunidades de interesse**, que ficou vago desde o fim do Amino, com um produto visualmente atual e pensado para o comportamento de consumo de conteúdo de hoje, e com futuras melhorias.
