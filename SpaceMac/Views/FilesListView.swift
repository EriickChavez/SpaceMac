//
//  FilesListView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI
import QuickLook

// FilesListView - V5 + Multiselector + Preview
// Misma firma que usa ContentView V5, solo se agregó onDeleteSelected

public struct FilesListView: View {
    var files: [ScannedFile]
        var totalFiles: Int
        var deletedMessage: String?
        var isAIReady: Bool
        var onDelete: (ScannedFile) -> Void
        var onDeleteSelected: ([ScannedFile]) -> Void
        var onShowDuplicates: () -> Void
        var hasDuplicates: Bool
        var duplicateCount: Int

    @State private var previewURL: URL? = nil
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteSelectedConfirm = false
    @State private var showSelectMode = false

    public init(
        files: [ScannedFile],
        totalFiles: Int,
        deletedMessage: String?,
        isAIReady: Bool = false,
        onDelete: @escaping (ScannedFile) -> Void,
        onDeleteSelected: @escaping ([ScannedFile]) -> Void = { _ in },
        onShowDuplicates: @escaping () -> Void,
        hasDuplicates: Bool,
        duplicateCount: Int
    ) {
        self.files = files
        self.totalFiles = totalFiles
        self.deletedMessage = deletedMessage
        self.isAIReady = isAIReady
        self.onDelete = onDelete
        self.onDeleteSelected = onDeleteSelected
        self.onShowDuplicates = onShowDuplicates
        self.hasDuplicates = hasDuplicates
        self.duplicateCount = duplicateCount
    }

    private var sorted: [ScannedFile] {
        files.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private var selectable: [ScannedFile] {
        sorted.filter { $0.risk != .rojo && !PremiumEngine.shared.isPrivate($0.path) }
    }

    private var selectedFiles: [ScannedFile] {
        sorted.filter { selectedIDs.contains($0.id) }
    }

    private var selectedBytes: Int64 {
        selectedFiles.map { $0.sizeBytes }.reduce(0, +)
    }

    private var isAllSelected: Bool {
        !selectable.isEmpty && selectable.allSatisfy { selectedIDs.contains($0.id) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Archivos encontrados")
                    .font(.headline)
                Text("(\(sorted.count) de \(totalFiles))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(showSelectMode ? "Cancelar selección" : "Seleccionar varios") {
                    showSelectMode.toggle()
                    if !showSelectMode {
                        selectedIDs.removeAll()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let deletedMessage {
                Text(deletedMessage)
                    .font(.caption)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(10)
            }

            if hasDuplicates {
                Button(action: onShowDuplicates) {
                    HStack {
                        Text("Tienes \(duplicateCount) grupos duplicados - Ver duplicados →")
                            .font(.caption.bold())
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            if showSelectMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Button(isAllSelected ? "Deseleccionar todo" : "Seleccionar todo lo visible") {
                            if isAllSelected {
                                selectedIDs.removeAll()
                            } else {
                                for f in selectable {
                                    selectedIDs.insert(f.id)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text("\(selectedIDs.count) seleccionados • \(formatBytes(selectedBytes))")
                            .font(.caption.bold())

                        Spacer()

                        if !selectedIDs.isEmpty {
                            Button("Limpiar") {
                                selectedIDs.removeAll()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    if !selectedIDs.isEmpty {
                        HStack {
                            Text("Vas a borrar \(selectedFiles.count) archivos que tú elegiste.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Borrar seleccionados (\(selectedFiles.count))") {
                                showDeleteSelectedConfirm = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(.red)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(10)
                    } else {
                        Text("Toca el checkbox de cada archivo. Los 🔴 No tocar y 🔒 Privados no se pueden seleccionar.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.06))
                .cornerRadius(12)
            }

            if sorted.isEmpty {
                VStack(spacing: 8) {
                    Text("Sin archivos. Dale a Escanear.")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sorted) { file in
                        HStack(spacing: 12) {
                            if showSelectMode {
                                Button {
                                    if canSelect(file) {
                                        toggle(file)
                                    }
                                } label: {
                                    Image(systemName: selectedIDs.contains(file.id) ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundStyle(selectedIDs.contains(file.id) ? .blue : .secondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canSelect(file))
                            } else {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(colorForRisk(file.risk))
                                        .frame(width: 12, height: 12)
                                    Text(labelForRisk(file.risk))
                                        .font(.caption2.bold())
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(file.name)
                                        .font(.body.bold())
                                        .lineLimit(1)
                                    if !canSelect(file) {
                                        Text(file.risk == .rojo ? "🔴 No tocar" : "🔒 Privado")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(file.path)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(file.category)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .cornerRadius(6)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(formatBytes(file.sizeBytes))
                                    .font(.caption.bold())
                                HStack(spacing: 6) {
                                    Button {
                                        openPreview(file)
                                    } label: {
                                        Label("Ver", systemImage: "eye.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)

                                    if file.risk == .rojo {
                                        Text("Bloqueado")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.red)
                                    } else if !showSelectMode {
                                        Button("Borrar") {
                                            onDelete(file)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedIDs.contains(file.id) ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
                        .cornerRadius(10)
                        .onTapGesture {
                            if showSelectMode && canSelect(file) {
                                toggle(file)
                            }
                        }
                    }
                }
            }
        }
        .quickLookPreview($previewURL)
        .alert("¿Borrar \(selectedFiles.count) archivos?", isPresented: $showDeleteSelectedConfirm) {
            Button("Borrar \(selectedFiles.count) - Mandar a Papelera", role: .destructive) {
                onDeleteSelected(selectedFiles)
                selectedIDs.removeAll()
                showSelectMode = false
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrarán \(selectedFiles.count) archivos que tú seleccionaste.\nTotal: \(formatBytes(selectedBytes))\nSe mandan a Papelera.\nLos del sistema y Privados nunca se seleccionan.")
        }
        .onChange(of: files.count) { _, _ in
            selectedIDs = selectedIDs.intersection(Set(files.map { $0.id }))
        }
    }

    private func canSelect(_ file: ScannedFile) -> Bool {
        file.risk != .rojo && !PremiumEngine.shared.isPrivate(file.path)
    }

    private func toggle(_ file: ScannedFile) {
        if selectedIDs.contains(file.id) {
            selectedIDs.remove(file.id)
        } else {
            selectedIDs.insert(file.id)
        }
    }

    private func openPreview(_ file: ScannedFile) {
        let expanded = (file.path as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expanded) {
            previewURL = URL(fileURLWithPath: expanded)
        }
    }

    private func colorForRisk(_ risk: RiskLevel) -> Color {
        switch risk {
        case .verde:
            return .green
        case .amarillo:
            return .yellow
        case .rojo:
            return .red
        }
    }

    private func labelForRisk(_ risk: RiskLevel) -> String {
        switch risk {
        case .verde:
            if isAIReady {
                return "Seguro por IA"
            } else {
                return "Seguro por regla"
            }
        case .amarillo:
            if isAIReady {
                return "Revisar con IA"
            } else {
                return "Revisar - Sin IA"
            }
        case .rojo:
            return "No tocar"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
