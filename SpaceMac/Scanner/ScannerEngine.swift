//
//  ScannerEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// R04 - ScannerEngine REAL V3 + R03 Bonus + R06 Permisos
// Ya no es simulado. Lee tu disco real con FileManager.
// R03: Si es carpeta privada, ni la escanea.
// R01: Si es sistema, lo marca Rojo y no lo deja borrar.

public final class ScannerEngine: ObservableObject {
    @Published public var files: [ScannedFile] = []
    @Published public var isScanning: Bool = false
    @Published public var lastScanDate: Date? = nil
    @Published public var skippedPrivateCount: Int = 0
    @Published public var permissionMessage: String? = nil

    public init() {}

    public func scan() async -> [ScannedFile] {
        await MainActor.run { isScanning = true; skippedPrivateCount = 0; permissionMessage = nil }

        let privateFolders = PremiumEngine.shared.privateFolders
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // Rutas reales que sí te quitan espacio en un Mac de dev
        // No tocamos /System, no tocamos /Library del sistema, solo tu Home
        let targets: [(path: String, category: String)] = [
            ("\(home)/Library/Caches", "Caché"),
            ("\(home)/Library/Developer/Xcode/DerivedData", "Dev iOS"),
            ("\(home)/Library/Developer/CoreSimulator", "Dev iOS"),
            ("\(home)/Library/Caches", "Caché"),
            ("\(home)/Downloads", "Común"),
            ("\(home)/Desktop", "Común"),
        ]

        var found: [ScannedFile] = []
        var skipped = 0

        for target in targets {
            // R03: Si la carpeta completa es privada, la saltamos
            if isPrivate(target.path, privateFolders: privateFolders) {
                skipped += 1
                continue
            }

            let items = scanFolder(target.path, category: target.category, privateFolders: privateFolders, skipped: &skipped)
            found.append(contentsOf: items)

            // No queremos que se trabe: si ya tenemos 200 archivos, paramos, es suficiente para limpiar
            if found.count > 200 { break }
        }

        // Ordenar: los más grandes primero, que son los que te importan
        found.sort { $0.sizeBytes > $1.sizeBytes }

        await MainActor.run {
            self.files = found
            self.skippedPrivateCount = skipped
            self.isScanning = false
            self.lastScanDate = Date()
            if found.isEmpty {
                self.permissionMessage = "No se encontraron archivos. Dale permisos a SpaceMac en Ajustes del Sistema > Privacidad y Seguridad > Archivos y Carpetas."
            }
        }
        return found
    }

    // MARK: - Lee una carpeta real con FileManager
    private func scanFolder(_ path: String, category: String, privateFolders: [String], skipped: inout Int) -> [ScannedFile] {
        var result: [ScannedFile] = []
        let fm = FileManager.default

        guard let items = try? fm.contentsOfDirectory(atPath: path) else {
            return []
        }

        for item in items {
            let fullPath = (path as NSString).appendingPathComponent(item)

            // R03: Si este archivo/carpeta es privado, lo saltamos
            if isPrivate(fullPath, privateFolders: privateFolders) {
                skipped += 1
                continue
            }

            // R01: Nunca tocamos sistema
            if fullPath.contains("/System/") || fullPath.hasPrefix("/System") {
                continue
            }

            // Tamaño real
            let size = folderSize(fullPath)
            if size < 100_000 { continue } // Solo mostramos cosas > 1MB, lo chiquito no vale la pena

            let risk: RiskLevel = riskFor(path: fullPath, category: category)

            result.append(ScannedFile(
                name: item,
                path: fullPath,
                sizeBytes: size,
                category: category,
                risk: risk
            ))

            if result.count > 50 { break }
        }
        return result
    }

    // MARK: - Tamaño real de carpeta/archivo
    private func folderSize(_ path: String) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            return (try? fm.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
        }

        // Es carpeta: sumamos lo que hay adentro, pero sin bajar muy profundo para que no se trabe
        guard let items = try? fm.contentsOfDirectory(atPath: path) else { return 0 }
        var total: Int64 = 0
        for item in items.prefix(20) {
            let full = (path as NSString).appendingPathComponent(item)
            if let size = try? fm.attributesOfItem(atPath: full)[.size] as? Int64 {
                total += size
            }
        }
        return total
    }

    // MARK: - R01: Semáforo
    private func riskFor(path: String, category: String) -> RiskLevel {
        if path.contains("/System/") { return .rojo }
        if path.contains("DerivedData") || path.contains("CoreSimulator") { return .amarillo }
        if category == "Caché" { return .verde }
        return .verde
    }

    private func isPrivate(_ path: String, privateFolders: [String]) -> Bool {
        for folder in privateFolders {
            let expanded = (folder as NSString).expandingTildeInPath
            if path == expanded || path.hasPrefix(expanded + "/") { return true }
            if path.contains(folder) { return true }
        }
        return false
    }
}
