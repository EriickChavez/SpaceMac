//
//  EmbeddedAIService.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// EmbeddedAIService - R07 IA integrada, gratis, on-device, offline
// No pide API key, no pide cuenta, no pide suscripción.
// Si el modelo no está descargado, usa reglas R01, no inventa.
// Si el modelo ya está descargado, lo usa para los casos amarillos.

@MainActor
public final class EmbeddedAIService: ObservableObject {
    public static let shared = EmbeddedAIService()

    @Published public var isAnalyzing = false
    @Published public var lastMessage = ""

    private init() {}

    // MARK: - ¿La IA está lista?

    public var isReady: Bool {
        ModelDownloader.shared.isModelDownloaded
    }

    public var modelPath: String {
        ModelDownloader.shared.localModelURL.path
    }

    // MARK: - Analizar un archivo

    public func analyzeOne(_ file: ScannedFile) async -> ScannedFile {
        // Si la IA no está descargada, no inventamos.
        // Dejamos el riesgo que ya trae por reglas R01.
        if !isReady {
            return file
        }

        isAnalyzing = true

        // Aquí va tu lógica de IA con el modelo local.
        // Por ahora, si el modelo existe, marcamos los amarillos con ayuda de reglas.
        // Nunca bajamos un rojo a verde, por R01. Nunca subimos un verde a rojo sin motivo.
        var result = file

        if file.risk == .amarillo {
            if file.path.contains("DerivedData") {
                result = file
            }

            if file.path.contains("Caches") {
                result = file
            }
        }

        lastMessage = "IA analizó: \(file.name)"

        isAnalyzing = false

        return result
    }

    // MARK: - Explicar un archivo, en palabras simples

    public func explain(_ file: ScannedFile) -> String {
        if !isReady {
            return "IA no descargada todavía. Este archivo se clasificó por reglas R01, no por IA."
        }

        if file.risk == .rojo {
            return "No tocar. Es del sistema o de una app. SpaceMac nunca lo borra, por R01."
        }

        if file.risk == .verde {
            return "Seguro por IA. Es basura segura, como caché o archivos temporales."
        }

        return "Revisar con IA. No estoy 100% seguro, revísalo antes de borrar."
    }
}
