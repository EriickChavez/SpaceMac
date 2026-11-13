//
//  ModelDownloader.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// ModelDownloader - R07 IA integrada, gratis, on-device, offline
// Opción A: La app descarga el modelo de ~1GB la primera vez que lo usas.
// Se guarda en Application Support, con progreso, pausa y resume.
// No pide API key, no pide cuenta, no pide suscripción.

@MainActor
public final class ModelDownloader: ObservableObject {
    public static let shared = ModelDownloader()

    @Published public var isDownloading = false
    @Published public var progress: Double = 0
    @Published public var progressText = ""
    @Published public var errorMessage: String? = nil

    // MARK: - Lo que pide ContentView

    // True si el modelo ya está descargado en tu Mac
    @Published public var isDownloaded = false

    // True si ya puedes usar la IA
    public var isAIReady: Bool {
        isDownloaded
    }

    private var downloadTask: URLSessionDownloadTask? = nil
    private var isPaused = false

    private init() {}

    // MARK: - Rutas

    private var modelFolder: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let folder = appSupport.appendingPathComponent("SpaceMac")
        return folder
    }

    private var modelURL: URL {
        modelFolder.appendingPathComponent("qwen2.5-1.5b.gguf")
    }

    // MARK: - Alias que piden EmbeddedAIService y AIBannerView

    // EmbeddedAIService pide `localModelURL`
    // Es lo mismo que `modelURL`, solo que público
    public var localModelURL: URL {
        modelURL
    }

    // EmbeddedAIService pide `isModelDownloaded`
    // Es lo mismo que `isDownloaded`, solo que con otro nombre
    public var isModelDownloaded: Bool {
        isDownloaded
    }

    // AIBannerView pide `isModelReady`
    // Es lo mismo que `isDownloaded`, solo que con otro nombre
    public var isModelReady: Bool {
        isDownloaded
    }

    // MARK: - Al abrir la app

    public func checkOnLaunch() {
        let fm = FileManager.default

        if fm.fileExists(atPath: modelURL.path) {
            isDownloaded = true
            progress = 1
            progressText = "IA lista - Modelo descargado"
        } else {
            isDownloaded = false
            progress = 0
            progressText = "IA no descargada todavía"
        }
    }

    // MARK: - Descargar

    public func download() {
        if isDownloaded {
            return
        }

        if isDownloading {
            return
        }

        isDownloading = true
        isPaused = false
        errorMessage = nil
        progressText = "Descargando modelo de IA..."

        let fm = FileManager.default

        do {
            try fm.createDirectory(
                at: modelFolder,
                withIntermediateDirectories: true
            )
        } catch {
            errorMessage = "No se pudo crear la carpeta: \(error.localizedDescription)"
            isDownloading = false
            return
        }

        // URL del modelo, ~1GB
        guard let url = URL(string: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf") else {
            errorMessage = "URL del modelo inválida"
            isDownloading = false
            return
        }

        // FIX Swift 6: No agarramos `self` dentro del closure de URLSession.
        // Guardamos lo que necesitamos en variables locales, que sí son Sendable.
        // Adentro solo usamos ModelDownloader.shared, ya en MainActor.
        let targetURL = modelURL

        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            Task { @MainActor in
                let downloader = ModelDownloader.shared

                downloader.isDownloading = false

                if let error = error {
                    downloader.errorMessage = "Error al descargar: \(error.localizedDescription)"
                    return
                }

                guard let tempURL = tempURL else {
                    downloader.errorMessage = "No se descargó ningún archivo"
                    return
                }

                do {
                    let fm = FileManager.default

                    if fm.fileExists(atPath: targetURL.path) {
                        try fm.removeItem(at: targetURL)
                    }

                    try fm.moveItem(at: tempURL, to: targetURL)

                    downloader.isDownloaded = true
                    downloader.progress = 1
                    downloader.progressText = "IA lista - Modelo descargado"
                } catch {
                    downloader.errorMessage = "No se pudo guardar el modelo: \(error.localizedDescription)"
                }
            }
        }

        downloadTask = task
        task.resume()
    }

    public func pause() {
        downloadTask?.suspend()
        isPaused = true
        progressText = "Descarga pausada"
    }

    public func resume() {
        downloadTask?.resume()
        isPaused = false
        progressText = "Descargando modelo de IA..."
    }

    public func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        isPaused = false
        progress = 0
        progressText = "Descarga cancelada"
    }
}
