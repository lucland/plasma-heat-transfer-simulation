# Desenvolvimento do Simulador de Fornalha de Plasma

## Planejamento e Configuração
- [x] Ler e analisar os requisitos do software
- [x] Esclarecer requisitos com o usuário
- [ ] Projetar a arquitetura do sistema
  - [ ] Definir estrutura do projeto Rust (backend)
  - [ ] Definir estrutura do projeto Flutter (frontend)
  - [ ] Projetar interface FFI entre Rust e Dart
- [ ] Configurar ambiente de desenvolvimento para macOS
- [ ] Configurar estrutura básica do projeto

## Implementação por Features

### Feature 1: Núcleo de Simulação Básica
- [ ] Backend (Rust)
  - [ ] Implementar estruturas de dados para parâmetros de entrada
  - [ ] Implementar malha de discretização cilíndrica
  - [ ] Implementar solucionador básico da equação de calor
  - [ ] Implementar exportação de resultados
- [ ] Frontend (Flutter)
  - [ ] Criar tela de entrada de parâmetros básicos
  - [ ] Implementar visualização 2D básica dos resultados
  - [ ] Implementar interface FFI para comunicação com o backend
  - [ ] Testar integração básica

### Feature 2: Configuração de Geometria e Tochas
- [ ] Backend (Rust)
  - [ ] Implementar configuração de múltiplas tochas
  - [ ] Implementar cálculos de transferência de calor das tochas
- [ ] Frontend (Flutter)
  - [ ] Criar interface para configuração de geometria
  - [ ] Criar interface para configuração de tochas
  - [ ] Implementar visualização da configuração

### Feature 3: Propriedades de Materiais
- [ ] Backend (Rust)
  - [ ] Implementar banco de dados de materiais
  - [ ] Implementar funções de propriedades dependentes de temperatura
- [ ] Frontend (Flutter)
  - [ ] Criar interface para seleção e configuração de materiais
  - [ ] Implementar visualização de propriedades

### Feature 4: Visualização Avançada
- [ ] Backend (Rust)
  - [ ] Preparar dados para visualização 3D
- [ ] Frontend (Flutter)
  - [ ] Implementar visualização 3D
  - [ ] Implementar controles de playback
  - [ ] Implementar seleção de estilos de visualização

### Feature 5: Editor de Fórmulas
- [ ] Backend (Rust)
  - [ ] Implementar sandbox para avaliação segura de fórmulas
- [ ] Frontend (Flutter)
  - [ ] Criar interface para visualização e edição de fórmulas
  - [ ] Implementar validação e feedback

### Feature 6: Métricas e Exportação
- [ ] Backend (Rust)
  - [ ] Implementar cálculo de métricas (composição de gás de síntese, valor de aquecimento, etc.)
  - [ ] Implementar exportação de dados completos (CSV/JSON)
- [ ] Frontend (Flutter)
  - [ ] Criar interface para visualização de métricas
  - [ ] Implementar controles de exportação

### Feature 7: Validação de Modelo
- [ ] Backend (Rust)
  - [ ] Implementar comparação com dados analíticos/experimentais
  - [ ] Implementar cálculo de métricas de erro
- [ ] Frontend (Flutter)
  - [ ] Criar interface para importação de dados de validação
  - [ ] Implementar visualização de comparação e desvios

### Feature 8: Estudos Paramétricos
- [ ] Backend (Rust)
  - [ ] Implementar execução de múltiplas simulações com parâmetros variados
- [ ] Frontend (Flutter)
  - [ ] Criar interface para definição de estudos paramétricos
  - [ ] Implementar visualização de resultados agregados

## Testes e Documentação
- [ ] Implementar testes unitários para o backend
- [ ] Implementar testes de integração
- [ ] Implementar testes de validação científica
- [ ] Criar documentação do usuário
- [ ] Criar tutorial de instalação para Windows e macOS

## Entrega Final
- [ ] Empacotar aplicativo para macOS
- [ ] Criar tutorial para geração de executável para Windows
- [ ] Entregar produto final com documentação
