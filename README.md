# 🌌 Aurora Alarme

Um aplicativo moderno e robusto de alarme desenvolvido em Flutter com arquitetura híbrida (Kotlin nativo) para máxima confiabilidade de disparo sobre a tela de bloqueio do Android.

---

## 🚀 Como Executar e Atualizar no Celular (ADB)

O projeto inclui um script automatizado [`update.sh`](update.sh) para compilar, instalar e abrir o app no seu dispositivo conectado via USB ou Wi-Fi com depuração ativada.

### Instalação e Atualização Padrão
Compila o APK de depuração (Debug), instala preservando seus dados e alarmes salvos, concede permissões e abre o aplicativo automaticamente:

```bash
./update.sh
```

### Comandos Rápidos e Opções Adicionais

| Comando | Descrição |
|---|---|
| `./update.sh` | Compila em modo debug, instala preservando dados e abre o app |
| `./update.sh --fast` | Pula a compilação e instala o APK existente imediatamente (~5-8s) |
| `./update.sh --logs` (ou `-l`) | Instala e abre o monitor de logs em tempo real (filtrado para o Aurora Alarme) |
| `./update.sh --release` | Compila e instala a versão de produção (Release) |
| `./update.sh --clean` | Executa `flutter clean` antes de compilar |

### Desenvolvimento com Hot Reload
Para desenvolvimento iterativo da interface com suporte a Hot Reload (`r`) e Hot Restart (`R`):

```bash
flutter run
```

---

## 🛠️ Arquitetura Híbrida

- **Interface do Usuário (UI):** Construída com Flutter para transições fluidas, animações cósmicas e personalização de alarmes.
- **Mecanismo de Disparo (Nativo Android/Kotlin):**
  - `AlarmScheduler`: Usa `AlarmManager.setAlarmClock()` para garantir disparos exatos mesmo com economia de bateria e modo Doze ativados.
  - `AlarmReceiver`: Recebe o disparo em segundo plano, desperta a CPU/tela com `WakeLock` e inicia o som em loop.
  - `AlarmRingingActivity`: Tela nativa em tela cheia que abre sobre a tela de bloqueio (`showWhenLocked`, `turnScreenOn`) sem exigir PIN/senha prévia para desarmar ou adiar.
  - `NativeAlarmSoundPlayer`: Controle de áudio nativo com loop contínuo e atenuação de volume automática em modo **DEBUG** (5% do volume para conforto em testes noturnos).

---

## 🧪 Testes e Validações

Para rodar a suíte completa de testes e análise:

```bash
flutter analyze
flutter test
```
