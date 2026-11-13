//
//  AntSpaceEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// AntSpaceEngine - Espacio Hormiga R04
// Busca carpetas con miles de archivos chiquitos que juntos son gigas.
// NO usa enumerator, porque Swift 6 lo bloquea en async.
// Usa subpathsOfDirectory, que es seguro en async.

public struct AntFolder: Identifiable, Hashable {
    public var id: String {
        path
    }

    public var name: String
    public var path: String
    public var fileCount: Int
    public var totalBytes: Int64
    public var category: String
    public var risk: RiskLevel

    public init(
        name: String,
        path: String,
        fileCount: Int,
        totalBytes: Int64,
        category: String,
        risk: RiskLevel
    ) {
        self.name = name
        self.path = path
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.category = category
        self.risk = risk
    }

    // MARK: - Lo que pide AntSpaceView

    // Una carpeta es Hormiga si tiene muchos archivos chiquitos
    public var isAntSpace: Bool {
        if fileCount >= 100 {
            return true
        }

        if fileCount >= 50 && totalBytes >= 100_000_000 {
            return true
        }

        return false
    }

    // Tamaño promedio por archivo, para saber si son hormigas o no
    public var avgFileSize: Int64 {
        if fileCount == 0 {
            return 0
        }

        return totalBytes / Int64(fileCount)
    }
}

@MainActor
public final class AntSpaceEngine: ObservableObject {
    public static let shared = AntSpaceEngine()

    @Published public var folders: [AntFolder] = []
    @Published public var isAnalyzing = false
    @Published public var progressText = ""
    @Published public var currentFolderName = ""

    private var isCancelled = false

    private init() {}

    // MARK: - Lo que pide AntSpaceView

    public var totalAntFiles: Int {
        var total = 0

        for folder in folders {
            total += folder.fileCount
        }

        return total
    }

    public var totalAntBytes: Int64 {
        var total: Int64 = 0

        for folder in folders {
            total += folder.totalBytes
        }

        return total
    }

    public func cancel() {
        isCancelled = true
        isAnalyzing = false
        progressText = "Cancelado por el usuario."
        currentFolderName = ""
    }

    public func analyze(foldersToCheck: [String]) async {
        isCancelled = false
        isAnalyzing = true
        progressText = "Analizando Espacio Hormiga..."
        currentFolderName = ""
        folders = []

        var found: [AntFolder] = []

        for folderPath in foldersToCheck {
            if isCancelled {
                break
            }

            progressText = "Revisando \(folderPath)..."

            let expanded = (folderPath as NSString).expandingTildeInPath

            currentFolderName = (expanded as NSString).lastPathComponent

            let result = await analyzeOneFolder(path: expanded)

            if let folder = result {
                found.append(folder)
            }
        }

        found.sort { $0.totalBytes > $1.totalBytes }

        folders = found

        if isCancelled {
            progressText = "Cancelado por el usuario."
        } else {
            progressText = "Listo. \(found.count) carpetas hormiga."
        }

        currentFolderName = ""
        isAnalyzing = false
    }

    private func analyzeOneFolder(path: String) async -> AntFolder? {
        let fm = FileManager.default

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else {
            return nil
        }

        guard isDir.boolValue else {
            return nil
        }

        // FIX: No usamos enumerator, porque en async da error de makeIterator.
        // Usamos subpathsOfDirectory, que regresa un [String] normal.
        let subpaths = (try? fm.subpathsOfDirectory(atPath: path)) ?? []

        var fileCount = 0
        var totalBytes: Int64 = 0

        for relative in subpaths {
            if isCancelled {
                break
            }

            let full = (path as NSString).appendingPathComponent(relative)

            var isFileDir: ObjCBool = false
            guard fm.fileExists(atPath: full, isDirectory: &isFileDir) else {
                continue
            }

            if isFileDir.boolValue {
                continue
            }

            fileCount += 1

            if let attrs = try? fm.attributesOfItem(atPath: full) {
                if let size = attrs[.size] as? Int64 {
                    totalBytes += size
                }
            }

            if fileCount > 20000 {
                break
            }
        }

        // Solo nos interesan carpetas hormiga: muchos archivos o mucho peso
        if fileCount < 10 && totalBytes < 10_000_000 {
            return nil
        }

        let name = (path as NSString).lastPathComponent

        let category = categoryFor(path: path)
        let risk = riskFor(path: path)

        return AntFolder(
            name: name,
            path: path,
            fileCount: fileCount,
            totalBytes: totalBytes,
            category: category,
            risk: risk
        )
    }

    private func categoryFor(path: String) -> String {
        if path.contains("DerivedData") {
            return "Dev iOS"
        }

        if path.contains("CoreSimulator") {
            return "Dev iOS"
        }

        if path.contains("Caches") {
            return "Caché"
        }

        if path.contains("Downloads") {
            return "Descargas"
        }

        if path.contains("Desktop") {
            return "Escritorio"
        }

        return "Sistema"
    }

    private func riskFor(path: String) -> RiskLevel {
        if path.contains("DerivedData") {
            return .amarillo
        }

        if path.contains("CoreSimulator") {
            return .amarillo
        }

        if path.contains("Caches") {
            return .amarillo
        }

        return .verde
    }
}
