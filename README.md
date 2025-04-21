# README.md - Simulador de Fornalha de Plasma

## Visão Geral

O Simulador de Fornalha de Plasma é uma aplicação desktop multiplataforma projetada para simular a transferência de calor em fornalhas de plasma. Este software permite aos engenheiros e pesquisadores modelar, simular e analisar o comportamento térmico de fornalhas de plasma com alta precisão, auxiliando no design, otimização e operação desses sistemas.

## Características Principais

- **Simulação de Alta Performance**: Núcleo de simulação em Rust para cálculos numéricos intensivos
- **Interface Gráfica Intuitiva**: Frontend em Flutter para experiência multiplataforma
- **Visualização Avançada**: Visualizações 2D e 3D interativas dos resultados
- **Configuração Flexível**: Suporte para múltiplas tochas e geometrias complexas
- **Biblioteca de Materiais**: Propriedades térmicas predefinidas e personalizáveis
- **Editor de Fórmulas**: Personalização das equações físicas
- **Estudos Paramétricos**: Exploração sistemática do espaço de parâmetros
- **Validação de Modelos**: Comparação com dados experimentais ou analíticos
- **Métricas e Exportação**: Análise quantitativa e exportação de resultados

## Status de Desenvolvimento

**Nota:** O núcleo de simulação está atualmente passando por uma refatoração significativa para melhorar a precisão da modelagem de mudança de fase. Foi implementado o **Método da Entalpia**, substituindo a abordagem anterior. Atualmente, a equação da entalpia é resolvida usando um método **Euler Explícito**, que pode exigir passos de tempo pequenos para garantir a estabilidade. A implementação de um solver implícito mais robusto (como Crank-Nicolson com tratamento de não-linearidade) é um próximo passo planejado. Consulte `docs/phase_change_modeling.md` e `docs/solver_methods.md` para mais detalhes.

## Requisitos do Sistema

### macOS
- macOS 10.15 ou superior
- 8 GB de RAM (recomendado: 16 GB)
- 500 MB de espaço em disco
- Placa de vídeo compatível com OpenGL 3.3+

### Windows
- Windows 10 ou superior
- 8 GB de RAM (recomendado: 16 GB)
- 500 MB de espaço em disco
- Placa de vídeo compatível com OpenGL 3.3+

## Instalação

### macOS
1. Baixe o arquivo `Simulador_de_Fornalha_de_Plasma-1.0.0-macOS.dmg`
2. Abra o arquivo DMG e arraste o aplicativo para a pasta Aplicativos
3. Na primeira execução, pode ser necessário autorizar a execução em Preferências do Sistema > Segurança e Privacidade

### Windows
1. Baixe o arquivo `Simulador_de_Fornalha_de_Plasma-1.0.0-Windows-Setup.exe`
2. Execute o instalador e siga as instruções na tela
3. Após a instalação, o aplicativo estará disponível no menu Iniciar

## Documentação

A documentação completa está disponível na pasta `docs/`:

- **Manual do Usuário (`user_manual.md`)**: Guia abrangente para instalação e uso do software.
- **Guia de Referência (`reference_guide.md`)**: Informações detalhadas sobre parâmetros, fórmulas e APIs.
- **Tutorial (`tutorial.md`)**: Passo a passo para iniciantes realizarem sua primeira simulação.
- **Documentação Técnica (`technical_documentation.md`)**: Detalhamento da arquitetura e implementação.
- **Métodos do Solver (`solver_methods.md`)**: Descrição dos métodos numéricos usados na simulação de calor.
- **Modelagem de Mudança de Fase (`phase_change_modeling.md`)**: Discussão sobre as abordagens para simular fusão e vaporização.
- **Guia de Compilação (`build_guide.md`)**: Instruções para compilar e empacotar o software.

## Desenvolvimento

### Estrutura do Projeto

```
plasma_furnace_simulator/
├── backend/                  # Código Rust para simulação numérica
│   ├── src/
│   │   ├── simulation/       # Núcleo de simulação
│   │   ├── formula/          # Motor de fórmulas
│   │   ├── ffi/              # Interface FFI
│   │   └── ...
│   └── Cargo.toml            # Configuração do projeto Rust
│
├── frontend/                 # Aplicação Flutter
│   ├── lib/
│   │   ├── app/              # Configuração da aplicação
│   │   ├── models/           # Modelos de dados
│   │   ├── state/            # Gerenciamento de estado
│   │   ├── services/         # Serviços e ponte FFI
│   │   ├── screens/          # Telas da aplicação
│   │   ├── widgets/          # Componentes de UI
│   │   └── ...
│   └── pubspec.yaml          # Configuração do projeto Flutter
│
├── docs/                     # Documentação
│   ├── technical_documentation.md
│   ├── user_manual.md
│   ├── reference_guide.md
│   ├── tutorial.md
│   ├── solver_methods.md
│   ├── phase_change_modeling.md
│   └── build_guide.md
│
└── scripts/                  # Scripts de empacotamento
    ├── package_macos.sh      # Script para macOS
    ├── package_windows.bat   # Script para Windows
    └── package_source.sh     # Script para empacotar código-fonte
```

### Compilação e Empacotamento

Consulte o arquivo `docs/build_guide.md` para instruções detalhadas sobre como compilar e empacotar o software para diferentes plataformas.

## Licença

Este software é distribuído sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## Contato

Para suporte técnico ou dúvidas, entre em contato através de:
- Email: lucas.vsc@gmail.com
- LinkedIn: http://linkedin.com/in/lucasvalentedev
