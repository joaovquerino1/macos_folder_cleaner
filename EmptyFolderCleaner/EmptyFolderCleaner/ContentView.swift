import SwiftUI

struct FolderHierarchyView: View {
    let hierarchy: FolderHierarchy
    let scanner: FolderScanner
    let onDelete: (FolderHierarchy) -> Void
    let indentLevel: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Pasta principal
            HStack(spacing: 8) {
                // Indentação
                if indentLevel > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: CGFloat(indentLevel * 20), height: 1)
                }

                Image(systemName: hierarchy.subfolders.isEmpty ? "folder" : "folder.fill")
                    .foregroundColor(hierarchy.subfolders.isEmpty ? .orange : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(hierarchy.url.lastPathComponent)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)

                    if !hierarchy.subfolders.isEmpty {
                        Text("\(scanner.countAllFolders(hierarchy) - 1) subpasta(s) vazia(s)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    onDelete(hierarchy)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Deletar esta pasta e todas as subpastas")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(indentLevel == 0 ? 0.08 : 0.04))
            .cornerRadius(6)

            // Subpastas
            if !hierarchy.subfolders.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(hierarchy.subfolders) { subfolder in
                        FolderHierarchyView(
                            hierarchy: subfolder,
                            scanner: scanner,
                            onDelete: onDelete,
                            indentLevel: indentLevel + 1
                        )
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var scanner = FolderScanner()
    @State private var showDeleteConfirmation = false
    @State private var folderToDelete: FolderHierarchy?
    @State private var showStatsAlert = false

    var totalFolderCount: Int {
        scanner.emptyFolders.reduce(0) { sum, hierarchy in
            sum + scanner.countAllFolders(hierarchy)
        }
    }

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

                Text("Encontre e remova pastas vazias com suas subpastas")
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

            // Mensagem de erro
            if let error = scanner.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }

            // Estatísticas de deleção
            if let stats = scanner.deletionStats {
                HStack {
                    Image(systemName: stats.failed > 0 ? "checkmark.circle.badge.xmark" : "checkmark.circle.fill")
                        .foregroundColor(stats.failed > 0 ? .orange : .green)
                    Text("\(stats.deleted) pasta(s) deletada(s)" + (stats.failed > 0 ? ", \(stats.failed) falharam" : ""))
                        .font(.subheadline)
                        .foregroundColor(stats.failed > 0 ? .orange : .green)
                }
                .padding(.horizontal)
            }

            // Loading indicator
            if scanner.isScanning {
                ProgressView("Escaneando pastas e subpastas vazias...")
                    .padding()
            }

            // Lista de pastas vazias
            if !scanner.emptyFolders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(scanner.emptyFolders.count) hierarquia(s) de pasta(s) vazia(s)")
                                .font(.headline)
                            Text("Total: \(totalFolderCount) pasta(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(scanner.emptyFolders) { folder in
                                FolderHierarchyView(
                                    hierarchy: folder,
                                    scanner: scanner,
                                    onDelete: { hierarchy in
                                        folderToDelete = hierarchy
                                    },
                                    indentLevel: 0
                                )
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
        .frame(width: 750, height: 550)
        .alert("Deletar Todas as Pastas?", isPresented: $showDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Deletar", role: .destructive) {
                scanner.deleteAllEmptyFolders()
            }
        } message: {
            Text("Tem certeza que deseja deletar todas as \(totalFolderCount) pasta(s) vazia(s)? Isso inclui todas as hierarquias. Esta ação não pode ser desfeita.\n\nSe houver problemas de permissão, você será solicitado a fornecer sua senha de administrador.")
        }
        .alert("Deletar Pasta?", isPresented: .constant(folderToDelete != nil)) {
            Button("Cancelar", role: .cancel) {
                folderToDelete = nil
            }
            Button("Deletar", role: .destructive) {
                if let folder = folderToDelete {
                    deleteFolderWithErrorHandling(folder)
                }
            }
        } message: {
            if let folder = folderToDelete {
                let count = scanner.countAllFolders(folder)
                Text("Tem certeza que deseja deletar '\(folder.url.lastPathComponent)' e \(count - 1) subpasta(s)?\n\nSe houver problemas de permissão, você será solicitado a fornecer sua senha.")
            }
        }
    }

    private func deleteFolderWithErrorHandling(_ hierarchy: FolderHierarchy) {
        do {
            try scanner.deleteFolder(hierarchy, useElevatedPrivileges: false)
            folderToDelete = nil
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
                // Tentar com privilégios elevados
                do {
                    try scanner.deleteFolder(hierarchy, useElevatedPrivileges: true)
                    folderToDelete = nil
                } catch {
                    scanner.lastError = "Erro ao deletar: \(error.localizedDescription)"
                    folderToDelete = nil
                }
            } else {
                scanner.lastError = "Erro ao deletar: \(error.localizedDescription)"
                folderToDelete = nil
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
            scanner.lastError = nil
            scanner.deletionStats = nil
            scanner.scanDirectory(at: url)
        }
    }
}

#Preview {
    ContentView()
}
