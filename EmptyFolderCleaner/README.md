# Empty Folder Cleaner 🗂️

Um aplicativo nativo para macOS que encontra e deleta pastas vazias em um diretório selecionado pelo usuário.

## Funcionalidades

- ✅ Interface gráfica moderna e intuitiva usando SwiftUI
- 🔍 Escaneamento recursivo inteligente de diretórios
- 🌳 **Detecção de hierarquias completas** de pastas vazias (pasta pai + subpastas)
- 📋 **Visualização hierárquica** com indentação mostrando estrutura de pastas
- 🗑️ **Deleção automática em cascata** - ao deletar uma pasta, todas as subpastas vazias são removidas
- 🔐 **Elevação automática de privilégios** - solicita senha do administrador quando necessário
- 📊 Estatísticas de deleção com feedback de sucesso/erro
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
3. O aplicativo irá automaticamente escanear o diretório e listar todas as hierarquias de pastas vazias
4. A interface mostra:
   - **Pastas principais** com fundo mais escuro
   - **Subpastas vazias** indentadas abaixo da pasta pai
   - **Contador de subpastas** para cada hierarquia
   - **Caminho completo** ao passar o mouse sobre cada pasta
5. Você pode:
   - **Deletar individualmente**: Clique no ícone de lixeira ao lado de qualquer pasta (deleta a pasta e todas as subpastas vazias)
   - **Deletar todas**: Clique em "Deletar Todas" para remover todas as hierarquias de uma vez
6. **Tratamento de permissões**:
   - Se o app encontrar problemas de permissão, **automaticamente solicitará sua senha de administrador**
   - Você pode escolher fornecer a senha ou cancelar a operação

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
- **Escanear recursivamente** todos os diretórios a partir do caminho selecionado
- **Identificar hierarquias completas** de pastas vazias (pasta pai + todas as subpastas vazias)
- **Construir árvore hierárquica** mostrando a relação entre pastas e subpastas
- **Filtrar inteligentemente** para mostrar apenas pastas raiz (evita duplicação de subpastas)
- **Verificação profunda** - uma pasta é considerada vazia se ela e todas as suas subpastas não contêm arquivos
- **Gerenciar deleção em cascata** - ao deletar uma pasta, todas as subpastas vazias são removidas automaticamente
- **Elevação automática de privilégios** usando AppleScript quando encontra problemas de permissão

### ContentView

A interface do usuário oferece:
- Botão de seleção de diretório usando `NSOpenPanel`
- **Visualização hierárquica** com indentação mostrando estrutura de pastas
- **Contador de pastas** mostrando quantas subpastas cada hierarquia contém
- **Ícones diferenciados** (pasta vazia vs pasta com subpastas)
- Feedback visual durante o escaneamento
- **Estatísticas em tempo real** de deleções bem-sucedidas e falhas
- **Mensagens de erro** claras quando há problemas de permissão
- Confirmações antes de deletar pastas com informação sobre quantas subpastas serão removidas

## Permissões

O aplicativo requer as seguintes permissões (definidas no arquivo `.entitlements`):
- `com.apple.security.app-sandbox`: O app roda em sandbox para maior segurança
- `com.apple.security.files.user-selected.read-write`: Permite ler e escrever apenas em arquivos/pastas selecionados pelo usuário

## Avisos

⚠️ **IMPORTANTE**:
- A exclusão de pastas é **permanente** e não pode ser desfeita
- **Deleção em cascata**: Ao deletar uma pasta pai, **todas as subpastas vazias** também serão removidas
- Sempre verifique cuidadosamente a **hierarquia completa** antes de deletar
- O contador mostra **quantas pastas no total** serão removidas
- Recomenda-se fazer **backup de dados importantes** antes de usar o aplicativo
- **Elevação de privilégios**: Forneça sua senha de administrador apenas quando necessário e confiável

## Segurança

🔐 **Tratamento de Permissões**:
- O app tenta primeiro deletar sem privilégios elevados
- Se encontrar problemas de permissão, **solicita senha de administrador** via diálogo seguro do macOS
- A senha é tratada pelo sistema operacional, não pelo aplicativo
- Você sempre pode **cancelar** a solicitação de senha

🛡️ **Sandbox**:
- O aplicativo roda em sandbox do macOS
- Só pode acessar pastas que **você selecionou explicitamente**
- Não tem acesso a outras áreas do sistema sem sua permissão

## Tecnologias Utilizadas

- **SwiftUI**: Framework moderno para construção da interface com visualização hierárquica
- **Combine**: Gerenciamento reativo de estado e atualizações em tempo real
- **FileManager**: API do macOS para operações de sistema de arquivos
- **NSOpenPanel**: Diálogo nativo de seleção de diretório
- **NSAppleScript**: Elevação de privilégios segura quando necessário
- **DispatchQueue**: Operações assíncronas para não bloquear a interface

## Licença

Este projeto é fornecido como está, sem garantias de qualquer tipo.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.
