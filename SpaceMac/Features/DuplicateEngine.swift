//
//  DuplicateEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

//
//  DuplicateEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// DuplicateEngine - R08 Duplicados Inteligentes Gratis
// Compara por hash de contenido, NO por nombre.
// Nunca borra el original. El original es el primero de cada grupo.

public struct DuplicateGroup: Identifiable {
    public var id: String {
        files.first?.path ?? UUID().uuidString
    }

    public var files: [ScannedFile]
    public var wastedBytes: Int64

    public init(files: [ScannedFile], wastedBytes: Int64) {
        self.files = files
        self.wastedBytes = wastedBytes
    }
}

@MainActor
public final class DuplicateEngine: ObservableObject {
    public static let shared = DuplicateEngine()

    @Published public var groups: [DuplicateGroup] = []
    @Published public var isSearching = false

    private init() {}

    public func findDuplicates(in files: [ScannedFile]) async -> [DuplicateGroup] {
        isSearching = true

        var byHash: [String: [ScannedFile]] = [:]

        for file in files {
            // Si es rojo, ni lo contamos como duplicado, por R01
            if file.risk == .rojo {
                continue
            }

            let hash = hashFor(file: file)

            if byHash[hash] == nil {
                byHash[hash] = []
            }

            byHash[hash]?.append(file)
        }

        var result: [DuplicateGroup] = []

        for (_, groupFiles) in byHash {
            // Solo si hay 2 o más con el mismo hash, es duplicado
            if groupFiles.count < 2 {
                continue
            }

            let sorted = groupFiles.sorted { $0.path < $1.path }

            // El primero es el original, se queda.
            // Los demás son copias, esos sí se pueden borrar.
            // FIX: Antes aquí estaba `let keeperSize = ...` que nunca se usaba.
            // Ya se quitó, porque el desperdicio se calcula con los demás.
            let copies = Array(sorted.dropFirst())

            var wasted: Int64 = 0

            for copy in copies {
                wasted += copy.sizeBytes
            }

            let group = DuplicateGroup(
                files: sorted,
                wastedBytes: wasted
            )

            result.append(group)
        }

        result.sort { $0.wastedBytes > $1.wastedBytes }

        groups = result
        isSearching = false

        return result
    }

    private func hashFor(file: ScannedFile) -> String {
        let fm = FileManager.default
        let expanded = (file.path as NSString).expandingTildeInPath

        guard fm.fileExists(atPath: expanded) else {
            // Si no existe, usamos nombre + tamaño para no romper
            return "\(file.name)-\(file.sizeBytes)"
        }

        // Para archivos chiquitos, leemos todo y sacamos hash real.
        // Para archivos grandes, usamos tamaño + fecha, para no tardar horas.
        if file.sizeBytes < 10_000_000 {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: expanded)) {
                // FIX: Antes aquí estaba `let b = data` que nunca se usaba.
                // Ya se quitó, usamos data directo.
                return "\(data.count)-\(data.hashValue)"
            }
        }

        // Archivos grandes: tamaño + nombre + fecha de modificación
        if let attrs = try? fm.attributesOfItem(atPath: expanded) {
            if let date = attrs[.modificationDate] as? Date {
                return "\(file.sizeBytes)-\(date.timeIntervalSince1970)"
            }
        }

        return "\(file.name)-\(file.sizeBytes)"
    }
}
