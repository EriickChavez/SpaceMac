//
//  AntSpaceView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// AntSpaceView - Espacio Hormiga 🐜
// Muestra carpetas con miles de archivos chiquitos que juntos son gigas.
// No borra carpetas enteras, solo entras y borras archivo por archivo.

public struct AntSpaceView: View {
    @ObservedObject var antEngine: AntSpaceEngine
    var onAnalyze: () -> Void
    var onOpenFolder: (AntFolder) -> Void

    public init(
        antEngine: AntSpaceEngine,
        onAnalyze: @escaping () -> Void,
        onOpenFolder: @escaping (AntFolder) -> Void
    ) {
        self.antEngine = antEngine
        self.onAnalyze = onAnalyze
        self.onOpenFolder = onOpenFolder
    }

    private var antFolders: [AntFolder] {
        antEngine.folders.filter { $0.isAntSpace }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🐜 Espacio Hormiga")
                    .font(.headline)

                Spacer()

                if antEngine.isAnalyzing {
                    Button("Cancelar") {
                        antEngine.cancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                } else {
                    Button("Analizar Espacio Hormiga") {
                        onAnalyze()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            Text("Miles de archivos chiquitos que juntos son gigas. Entra a cada carpeta y borra archivo por archivo, nunca la carpeta entera.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if antEngine.isAnalyzing {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analizando...")
                            .font(.caption.bold())
                    }

                    if !antEngine.currentFolderName.isEmpty {
                        Text("Revisando: \(antEngine.currentFolderName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(antEngine.progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
            }

            if !antEngine.folders.isEmpty {
                HStack(spacing: 16) {
                    Label("\(antEngine.totalAntFiles) archivos hormiga", systemImage: "doc.fill")
                        .font(.caption.bold())

                    Label(formatBytes(antEngine.totalAntBytes), systemImage: "scalemass.fill")
                        .font(.caption.bold())

                    Spacer()

                    Text("\(antFolders.count) carpetas hormiga")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
            }

            if !antEngine.progressText.isEmpty && !antEngine.isAnalyzing {
                Text(antEngine.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if antEngine.folders.isEmpty && !antEngine.isAnalyzing {
                VStack(spacing: 8) {
                    Text("Sin análisis todavía.")
                        .font(.body)
                    Text("Dale a Analizar para ver tus carpetas hormiga.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(antEngine.folders) { folder in
                        Button {
                            onOpenFolder(folder)
                        } label: {
                            HStack(spacing: 12) {
                                Text("🐜")
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(folder.name)
                                            .font(.body.bold())
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)

                                        if folder.isAntSpace {
                                            Text("HORMIGA")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(6)
                                                .foregroundStyle(.orange)
                                        }
                                    }

                                    Text(folder.path)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    HStack(spacing: 12) {
                                        Text("\(folder.fileCount) archivos")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text("Promedio: \(formatBytes(folder.avgFileSize)) por archivo")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(formatBytes(folder.totalBytes))
                                        .font(.caption.bold())
                                        .foregroundStyle(.primary)

                                    Text("Entrar →")
                                        .font(.caption.bold())
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
