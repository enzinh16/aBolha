# Documentação Inicial — aBolha 🫧

> Atualizada de acordo com a versão atual do app (identidade visual v2, tema escuro).

## 1. O problema

Pessoas com interesses específicos (um fandom, um jogo, um hobby, uma coincidência) têm dificuldade de encontrar comunidades ativas e acolhedoras para conversar sobre aquilo que as interessa. As opções atuais têm atrito:

- **Discord**: exige já saber qual servidor procurar; não tem descoberta orgânica de comunidades novas.
- **Reddit/fóruns**: interface pesada em texto, pouco visual, e a experiência de entrada (onboarding) é fria para quem não é usuário frequente.
- **Amino**: resolvia bem esse problema, mas o app está descontinuado/abandonado, deixando um espaço aberto no mercado.

## 2. Público-alvo

- Jovens de 16 a 28 anos, usuários de smartphone, já habituados a redes sociais baseadas em interesse (TikTok, Twitter/X, Discord).
- Pessoas que participam ou têm interesse em fandoms, comunidades de jogos, artistas ou bandas, animes, livros, esportes ou até mesmo hobbies mais específicos.
- Gente muito ligada na internet, o que guiou o visual do app: tema escuro, cores fortes e traço de adesivo desenhado à mão.
- Público majoritariamente brasileiro na fase inicial de lançamento.

## 3. Funcionalidades

### 3.1 Já entregues no app

| Funcionalidade | Como funciona hoje |
|---|---|
| **Cadastro e login** | Nome, e-mail, telefone e senha (com confirmação). Login por e-mail e senha com **Firebase Authentication**. |
| **Sessão persistente** | Quem já entrou abre o app direto na tela principal; só vê onboarding e login se não houver sessão salva. |
| **Bolhas (comunidades)** | Qualquer usuário **cria uma bolha** (nome, descrição e URL da foto), **entra** e **sai** dela. A aba *Bolhas* separa **Minhas Bolhas** de **Todas**. |
| **Página da bolha** | Mostra a descrição, o botão de entrar/sair e os posts daquela comunidade. |
| **Feed (Home)** | Posts mais recentes das bolhas, com **rolagem infinita** (5 posts por vez). Cada post mostra autor, bolha de origem, curtidas e comentários. |
| **Posts** | Criar uma nova postagem de texto numa bolha; o autor pode **excluir** o próprio post. |
| **Curtidas e comentários** | Curtir e descurtir, comentar, **responder comentários** (respostas aninhadas) e excluir o próprio comentário (junto com as respostas dele). |
| **Chat privado** | Conversas **1 a 1** com mensagens em tempo real; a aba *Chat* lista as conversas. |
| **Perfil e seguidores** | Perfil com os próprios posts, contagem de **seguidores** e **seguindo**, listas de ambos e botão **Seguir/Seguindo** no perfil de outras pessoas. |
| **Conta** | Edição dos dados do perfil, **troca de senha** e **logout**. |

Os dados aparecem **em tempo real** (posts, curtidas, comentários e mensagens usam *streams* do Firestore).

### 3.2 Planejadas (ainda não implementadas)

- **Onboarding por interesses**: no cadastro, escolher temas/tags e receber sugestões de bolhas compatíveis. Hoje o onboarding é só a tela de boas-vindas.
- **Pesquisa**: a aba existe na barra inferior, mas a tela ainda é um espaço reservado.
- **Imagens nos posts**: o modelo de post já tem o campo de imagem, mas a tela de nova postagem aceita só texto.
- **Chat em grupo** por bolha (hoje o chat é apenas 1 a 1).
- **Feed único** misturando as bolhas de que a pessoa participa, com sinalização de qual bolha originou cada post.
- **Perfil e gamificação leve**: nível de participação e badges por engajamento dentro das comunidades.

## 4. Como o app é organizado

### Telas

| Área | Telas |
|---|---|
| Acesso | Onboarding, Login, Cadastro |
| Barra inferior | Minha conta (perfil), Bolhas, Home, Pesquisa, Chat |
| Bolhas | Criar bolha, página da bolha, nova postagem, detalhe da postagem (curtidas e comentários) |
| Pessoas | Perfil de outro usuário, seguidores/seguindo, editar perfil |

### Dados (Cloud Firestore)

```
users/{uid}                              # nome, telefone, e-mail...
  ├── followers/{uid}
  └── following/{uid}
bubbles/{bubbleId}                       # nome, descrição, foto, criador
  ├── members/{uid}
  └── posts/{postId}                     # texto, autor, contadores
        ├── likes/{uid}
        └── comments/{commentId}         # parentId para respostas
conversations/{conversationId}           # id gerado a partir dos 2 usuários
  └── messages/{messageId}
```

### Código (`app/lib`)

`models/` (bolha, post, comentário) · `services/` (auth, usuários, bolhas, posts, chat, seguidores) · `screens/` · `theme/` (paleta e bordas desenhadas à mão) · `widgets/`.

## 5. Fora do escopo desta fase

- Moderação híbrida: metade automatizada por IA em casos menores e, em casos mais críticos, uma equipe de resolução de problemas. A moderação inicial será apenas manual, sendo a macro realizada pela nossa equipe e as micros (como assuntos que podem ser discutidos e abordagem) pelos criadores de cada bolha.
- Monetização (planejada, mas não implementada nesta fase).
- Versão web e desktop: o foco é mobile (Flutter, Android/iOS).
