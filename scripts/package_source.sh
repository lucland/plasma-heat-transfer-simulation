#!/bin/bash

# Script para criar um arquivo ZIP com o código-fonte completo do projeto
# Útil para compartilhar o código-fonte ou para backup

# Definir variáveis
PROJECT_NAME="plasma_furnace_simulator"
VERSION="1.0.0"
OUTPUT_DIR="$(pwd)/dist"
SOURCE_DIR="$(pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ZIP_FILENAME="${PROJECT_NAME}_v${VERSION}_source_${TIMESTAMP}.zip"

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

# Verificar se o diretório de saída existe
if [ ! -d "$OUTPUT_DIR" ]; then
    progress "Criando diretório de saída..."
    mkdir -p "$OUTPUT_DIR" || error "Não foi possível criar o diretório de saída."
fi

# Criar lista de arquivos e diretórios a serem incluídos
progress "Preparando lista de arquivos para empacotamento..."
INCLUDE_DIRS=(
    "backend/src"
    "backend/Cargo.toml"
    "backend/Cargo.lock"
    "frontend/lib"
    "frontend/pubspec.yaml"
    "frontend/pubspec.lock"
    "frontend/assets"
    "frontend/test"
    "docs"
    "scripts"
    "README.md"
)

# Criar lista de arquivos e diretórios a serem excluídos
EXCLUDE_PATTERNS=(
    "*/build/*"
    "*/target/*"
    "*/.dart_tool/*"
    "*/.flutter-plugins*"
    "*/.packages"
    "*/.pub-cache/*"
    "*/.pub/*"
    "*/dist/*"
    "*/.git/*"
    "*/.github/*"
    "*/.idea/*"
    "*/.vscode/*"
    "*/node_modules/*"
    "*/.DS_Store"
    "*/*.iml"
    "*/*.log"
    "*/*.tmp"
)

# Construir string de exclusão para o comando zip
EXCLUDE_STRING=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_STRING="$EXCLUDE_STRING --exclude=$pattern"
done

# Verificar se o comando zip está disponível
if ! command -v zip &> /dev/null; then
    error "O comando 'zip' não foi encontrado. Por favor, instale-o antes de continuar."
fi

# Criar o arquivo ZIP
progress "Criando arquivo ZIP com o código-fonte..."
cd "$SOURCE_DIR" || error "Não foi possível acessar o diretório do projeto."

# Construir o comando zip
ZIP_CMD="zip -r \"$OUTPUT_DIR/$ZIP_FILENAME\" ${INCLUDE_DIRS[*]} $EXCLUDE_STRING"

# Executar o comando
eval "$ZIP_CMD"

if [ $? -eq 0 ]; then
    progress "Arquivo ZIP criado com sucesso: $OUTPUT_DIR/$ZIP_FILENAME"
else
    error "Falha ao criar o arquivo ZIP."
fi

# Calcular o tamanho do arquivo
if [ -f "$OUTPUT_DIR/$ZIP_FILENAME" ]; then
    SIZE=$(du -h "$OUTPUT_DIR/$ZIP_FILENAME" | cut -f1)
    progress "Tamanho do arquivo: $SIZE"
fi

progress "Empacotamento do código-fonte concluído!"
