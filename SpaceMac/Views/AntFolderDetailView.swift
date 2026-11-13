//
//  AntFolderDetailView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI
import QuickLook

// AntFolderDetailView - V5 + Multiselector + Preview

public struct AntFolderDetailView: View {
    var folder: AntFolder
    var onDeleteOne: (ScannedFile) -> Void
    var onDeleteSelected: ([ScannedFile]) -> Void
    var onBack: () -> Void

    @State private var files: [ScannedFile] = []
    @State private var isLoading = true
    @State private var loadedCount = 0
    @State private var query = ""
    @State private var previewURL: URL? = nil
    @State private var selectedIDs: Set<UUID> = []
    @State private var showSelectMode = false
    @State private var showConfirm = false

    public init(
        folder: AntFolder,
        onDeleteOne: @escaping (ScannedFile) -> Void,
        onDeleteSelected: @escaping ([ScannedFile]) -> Void = { _ in },
        onBack: @escaping () -> Void
    ) {
        self.folder = folder
        self.onDeleteOne = onDeleteOne
        self.onDeleteSelected = onDeleteSelected
        self.onBack = onBack
    }

    private var filtered: [ScannedFile] {
        var list = files
        if !query.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return list.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private var selectedFiles: [ScannedFile] {
        filtered.filter { selectedIDs.contains($0.id) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("🐜")
                        .font(.title2)
                    Text(folder.name)
                        .font(.title2.bold())
                        .lineLimit(1)
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
                Text(folder.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 12) {
                    Label("\(folder.fileCount) archivos", systemImage: "doc.fill")
                        .font(.caption.bold())
                    Label(formatBytes(folder.totalBytes), systemImage: "scalemass.fill")
                        .font(.caption.bold())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)

            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Cargando... \(loadedCount) / \(folder.fileCount)")
                        .font(.caption.bold())
                }
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar en esta carpeta...", text: $query)
                    .textFieldStyle(.roundedBorder)
            }

            if showSelectMode && !selectedIDs.isEmpty {
                HStack {
                    Text("\(selectedIDs.count) seleccionados")
                        .font(.caption.bold())
                    Spacer()
                    Button("Borrar seleccionados (\(selectedIDs.count))") {
                        showConfirm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(filtered.prefix(200)) { file in
                    HStack(spacing: 10) {
                        if showSelectMode {
                            Button {
                                toggle(file)
                            } label: {
                                Image(systemName: selectedIDs.contains(file.id) ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            .disabled(file.risk == .rojo)
                        } else {
                            Circle()
                                .fill(colorForRisk(file.risk))
                                .frame(width: 10, height: 10)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.name)
                                .font(.body)
                                .lineLimit(1)
                            Text(file.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
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
                                        handleDeleteOne(file)
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
                }
            }

            Button("← Volver a Espacio Hormiga", action: onBack)
                .buttonStyle(.bordered)
        }
        .onAppear {
            Task {
                await loadFiles()
            }
        }
        .quickLookPreview($previewURL)
        .alert("¿Borrar \(selectedFiles.count) archivos?", isPresented: $showConfirm) {
            Button("Borrar", role: .destructive) {
                let toDelete = selectedFiles
                for file in toDelete {
                    files.removeAll { $0.id == file.id }
                }
                selectedIDs.removeAll()
                showSelectMode = false
                onDeleteSelected(toDelete)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Solo los que seleccionaste. Se mandan a Papelera.")
        }
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

    private func handleDeleteOne(_ file: ScannedFile) {
        files.removeAll { $0.id == file.id }
        onDeleteOne(file)
    }

    private func loadFiles() async {
        await MainActor.run {
            isLoading = true
            loadedCount = 0
        }

        let fm = FileManager.default

        // FIX: No usamos enumerator, porque en async da error de makeIterator.
        // Usamos subpathsOfDirectory, que regresa un [String] normal.
        let subpaths = (try? fm.subpathsOfDirectory(atPath: folder.path)) ?? []

        var result: [ScannedFile] = []
        var count = 0

        for relative in subpaths {
            let full = (folder.path as NSString).appendingPathComponent(relative)

            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: full, isDirectory: &isDir) else {
                continue
            }

            if isDir.boolValue {
                continue
            }

            let size = (try? fm.attributesOfItem(atPath: full)[.size] as? Int64) ?? 0

            result.append(
                ScannedFile(
                    name: (full as NSString).lastPathComponent,
                    path: full,
                    sizeBytes: size,
                    category: folder.category,
                    risk: folder.risk
                )
            )

            count += 1

            if count % 200 == 0 {
                let snapshot = result
                let current = count
                await MainActor.run {
                    self.files = snapshot
                    self.loadedCount = current
                }
                try? await Task.sleep(nanoseconds: 1_000_000)
            }

            if count > 5000 {
                break
            }
        }

        await MainActor.run {
            self.files = result
            self.loadedCount = result.count
            self.isLoading = false
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

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
