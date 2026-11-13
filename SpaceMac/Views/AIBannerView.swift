//
//  AIBannerView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// AIBannerView - R07 IA integrada, gratis, on-device, offline
// Muestra si la IA ya está lista o si falta descargarla.
// No pide API key, no pide cuenta, no pide suscripción.

public struct AIBannerView: View {
    @ObservedObject var downloader: ModelDownloader
    @ObservedObject var aiService: EmbeddedAIService

    public init(
        downloader: ModelDownloader,
        aiService: EmbeddedAIService
    ) {
        self.downloader = downloader
        self.aiService = aiService
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("🤖")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    if downloader.isModelReady {
                        Text("IA lista - Gratis, en tu Mac, sin internet")
                            .font(.body.bold())
                    } else {
                        Text("IA no descargada todavía")
                            .font(.body.bold())
                    }

                    if downloader.isModelReady {
                        Text("La IA te ayuda a decidir en los archivos amarillos. Los rojos nunca se tocan, por R01.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Descarga el modelo de ~1GB una sola vez. Sin API key, sin cuenta, sin suscripción. Mientras tanto SpaceMac usa reglas R01.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }

            if downloader.isDownloading {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: downloader.progress) {
                        Text("Descargando modelo...")
                            .font(.caption.bold())
                    }

                    Text(downloader.progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button("Pausar") {
                            downloader.pause()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Reanudar") {
                            downloader.resume()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("Cancelar") {
                            downloader.cancel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
            } else {
                if !downloader.isModelReady {
                    Button("Descargar IA gratis (~1GB)") {
                        downloader.download()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    HStack(spacing: 8) {
                        Text("✅ Modelo descargado")
                            .font(.caption.bold())
                            .foregroundStyle(.green)

                        if aiService.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Analizando...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let errorMessage = downloader.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            downloader.isModelReady
                ? Color.green.opacity(0.08)
                : Color.blue.opacity(0.06)
        )
        .cornerRadius(12)
    }
}
