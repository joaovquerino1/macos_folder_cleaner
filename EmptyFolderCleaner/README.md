# Empty Folder Cleaner 🗂️

Um aplicativo nativo para macOS que encontra e deleta pastas vazias em um diretório selecionado pelo usuário.

## Funcionalidades

- ✅ Interface gráfica moderna e intuitiva usando SwiftUI
- 🔍 Escaneamento recursivo de diretórios
- 📋 Visualização de todas as pastas vazias encontradas
- 🗑️ Opção de deletar pastas individualmente ou todas de uma vez
- 🔒 Sandboxed para maior segurança
- ⚡ Performance otimizada com operações assíncronas

## Requisitos

- macOS 13.0 (Ventura) ou superior
- Xcode 15.0 ou superior (para compilar o projeto)

## Como Usar

### Opção 1: Gerar o arquivo .app (Recomendado para distribuição)

#### Método 1: Archive (Para distribuição profissional)

1. Abra o arquivo `EmptyFolderCleaner.xcodeproj` no Xcode
2. No menu superior, vá em **Product** → **Archive**
3. Aguarde a compilação terminar
4. Na janela de Organizer que abrir:
   - Clique em **Distribute App**
   - Selecione **Copy App**
   - Escolha o local para salvar
5. O arquivo `EmptyFolderCleaner.app` estará no local escolhido

#### Método 2: Build para uso local (Mais rápido)

1. Abra o arquivo `EmptyFolderCleaner.xcodeproj` no Xcode
2. No menu superior, vá em **Product** → **Build** (ou `Cmd + B`)
3. Após a compilação, no navegador do projeto (lado esquerdo):
   - Expanda a pasta **Products**
   - Clique com botão direito em **EmptyFolderCleaner.app**
   - Selecione **Show in Finder**
4. O arquivo .app estará na pasta de build
5. Copie o arquivo .app para sua pasta **Applications** ou onde preferir

**Dica**: Para criar um .app otimizado para distribuição, use o Método 1 com a opção de Release.

### Opção 2: Executar direto do Xcode (Para desenvolvimento)

1. Abra o arquivo `EmptyFolderCleaner.xcodeproj` no Xcode
2. Selecione o esquema "EmptyFolderCleaner" e seu Mac como destino
3. Pressione `Cmd + R` para compilar e executar

### Executar o Aplicativo

1. Clique no botão **"Selecionar Diretório"**
2. Escolha a pasta que deseja escanear
3. O aplicativo irá automaticamente escanear o diretório e listar todas as pastas vazias
4. Você pode:
   - Deletar pastas individualmente clicando no ícone de lixeira ao lado de cada pasta
   - Deletar todas as pastas vazias de uma vez clicando em **"Deletar Todas"**

## Estrutura do Projeto

```
EmptyFolderCleaner/
├── EmptyFolderCleaner/
│   ├── EmptyFolderCleanerApp.swift  # Ponto de entrada do app
│   ├── ContentView.swift             # Interface principal do usuário
│   ├── FolderScanner.swift           # Lógica de escaneamento de pastas
│   ├── Assets.xcassets/              # Recursos visuais
│   └── EmptyFolderCleaner.entitlements  # Permissões do app
└── EmptyFolderCleaner.xcodeproj/     # Projeto Xcode
```

## Como Funciona

### FolderScanner

A classe `FolderScanner` é responsável por:
- Escanear recursivamente todos os diretórios a partir do caminho selecionado
- Identificar pastas que não contêm nenhum arquivo ou subpasta
- Ordenar as pastas por profundidade (mais profundas primeiro) para evitar problemas ao deletar
- Gerenciar a exclusão de pastas vazias

### ContentView

A interface do usuário oferece:
- Botão de seleção de diretório usando `NSOpenPanel`
- Lista scrollable de pastas vazias encontradas
- Feedback visual durante o escaneamento
- Confirmações antes de deletar pastas
- Mensagens de sucesso quando nenhuma pasta vazia é encontrada

## Permissões

O aplicativo requer as seguintes permissões (definidas no arquivo `.entitlements`):
- `com.apple.security.app-sandbox`: O app roda em sandbox para maior segurança
- `com.apple.security.files.user-selected.read-write`: Permite ler e escrever apenas em arquivos/pastas selecionados pelo usuário

## Avisos

⚠️ **IMPORTANTE**:
- A exclusão de pastas é **permanente** e não pode ser desfeita
- Sempre verifique cuidadosamente a lista de pastas antes de deletá-las
- Recomenda-se fazer backup de dados importantes antes de usar o aplicativo

## Tecnologias Utilizadas

- **SwiftUI**: Framework moderno para construção da interface
- **Combine**: Gerenciamento reativo de estado
- **FileManager**: API do macOS para operações de sistema de arquivos
- **NSOpenPanel**: Diálogo nativo de seleção de diretório

## Licença

Este projeto é fornecido como está, sem garantias de qualquer tipo.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.
