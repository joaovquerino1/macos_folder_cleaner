import Foundation
import AppKit

struct FolderHierarchy: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let depth: Int
    var subfolders: [FolderHierarchy] = []

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: FolderHierarchy, rhs: FolderHierarchy) -> Bool {
        lhs.url == rhs.url
    }
}

class FolderScanner: ObservableObject {
    @Published var emptyFolders: [FolderHierarchy] = []
    @Published var isScanning = false
    @Published var selectedPath: String = ""
    @Published var lastError: String?
    @Published var deletionStats: (deleted: Int, failed: Int)?

    func scanDirectory(at url: URL) {
        isScanning = true
        emptyFolders.removeAll()
        selectedPath = url.path
        lastError = nil
        deletionStats = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let foundFolders = self?.findEmptyFolderHierarchies(in: url) ?? []

            DispatchQueue.main.async {
                self?.emptyFolders = foundFolders.sorted { $0.url.path < $1.url.path }
                self?.isScanning = false
            }
        }
    }

    private func findEmptyFolderHierarchies(in directory: URL) -> [FolderHierarchy] {
        let fileManager = FileManager.default
        var emptyFolderURLs: Set<URL> = []

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsPackageDescendants]
        ) else {
            return []
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
            if isFolderEmpty(directoryURL, checkingAllFiles: true) {
                emptyFolderURLs.insert(directoryURL)
            }
        }

        // Filtrar para mostrar apenas as pastas "raiz" vazias (remover subpastas se a pai também está vazia)
        let rootEmptyFolders = filterRootEmptyFolders(from: Array(emptyFolderURLs))

        // Construir hierarquias
        return rootEmptyFolders.map { url in
            buildHierarchy(for: url, allEmpty: emptyFolderURLs)
        }
    }

    private func filterRootEmptyFolders(from folders: [URL]) -> [URL] {
        var result: [URL] = []

        for folder in folders.sorted(by: { $0.pathComponents.count < $1.pathComponents.count }) {
            // Verificar se alguma pasta pai já está na lista de resultado
            let hasParentInList = result.contains { parent in
                folder.path.hasPrefix(parent.path + "/")
            }

            if !hasParentInList {
                result.append(folder)
            }
        }

        return result
    }

    private func buildHierarchy(for url: URL, allEmpty: Set<URL>) -> FolderHierarchy {
        let fileManager = FileManager.default
        var subfolders: [FolderHierarchy] = []

        if let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for item in contents {
                if let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey]),
                   let isDirectory = resourceValues.isDirectory,
                   isDirectory,
                   allEmpty.contains(item) {
                    subfolders.append(buildHierarchy(for: item, allEmpty: allEmpty))
                }
            }
        }

        let depth = url.pathComponents.count
        return FolderHierarchy(url: url, depth: depth, subfolders: subfolders.sorted { $0.url.path < $1.url.path })
    }

    private func isFolderEmpty(_ url: URL, checkingAllFiles: Bool = false) -> Bool {
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: checkingAllFiles ? [] : [.skipsHiddenFiles]
            )

            // Se não há conteúdo, está vazio
            if contents.isEmpty {
                return true
            }

            // Se há conteúdo, verificar se todos são diretórios vazios
            for item in contents {
                if let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey]),
                   let isDirectory = resourceValues.isDirectory {
                    if isDirectory {
                        // Se é diretório, verificar recursivamente
                        if !isFolderEmpty(item, checkingAllFiles: checkingAllFiles) {
                            return false
                        }
                    } else {
                        // Se é arquivo, não está vazio
                        return false
                    }
                }
            }

            return true
        } catch {
            return false
        }
    }

    func deleteFolder(_ hierarchy: FolderHierarchy, useElevatedPrivileges: Bool = false) throws {
        let fileManager = FileManager.default

        do {
            // Tentar deletar normalmente primeiro
            try fileManager.removeItem(at: hierarchy.url)

            // Remover da lista
            DispatchQueue.main.async { [weak self] in
                self?.emptyFolders.removeAll { $0.url == hierarchy.url }
            }
        } catch let error as NSError {
            // Se falhar por permissão, tentar com privilégios elevados
            if error.domain == NSCocoaErrorDomain && (error.code == NSFileWriteNoPermissionError || error.code == NSFileNoSuchFileError) {
                if useElevatedPrivileges {
                    try deleteWithElevatedPrivileges(hierarchy.url)

                    // Remover da lista
                    DispatchQueue.main.async { [weak self] in
                        self?.emptyFolders.removeAll { $0.url == hierarchy.url }
                    }
                } else {
                    throw error
                }
            } else {
                throw error
            }
        }
    }

    private func deleteWithElevatedPrivileges(_ url: URL) throws {
        let script = """
        do shell script "rm -rf '\(url.path.replacingOccurrences(of: "'", with: "'\\''"))'" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                throw NSError(
                    domain: "FolderScannerError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Falha ao deletar com privilégios elevados: \(error)"]
                )
            }

            // Verificar se o arquivo ainda existe
            if FileManager.default.fileExists(atPath: url.path) {
                throw NSError(
                    domain: "FolderScannerError",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "A pasta não foi deletada mesmo com privilégios elevados"]
                )
            }
        }
    }

    func deleteAllEmptyFolders(askForElevation: Bool = true) {
        let foldersToDelete = emptyFolders

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var deletedCount = 0
            var failedCount = 0
            var needsElevation = false

            for folder in foldersToDelete {
                do {
                    try self?.deleteFolder(folder, useElevatedPrivileges: false)
                    deletedCount += 1
                } catch let error as NSError {
                    if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
                        needsElevation = true
                        failedCount += 1
                    } else {
                        print("Erro ao deletar \(folder.url.path): \(error.localizedDescription)")
                        failedCount += 1
                    }
                }
            }

            // Se houver falhas por permissão e o usuário permitir elevação, tentar novamente
            if needsElevation && askForElevation {
                DispatchQueue.main.async {
                    self?.promptForElevatedDeletion(foldersToDelete, previouslyDeleted: deletedCount)
                }
            } else {
                DispatchQueue.main.async {
                    self?.deletionStats = (deleted: deletedCount, failed: failedCount)
                    if failedCount > 0 {
                        self?.lastError = "\(failedCount) pasta(s) não puderam ser deletadas devido a problemas de permissão."
                    }
                }
            }
        }
    }

    private func promptForElevatedDeletion(_ folders: [FolderHierarchy], previouslyDeleted: Int) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var deletedCount = previouslyDeleted
            var failedCount = 0

            // Tentar deletar com privilégios elevados
            for folder in folders {
                // Verificar se ainda existe (pode ter sido deletado na primeira tentativa)
                if !FileManager.default.fileExists(atPath: folder.url.path) {
                    continue
                }

                do {
                    try self?.deleteFolder(folder, useElevatedPrivileges: true)
                    deletedCount += 1
                } catch {
                    print("Erro ao deletar com privilégios elevados \(folder.url.path): \(error.localizedDescription)")
                    failedCount += 1
                }
            }

            DispatchQueue.main.async {
                self?.deletionStats = (deleted: deletedCount, failed: failedCount)
                if failedCount > 0 {
                    self?.lastError = "\(failedCount) pasta(s) não puderam ser deletadas mesmo com privilégios elevados."
                }
            }
        }
    }

    func countAllFolders(_ hierarchy: FolderHierarchy) -> Int {
        var count = 1 // A própria pasta
        for subfolder in hierarchy.subfolders {
            count += countAllFolders(subfolder)
        }
        return count
    }
}
