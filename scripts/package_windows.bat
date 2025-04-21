@echo off
REM Script para empacotar o Simulador de Fornalha de Plasma para Windows
REM Este script deve ser executado em um ambiente Windows

REM Definir variáveis
set APP_NAME=Simulador de Fornalha de Plasma
set VERSION=1.0.0
set OUTPUT_DIR=%CD%\dist
set BUILD_DIR=%CD%\build
set WINDOWS_DIR=%BUILD_DIR%\windows
set RESOURCES_DIR=%WINDOWS_DIR%\resources
set BIN_DIR=%WINDOWS_DIR%\bin

REM Função para exibir mensagens de progresso
echo [INFO] Iniciando empacotamento para Windows...

REM Verificar se o Flutter está instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Flutter não encontrado. Por favor, instale o Flutter antes de continuar.
    exit /b 1
)

REM Verificar se o Rust está instalado
where rustc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Rust não encontrado. Por favor, instale o Rust antes de continuar.
    exit /b 1
)

REM Verificar se o NSIS está instalado (para criar o instalador)
where makensis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] NSIS não encontrado. O instalador não será criado.
    set NSIS_AVAILABLE=0
) else (
    set NSIS_AVAILABLE=1
)

REM Criar diretórios necessários
echo [INFO] Criando diretórios para o pacote...
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%WINDOWS_DIR%" mkdir "%WINDOWS_DIR%"
if not exist "%RESOURCES_DIR%" mkdir "%RESOURCES_DIR%"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

REM Compilar a biblioteca Rust
echo [INFO] Compilando a biblioteca Rust...
cd backend
cargo build --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao compilar a biblioteca Rust.
    exit /b 1
)
cd ..

REM Copiar a biblioteca Rust para o diretório de binários
echo [INFO] Copiando a biblioteca Rust...
copy "backend\target\release\plasma_simulation.dll" "%BIN_DIR%\"
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao copiar a biblioteca Rust.
    exit /b 1
)

REM Compilar o aplicativo Flutter para Windows
echo [INFO] Compilando o aplicativo Flutter para Windows...
cd frontend
call flutter clean
call flutter pub get
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao compilar o aplicativo Flutter para Windows.
    exit /b 1
)
cd ..

REM Copiar o aplicativo Flutter compilado
echo [INFO] Copiando o aplicativo Flutter compilado...
xcopy "frontend\build\windows\runner\Release\*" "%BIN_DIR%\" /E /I /Y
if %ERRORLEVEL% NEQ 0 (
    echo [ERRO] Falha ao copiar o aplicativo Flutter compilado.
    exit /b 1
)

REM Copiar documentação
echo [INFO] Copiando documentação...
if not exist "%RESOURCES_DIR%\docs" mkdir "%RESOURCES_DIR%\docs"
xcopy "docs\*" "%RESOURCES_DIR%\docs\" /E /I /Y
if %ERRORLEVEL% NEQ 0 (
    echo [AVISO] Falha ao copiar alguns arquivos de documentação.
)

REM Criar arquivo de atalho
echo [INFO] Criando arquivo de atalho...
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%BUILD_DIR%\createShortcut.vbs"
echo sLinkFile = "%WINDOWS_DIR%\%APP_NAME%.lnk" >> "%BUILD_DIR%\createShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%BUILD_DIR%\createShortcut.vbs"
echo oLink.TargetPath = "%BIN_DIR%\plasma_furnace_ui.exe" >> "%BUILD_DIR%\createShortcut.vbs"
echo oLink.WorkingDirectory = "%BIN_DIR%" >> "%BUILD_DIR%\createShortcut.vbs"
echo oLink.Description = "Simulador de Fornalha de Plasma" >> "%BUILD_DIR%\createShortcut.vbs"
echo oLink.IconLocation = "%BIN_DIR%\plasma_furnace_ui.exe, 0" >> "%BUILD_DIR%\createShortcut.vbs"
echo oLink.Save >> "%BUILD_DIR%\createShortcut.vbs"
cscript //nologo "%BUILD_DIR%\createShortcut.vbs"
del "%BUILD_DIR%\createShortcut.vbs"

REM Criar instalador NSIS se disponível
if %NSIS_AVAILABLE% EQU 1 (
    echo [INFO] Criando script NSIS para o instalador...
    
    echo !include "MUI2.nsh" > "%BUILD_DIR%\installer.nsi"
    echo Name "%APP_NAME%" >> "%BUILD_DIR%\installer.nsi"
    echo OutFile "%OUTPUT_DIR%\%APP_NAME:-= %-%VERSION%-Windows-Setup.exe" >> "%BUILD_DIR%\installer.nsi"
    echo InstallDir "$PROGRAMFILES64\%APP_NAME%" >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_WELCOME >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_DIRECTORY >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_INSTFILES >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_FINISH >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_UNPAGE_CONFIRM >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_UNPAGE_INSTFILES >> "%BUILD_DIR%\installer.nsi"
    echo !insertmacro MUI_LANGUAGE "PortugueseBR" >> "%BUILD_DIR%\installer.nsi"
    echo Section "Instalação Principal" SecMain >> "%BUILD_DIR%\installer.nsi"
    echo     SetOutPath "$INSTDIR" >> "%BUILD_DIR%\installer.nsi"
    echo     File /r "%WINDOWS_DIR%\*.*" >> "%BUILD_DIR%\installer.nsi"
    echo     CreateDirectory "$SMPROGRAMS\%APP_NAME%" >> "%BUILD_DIR%\installer.nsi"
    echo     CreateShortcut "$SMPROGRAMS\%APP_NAME%\%APP_NAME%.lnk" "$INSTDIR\bin\plasma_furnace_ui.exe" >> "%BUILD_DIR%\installer.nsi"
    echo     CreateShortcut "$DESKTOP\%APP_NAME%.lnk" "$INSTDIR\bin\plasma_furnace_ui.exe" >> "%BUILD_DIR%\installer.nsi"
    echo     WriteUninstaller "$INSTDIR\uninstall.exe" >> "%BUILD_DIR%\installer.nsi"
    echo SectionEnd >> "%BUILD_DIR%\installer.nsi"
    echo Section "Uninstall" >> "%BUILD_DIR%\installer.nsi"
    echo     Delete "$INSTDIR\uninstall.exe" >> "%BUILD_DIR%\installer.nsi"
    echo     RMDir /r "$INSTDIR" >> "%BUILD_DIR%\installer.nsi"
    echo     Delete "$SMPROGRAMS\%APP_NAME%\%APP_NAME%.lnk" >> "%BUILD_DIR%\installer.nsi"
    echo     RMDir "$SMPROGRAMS\%APP_NAME%" >> "%BUILD_DIR%\installer.nsi"
    echo     Delete "$DESKTOP\%APP_NAME%.lnk" >> "%BUILD_DIR%\installer.nsi"
    echo SectionEnd >> "%BUILD_DIR%\installer.nsi"
    
    echo [INFO] Criando instalador...
    makensis "%BUILD_DIR%\installer.nsi"
    if %ERRORLEVEL% NEQ 0 (
        echo [AVISO] Falha ao criar o instalador.
    ) else (
        echo [INFO] Instalador criado com sucesso.
    )
) else (
    echo [INFO] Criando arquivo ZIP...
    powershell -Command "Compress-Archive -Path '%WINDOWS_DIR%\*' -DestinationPath '%OUTPUT_DIR%\%APP_NAME:-= %-%VERSION%-Windows.zip' -Force"
    if %ERRORLEVEL% NEQ 0 (
        echo [AVISO] Falha ao criar o arquivo ZIP.
    ) else (
        echo [INFO] Arquivo ZIP criado com sucesso.
    )
)

REM Limpar arquivos temporários
echo [INFO] Limpando arquivos temporários...
rmdir /S /Q "%BUILD_DIR%"

echo [INFO] Empacotamento concluído com sucesso!
if %NSIS_AVAILABLE% EQU 1 (
    echo [INFO] O instalador está disponível em: %OUTPUT_DIR%\%APP_NAME:-= %-%VERSION%-Windows-Setup.exe
) else (
    echo [INFO] O arquivo ZIP está disponível em: %OUTPUT_DIR%\%APP_NAME:-= %-%VERSION%-Windows.zip
)
