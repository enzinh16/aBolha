# Login com Google e Discord — guia de configuração 🔑

O app já tem os botões **Continuar com Google** e **Continuar com Discord** (telas de **Login** e **Boas-vindas**). Falta só ligar os provedores no Firebase. Enquanto isso não for feito, tocar no botão mostra a mensagem *"Entrar com o Google/Discord ainda não foi ativado no Firebase"*, e o login por e-mail e senha continua funcionando normalmente.

## Como funciona no app

| Peça | Onde fica |
|---|---|
| Botões, mensagens de erro e criação do perfil | `app/lib/widgets/social_login_buttons.dart` |
| Chamadas ao Firebase Auth | `app/lib/services/auth_service.dart` (`entrarComGoogle`, `entrarComDiscord`) |
| Perfil criado só na primeira vez | `app/lib/services/firestore_service.dart` (`garantirUsuario`) |

O app usa `signInWithProvider` do `firebase_auth`, que abre o navegador do sistema, faz o login e volta para o app. **Não é preciso instalar nenhum pacote novo.**

Quem entra pela primeira vez ganha um perfil em `users/{uid}` com o **nome e a foto da conta** (`fotoPerfil`) e o telefone vazio. Quem já tinha perfil não é alterado.

## 1. Google

1. No [Console do Firebase](https://console.firebase.google.com/), abra o projeto e vá em **Authentication → Método de login → Google → Ativar**. Escolha um e-mail de suporte e salve.
2. Cadastre a **impressão digital (SHA-1 e SHA-256)** do app Android. Em `app/android`, rode:
   ```bash
   ./gradlew signingReport
   ```
   Copie o SHA-1 e o SHA-256 de `Variant: debug` e adicione em **Configurações do projeto → Seus apps → Android → Adicionar impressão digital**.
   > Cada pessoa do grupo tem uma chave de debug diferente: **cada uma precisa cadastrar o próprio SHA-1**. Para o APK de *release*, cadastre também o SHA-1 da chave de assinatura dele.
3. **Baixe o `google-services.json` de novo** e substitua `app/android/app/google-services.json`. Depois do passo 2 ele passa a trazer o cliente OAuth do Google.
4. Rode `flutter clean`, `flutter pub get` e `flutter run`.

No iOS, além disso, é preciso adicionar o `REVERSED_CLIENT_ID` (do `GoogleService-Info.plist`) como *URL Scheme* no `Info.plist`.

## 2. Discord

O Discord **não é um provedor nativo** do Firebase Auth. O app espera um provedor **OpenID Connect** com o ID exato `oidc.discord`.

1. No [Discord Developer Portal](https://discord.com/developers/applications), crie uma aplicação (**New Application**).
2. Em **OAuth2**, copie o **Client ID** e o **Client Secret** e adicione este **Redirect URI** (troque pelo ID do seu projeto Firebase):
   ```
   https://SEU_PROJECT_ID.firebaseapp.com/__/auth/handler
   ```
3. No Firebase, vá em **Authentication → Método de login → Adicionar novo provedor → OpenID Connect**:
   - **Nome:** `discord` (isso gera o ID `oidc.discord`)
   - **Client ID** e **Client secret:** os do passo 2
   - **URL do emissor (issuer):** a do Discord, que precisa publicar o documento `.well-known/openid-configuration`
4. Salve e teste no app.

> ⚠️ **Confirme este passo antes de apostar nele.** O Firebase só aceita provedores OIDC que publicam o documento de *discovery*. Se o Console recusar o emissor do Discord ou o login voltar com erro de configuração, o caminho alternativo é o **token customizado**: uma Cloud Function troca o código OAuth do Discord por um token do Firebase (`createCustomToken`) e o app entra com `signInWithCustomToken`. Isso exige o plano Blaze do Firebase e uma pequena mudança no app. Se precisarem, é só pedir que a gente monta.

## 3. Conferindo se deu certo

| O que aparece | Causa provável |
|---|---|
| "Entrar com o Google/Discord ainda não foi ativado no Firebase" (`operation-not-allowed`) | O provedor não foi ativado no passo 1 ou 3 |
| Janela do Google abre e fecha com erro / `sign_in_failed` / `DEVELOPER_ERROR` | SHA-1 ou SHA-256 ainda não cadastrado, ou `google-services.json` antigo |
| "Já existe uma conta com esse e-mail, criada de outro jeito" (`account-exists-with-different-credential`) | O mesmo e-mail já foi usado com outro método. Entre com o método original |
| Discord devolve `redirect_uri` inválido | O Redirect URI do passo 2 não bate exatamente com o do Firebase |

Dica: o app registra o código do erro no console (`debugPrint`), então rode `flutter run` e olhe o terminal.

## Observações

- Quem entra com Google/Discord **não tem senha**. O botão **Alterar senha** em *Editar perfil* vai avisar que não foi possível alterar para essas contas.
- O **"Esqueceu a senha?"** do login manda o link de redefinição pelo Firebase e vale só para contas de e-mail e senha.
- A sessão continua persistente: depois de entrar, o app abre direto na tela principal.
