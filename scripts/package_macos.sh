#!/bin/bash

# Script para empacotar o Simulador de Fornalha de Plasma para macOS
# Este script deve ser executado em um ambiente macOS

# Definir variáveis
APP_NAME="Simulador de Fornalha de Plasma"
VERSION="1.0.0"
OUTPUT_DIR="$(pwd)/dist"
BUILD_DIR="$(pwd)/build"
MACOS_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$MACOS_DIR/Contents"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MACOS_BIN_DIR="$CONTENTS_DIR/MacOS"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para exibir mensagens de progresso
progress() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Função para exibir avisos
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para exibir erros
error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

# Verificar se estamos em um macOS
if [[ $(uname) != "Darwin" ]]; then
    error "Este script deve ser executado em um sistema macOS."
fi

# Verificar se o Flutter está instalado
if ! command -v flutter &> /dev/null; then
    error "Flutter não encontrado. Por favor, instale o Flutter antes de continuar."
fi

# Verificar se o Rust está instalado
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
    error "Rust não encontrado. Por favor, instale o Rust antes de continuar."
fi

# Criar diretórios necessários
progress "Criando diretórios para o pacote..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$CONTENTS_DIR"
mkdir -p "$FRAMEWORKS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$MACOS_BIN_DIR"

# Compilar a biblioteca Rust
progress "Compilando a biblioteca Rust..."
cd backend || error "Diretório backend não encontrado."
cargo build --release || error "Falha ao compilar a biblioteca Rust."
cd ..

# Copiar a biblioteca Rust para o diretório de frameworks
progress "Copiando a biblioteca Rust..."
cp "backend/target/release/libplasma_simulation.dylib" "$FRAMEWORKS_DIR/" || error "Falha ao copiar a biblioteca Rust."

# Compilar o aplicativo Flutter para macOS
progress "Compilando o aplicativo Flutter para macOS..."
cd frontend || error "Diretório frontend não encontrado."
flutter clean
flutter pub get
flutter build macos --release || error "Falha ao compilar o aplicativo Flutter para macOS."
cd ..

# Copiar o aplicativo Flutter compilado
progress "Copiando o aplicativo Flutter compilado..."
cp -R "frontend/build/macos/Build/Products/Release/plasma_furnace_ui.app/" "$MACOS_DIR/" || error "Falha ao copiar o aplicativo Flutter compilado."

# Criar arquivo Info.plist
progress "Criando arquivo Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>pt_BR</string>
    <key>CFBundleExecutable</key>
    <string>plasma_furnace_ui</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.plasma.furnace</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Plasma Furnace Team. Todos os direitos reservados.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copiar documentação
progress "Copiando documentação..."
mkdir -p "$RESOURCES_DIR/docs"
cp -R docs/* "$RESOURCES_DIR/docs/" || warning "Falha ao copiar alguns arquivos de documentação."

# Criar DMG
progress "Criando arquivo DMG..."
DMG_FILE="$OUTPUT_DIR/${APP_NAME// /_}-$VERSION-macOS.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$MACOS_DIR" -ov -format UDZO "$DMG_FILE" || error "Falha ao criar o arquivo DMG."

# Limpar arquivos temporários
progress "Limpando arquivos temporários..."
rm -rf "$BUILD_DIR"

progress "Empacotamento concluído com sucesso!"
progress "O arquivo DMG está disponível em: $DMG_FILE"
