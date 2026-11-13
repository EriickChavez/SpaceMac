//
//  DuplicatesView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// DuplicatesView - V5 + Multiselector
// Misma firma que usa ContentView V5, solo se agregó onDeleteSelected

public struct DuplicatesView: View {
    @ObservedObject var duplicateEngine: DuplicateEngine
    var onSearch: () -> Void
    var onDelete: (ScannedFile) -> Void
    var onDeleteSelected: ([ScannedFile]) -> Void
    var onBack: () -> Void
    var canSearch: Bool

    @State private var selectedIDs: Set<UUID> = []
    @State private var showConfirm = false

    public init(
        duplicateEngine: DuplicateEngine,
        onSearch: @escaping () -> Void,
        onDelete: @escaping (ScannedFile) -> Void,
        onDeleteSelected: @escaping ([ScannedFile]) -> Void = { _ in },
        onBack: @escaping () -> Void,
        canSearch: Bool
    ) {
        self.duplicateEngine = duplicateEngine
        self.onSearch = onSearch
        self.onDelete = onDelete
        self.onDeleteSelected = onDeleteSelected
        self.onBack = onBack
        self.canSearch = canSearch
    }

    private var allFiles: [ScannedFile] {
        duplicateEngine.groups.flatMap { $0.files }
    }

    private var selectedFiles: [ScannedFile] {
        allFiles.filter { selectedIDs.contains($0.id) }
    }

    private var selectedBytes: Int64 {
        selectedFiles.map { $0.sizeBytes }.reduce(0, +)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📄 Duplicados Inteligentes")
                    .font(.headline)
                Spacer()
                Button("← Volver", action: onBack)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Text("Nunca borramos el original. El primer archivo de cada grupo es el original, no se puede seleccionar. Solo las copias.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if duplicateEngine.groups.isEmpty {
                VStack(spacing: 8) {
                    Text("Sin duplicados todavía.")
                        .font(.body)
                    Button("Buscar duplicados") {
                        onSearch()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSearch)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
            } else {
                HStack(spacing: 10) {
                    Text("\(selectedIDs.count) copias seleccionadas • \(formatBytes(selectedBytes))")
                        .font(.caption.bold())
                    Spacer()
                    if !selectedIDs.isEmpty {
                        Button("Borrar copias seleccionadas (\(selectedIDs.count))") {
                            showConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                }

                ForEach(duplicateEngine.groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Desperdicio: \(formatBytes(group.wastedBytes))")
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                            Spacer()
                            Text("\(group.files.count) archivos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                            let isOriginal = index == 0

                            HStack(spacing: 10) {
                                if isOriginal {
                                    Text("✅")
                                        .font(.title3)
                                } else {
                                    Button {
                                        toggle(file)
                                    } label: {
                                        Image(systemName: selectedIDs.contains(file.id) ? "checkmark.square.fill" : "square")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(file.name)
                                            .font(.body.bold())
                                            .lineLimit(1)
                                        if isOriginal {
                                            Text("ORIGINAL - No se borra")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    Text(file.path)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                Text(formatBytes(file.sizeBytes))
                                    .font(.caption.bold())

                                if !isOriginal {
                                    Button("Borrar") {
                                        onDelete(file)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(10)
                            .background(
                                isOriginal
                                    ? Color.green.opacity(0.06)
                                    : (selectedIDs.contains(file.id) ? Color.blue.opacity(0.08) : Color.purple.opacity(0.06))
                            )
                            .cornerRadius(8)
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .alert("¿Borrar \(selectedIDs.count) copias?", isPresented: $showConfirm) {
            Button("Borrar copias", role: .destructive) {
                onDeleteSelected(selectedFiles)
                selectedIDs.removeAll()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Solo se borran las copias que seleccionaste. El original nunca se toca.\nTotal: \(formatBytes(selectedBytes))")
        }
    }

    private func toggle(_ file: ScannedFile) {
        if selectedIDs.contains(file.id) {
            selectedIDs.remove(file.id)
        } else {
            selectedIDs.insert(file.id)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
