import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = FolderScanner()
    @State private var showDeleteConfirmation = false
    @State private var folderToDelete: URL?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.minus")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Empty Folder Cleaner")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Encontre e remova pastas vazias")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Botão de seleção de diretório
            Button(action: selectDirectory) {
                HStack {
                    Image(systemName: "folder")
                    Text("Selecionar Diretório")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            // Caminho selecionado
            if !scanner.selectedPath.isEmpty {
                Text("Pasta: \(scanner.selectedPath)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal)
            }

            // Loading indicator
            if scanner.isScanning {
                ProgressView("Escaneando...")
                    .padding()
            }

            // Lista de pastas vazias
            if !scanner.emptyFolders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(scanner.emptyFolders.count) pastas vazias encontradas")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Deletar Todas")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(scanner.emptyFolders, id: \.self) { folder in
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.orange)
                                    Text(folder.path)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button(action: {
                                        folderToDelete = folder
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Deletar esta pasta")
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else if !scanner.isScanning && !scanner.selectedPath.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Nenhuma pasta vazia encontrada!")
                        .font(.headline)
                }
                .padding()
            }

            Spacer()
        }
        .frame(width: 700, height: 500)
        .alert("Deletar Todas as Pastas?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Deletar", role: .destructive) {
                scanner.deleteAllEmptyFolders()
            }
        } message: {
            Text("Tem certeza que deseja deletar todas as \(scanner.emptyFolders.count) pastas vazias? Esta ação não pode ser desfeita.")
        }
        .alert("Deletar Pasta?", isPresented: .constant(folderToDelete != nil)) {
            Button("Cancelar", role: .cancel) {
                folderToDelete = nil
            }
            Button("Deletar", role: .destructive) {
                if let folder = folderToDelete {
                    do {
                        try scanner.deleteFolder(folder)
                        folderToDelete = nil
                    } catch {
                        print("Erro ao deletar: \(error)")
                    }
                }
            }
        } message: {
            if let folder = folderToDelete {
                Text("Tem certeza que deseja deletar '\(folder.lastPathComponent)'?")
            }
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Selecionar"
        panel.message = "Escolha o diretório para escanear"

        if panel.runModal() == .OK, let url = panel.url {
            scanner.scanDirectory(at: url)
        }
    }
}

#Preview {
    ContentView()
}
