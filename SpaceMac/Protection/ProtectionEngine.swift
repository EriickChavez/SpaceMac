//
//  ProtectionEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation

// R01 - PROHIBIDO dañar sistema o apps.
// R02 - Sin botón Borrar Todo.
// R03 - Carpetas Privadas nunca se tocan.

public enum RiskLevel: String, Codable {
    case verde     // Seguro borrar, ejemplo: Caches, Logs
    case amarillo  // Revisar con IA, ejemplo: Descargas grandes
    case rojo      // PROHIBIDO borrar, ejemplo: Sistema, Apps, Privadas
}

public struct ScannedFile: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let path: String
    public let sizeBytes: Int64
    public let category: String
    public var risk: RiskLevel

    public init(name: String, path: String, sizeBytes: Int64, category: String, risk: RiskLevel) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.category = category
        self.risk = risk
    }
}

public final class ProtectionEngine {
    public static let shared = ProtectionEngine()
    private init() {}

    // R03 - Carpetas Privadas (Premium)
    // El usuario las agrega en Ajustes. Todo lo que esté aquí es ROJO siempre.
    public var privateFolders: [String] = []

    // R01 - Lista Negra del Sistema. NUNCA tocar.
    private let systemBlacklist = [
        "/System",
        "/private",
        "/bin",
        "/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/Library/Apple",
        "/System/Library",
        "/cores"
    ]

    // R01 - Lista Negra de Apps. NUNCA borrar una app.
    private let appBlacklist = [
        "/Applications",
        "Application Support",
        ".app",
        "Containers/com.apple"
    ]

    // Esta función decide el color de cada archivo.
    public func risk(for path: String) -> RiskLevel {
        // 1. Si es carpeta privada -> ROJO, sin discusión
        if privateFolders.contains(where: { path.hasPrefix($0) }) {
            return .rojo
        }
        // 2. Si es sistema -> ROJO
        if systemBlacklist.contains(where: { path.hasPrefix($0) }) {
            return .rojo
        }
        // 3. Si es una app -> ROJO
        if appBlacklist.contains(where: { path.contains($0) }) {
            return .rojo
        }
        // 4. Si es caché o log -> VERDE
        if path.contains("Caches") || path.contains("Logs") || path.hasSuffix(".log") {
            return .verde
        }
        // 5. Si no estamos 100% seguros -> AMARILLO, que lo revise la IA
        return .amarillo
    }

    public func canDelete(_ file: ScannedFile) -> Bool {
        return file.risk != .rojo
    }

    // R02 - NO EXISTE deleteAll(). Solo deleteOne().
    // Así cumplimos por código que nunca haya botón Borrar Todo.
    public func deleteOne(_ file: ScannedFile) throws {
        guard canDelete(file) else {
            throw NSError(
                domain: "SpaceMac",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Bloqueado por R01: Este archivo es de sistema, de una app o de una carpeta privada."]
            )
        }
        // Solo se manda a Papelera, no borrado permanente.
        try FileManager.default.trashItem(
            at: URL(fileURLWithPath: file.path),
            resultingItemURL: nil
        )
    }
}
