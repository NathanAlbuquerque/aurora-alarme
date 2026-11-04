#!/usr/bin/env bash

# ==============================================================================
# Aurora Alarme - Script de Atualização Rápida no Dispositivo (ADB)
# ==============================================================================

set -e

# Cores para saída no terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PACKAGE_NAME="com.example.aurora_alarm"
MAIN_ACTIVITY="com.example.aurora_alarm/.MainActivity"

echo -e "${PURPLE}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║         🌌 AURORA ALARME - DEPLOY TOOL 🚀         ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Verificar se o adb está instalado
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ Erro: 'adb' não foi encontrado no PATH.${NC}"
    echo "Instale o android-tools ou adicione o platform-tools ao seu PATH."
    exit 1
fi

# 2. Verificar conexão com o dispositivo
echo -e "${CYAN}🔍 Verificando dispositivos conectados via ADB...${NC}"
DEVICE_LINE=$(adb devices | grep -E "device$|unauthorized$" | head -n 1 || true)

if [ -z "$DEVICE_LINE" ]; then
    echo -e "${RED}❌ Nenhum celular conectado ou detectado via USB/Wi-Fi.${NC}"
    echo -e "${YELLOW}Dicas:${NC}"
    echo "  1. Conecte o cabo USB no computador."
    echo "  2. Ative as 'Opções do Desenvolvedor' no seu celular."
    echo "  3. Ative a 'Depuração USB'."
    exit 1
fi

DEVICE_ID=$(echo "$DEVICE_LINE" | awk '{print $1}')
DEVICE_STATUS=$(echo "$DEVICE_LINE" | awk '{print $2}')

if [ "$DEVICE_STATUS" = "unauthorized" ]; then
    echo -e "${YELLOW}⚠️ Dispositivo '$DEVICE_ID' está NÃO AUTORIZADO!${NC}"
    echo -e "Olhe para a tela do seu celular agora e clique em: ${BOLD}'Sempre permitir a partir deste computador'${NC} -> ${BOLD}'OK'${NC}."
    echo "Aguardando autorização..."
    adb wait-for-device
fi

MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n' || echo "Desconhecido")
ANDROID_VER=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n' || echo "Desconhecido")
SDK_VER=$(adb -s "$DEVICE_ID" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r\n' || echo "Desconhecido")

echo -e "${GREEN}📱 Dispositivo conectado com sucesso:${NC}"
echo -e "   • ${BOLD}ID:${NC} $DEVICE_ID"
echo -e "   • ${BOLD}Modelo:${NC} $MODEL"
echo -e "   • ${BOLD}Android:${NC} $ANDROID_VER (SDK $SDK_VER)"
echo ""

# Processar argumentos de linha de comando
BUILD_MODE="debug"
FAST_INSTALL=false
WATCH_LOGS=false
CLEAN_FIRST=false

for arg in "$@"; do
    case "$arg" in
        --release)
            BUILD_MODE="release"
            ;;
        --fast)
            FAST_INSTALL=true
            ;;
        --logs|-l)
            WATCH_LOGS=true
            ;;
        --clean)
            CLEAN_FIRST=true
            ;;
        --help|-h)
            echo "Uso: ./update.sh [opções]"
            echo ""
            echo "Opções:"
            echo "  (padrão)     Compila em modo debug, instala mantendo dados e abre o app"
            echo "  --fast       Pula a compilação e instala o APK existente imediatamente"
            echo "  --logs, -l   Após instalar, abre o monitor de logs (logcat) filtrado"
            echo "  --release    Compila e instala a versão release"
            echo "  --clean      Executa 'flutter clean' antes de compilar"
            echo "  --help, -h   Exibe esta ajuda"
            exit 0
            ;;
    esac
done

if [ "$BUILD_MODE" = "debug" ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
else
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
fi

# 3. Compilação (se não for --fast)
if [ "$FAST_INSTALL" = false ] || [ ! -f "$APK_PATH" ]; then
    if [ "$CLEAN_FIRST" = true ]; then
        echo -e "${YELLOW}🧹 Limpando build anterior...${NC}"
        flutter clean
    fi

    echo -e "${CYAN}⚙️  Compilando APK ($BUILD_MODE)...${NC}"
    if [ "$BUILD_MODE" = "debug" ]; then
        flutter build apk --debug
    else
        flutter build apk --release
    fi
else
    echo -e "${YELLOW}⚡ Modo rápido: pulando compilação (usando $APK_PATH)...${NC}"
fi

# 4. Instalação no dispositivo
echo ""
echo -e "${CYAN}📦 Instalando no celular ($DEVICE_ID)...${NC}"
adb -s "$DEVICE_ID" install -r -d "$APK_PATH"

# 5. Garantir permissões essenciais de notificação (Android 13+)
echo -e "${CYAN}🔐 Garantindo permissão de notificações...${NC}"
adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_NAME" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

# 6. Iniciar o app no dispositivo
echo -e "${CYAN}🚀 Abrindo o Aurora Alarme...${NC}"
adb -s "$DEVICE_ID" shell am start -n "$MAIN_ACTIVITY"

echo ""
echo -e "${GREEN}${BOLD}✨ Concluído com sucesso! O Aurora Alarme foi atualizado no seu celular.${NC}"

# 7. Monitorar logs se solicitado
if [ "$WATCH_LOGS" = true ]; then
    echo ""
    echo -e "${PURPLE}📋 Monitorando logs do app (Ctrl+C para sair)...${NC}"
    adb -s "$DEVICE_ID" logcat -v time | grep --line-buffered -E "aurora|Aurora|AlarmReceiver|AlarmRinging|NativeAlarm|flutter"
fi
