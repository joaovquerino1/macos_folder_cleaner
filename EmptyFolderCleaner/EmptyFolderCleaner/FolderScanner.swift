import Foundation

class FolderScanner: ObservableObject {
    @Published var emptyFolders: [URL] = []
    @Published var isScanning = false
    @Published var selectedPath: String = ""

    func scanDirectory(at url: URL) {
        isScanning = true
        emptyFolders.removeAll()
        selectedPath = url.path

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let foundFolders = self?.findEmptyFolders(in: url) ?? []

            DispatchQueue.main.async {
                self?.emptyFolders = foundFolders.sorted { $0.path < $1.path }
                self?.isScanning = false
            }
        }
    }

    private func findEmptyFolders(in directory: URL) -> [URL] {
        var emptyFolders: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsPackageDescendants]
        ) else {
            return emptyFolders
        }

        var allDirectories: [URL] = []

        // Coletar todos os diretórios
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory,
                  isDirectory else {
                continue
            }
            allDirectories.append(fileURL)
        }

        // Ordenar por profundidade (mais profundos primeiro) para verificar de baixo para cima
        allDirectories.sort { url1, url2 in
            url1.pathComponents.count > url2.pathComponents.count
        }

        // Verificar quais estão vazios
        for directoryURL in allDirectories {
            if isFolderEmpty(directoryURL) {
                emptyFolders.append(directoryURL)
            }
        }

        return emptyFolders
    }

    private func isFolderEmpty(_ url: URL) -> Bool {
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return contents.isEmpty
        } catch {
            return false
        }
    }

    func deleteFolder(_ url: URL) throws {
        let fileManager = FileManager.default
        try fileManager.removeItem(at: url)

        // Remover da lista
        DispatchQueue.main.async { [weak self] in
            self?.emptyFolders.removeAll { $0 == url }
        }
    }

    func deleteAllEmptyFolders() {
        let foldersToDelete = emptyFolders

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var deletedCount = 0

            for folder in foldersToDelete {
                do {
                    try self?.deleteFolder(folder)
                    deletedCount += 1
                } catch {
                    print("Erro ao deletar \(folder.path): \(error)")
                }
            }

            print("Deletadas \(deletedCount) pastas vazias")
        }
    }
}
