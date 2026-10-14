# Lembrete de Água (Android · Flutter)

App Android que avisa, todos os dias, a hora de beber 1 copo de água (250 mL):
07h, 08h, 09h, 10h, 11h, 12h, 14h, 15h, 16h, 17h, 18h, 19h, 21h e 22h
(14 copos, 3,5 L por dia). Os horários são os mesmos do arquivo `alarmes-agua.ics`.

## Como gerar o APK sem instalar nada no PC (GitHub Actions)

1. Crie uma conta grátis em https://github.com (ou entre na sua).
2. Clique em **+ → New repository**. Nome: `lembrete-agua`. Marque **Private**. Clique em **Create repository**.
3. Na página do repositório novo, clique no link **uploading an existing file**.
4. Descompacte o `lembrete_agua.zip` no PC, abra a pasta `lembrete_agua`, selecione **tudo o que está dentro dela**
   (`.github`, `lib`, `tool`, `pubspec.yaml`, `README.md`) e arraste para a página. Clique em **Commit changes**.
5. Confira se a pasta `.github` aparece na lista de arquivos. Se não aparecer, veja "Plano B" abaixo.
6. Abra a aba **Actions**. Vai aparecer "Gerar APK" rodando (bolinha amarela). Espere uns 5–10 min até ficar ✅ verde.
7. Clique na execução → role até **Artifacts** → baixe **lembrete-agua-apk** (vem em .zip; dentro está o `app-release.apk`).
8. Mande o `app-release.apk` para o celular (WhatsApp para você mesma, Google Drive ou cabo USB) e toque nele para instalar.
   O Android vai pedir para **permitir instalar apps desta fonte**: permita. O Play Protect pode avisar que o app é desconhecido;
   é normal para um app feito por você — toque em **Instalar mesmo assim**.

### Plano B — se a pasta `.github` não subiu
No repositório: **Add file → Create new file**. No nome, digite exatamente `.github/workflows/build-apk.yml`,
cole o conteúdo do arquivo `build-apk.yml` (está em `lembrete_agua/.github/workflows/`) e clique em **Commit changes**.

## Primeiro uso no celular
1. Abra o app **Água** e toque em **Ativar lembretes**. Permita as notificações.
2. Toque em **Enviar notificação de teste** para confirmar.
3. Se aparecer "Avisos podem atrasar alguns minutos", toque nele e permita **Alarmes e lembretes** para horário exato.
4. Em alguns celulares (Xiaomi, Samsung, Motorola), vá em Configurações → Apps → Água → **Bateria → Sem restrições**,
   senão o sistema pode segurar os avisos.

## Estrutura (para estudo)
- `lib/main.dart` — todo o app: tela, agendamento diário com `flutter_local_notifications` e fuso `America/Sao_Paulo`.
- `pubspec.yaml` — dependências.
- `tool/patch_android.py` — ajusta o projeto Android (permissões, desugaring, nome do app).
- `.github/workflows/build-apk.yml` — receita que o GitHub usa para compilar o APK.

Para mudar horários ou o tamanho do copo, edite `horarios` e `mlPorCopo` no topo de `lib/main.dart`
e envie de novo ao GitHub: um APK novo é gerado sozinho.
