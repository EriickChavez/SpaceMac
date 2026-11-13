//
//  RoutesView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// RoutesView - V5 + Multiselector

public struct RoutesView: View {
    var allFiles: [ScannedFile]
    var onDelete: (ScannedFile) -> Void
    var onDeleteSelected: ([ScannedFile]) -> Void

    @State private var selectedProfile: String = "Dev Web + Mobile"
    @State private var selectedIDs: Set<UUID> = []
    @State private var showConfirm = false

    public init(
        allFiles: [ScannedFile],
        onDelete: @escaping (ScannedFile) -> Void,
        onDeleteSelected: @escaping ([ScannedFile]) -> Void = { _ in }
    ) {
        self.allFiles = allFiles
        self.onDelete = onDelete
        self.onDeleteSelected = onDeleteSelected
    }

    private var routeFiles: [ScannedFile] {
        switch selectedProfile {
        case "Dev Web + Mobile":
            return allFiles.filter { $0.path.contains("DerivedData") || $0.path.contains("node_modules") || $0.category == "Caché" }
        case "Diseñador":
            return allFiles.filter { $0.category == "Caché" }
        default:
            return allFiles
        }
    }

    private var selectedFiles: [ScannedFile] {
        routeFiles.filter { selectedIDs.contains($0.id) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🗺️ Rutas por Perfil")
                .font(.headline)
            Text("Todos pueden usar todas las rutas, esto solo es para guiarte.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Perfil", selection: $selectedProfile) {
                Text("Dev Web + Mobile").tag("Dev Web + Mobile")
                Text("Diseñador").tag("Diseñador")
                Text("Todos").tag("Todos")
            }
            .pickerStyle(.segmented)

            Text("\(routeFiles.count) archivos en esta ruta")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !selectedIDs.isEmpty {
                Button("Borrar seleccionados (\(selectedIDs.count))") {
                    showConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }

            ForEach(routeFiles.prefix(100)) { file in
                HStack(spacing: 10) {
                    if file.risk != .rojo {
                        Button {
                            toggle(file)
                        } label: {
                            Image(systemName: selectedIDs.contains(file.id) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.body)
                            .lineLimit(1)
                        Text(file.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(formatBytes(file.sizeBytes))
                        .font(.caption.bold())

                    if file.risk != .rojo {
                        Button("Borrar") {
                            onDelete(file)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(10)
                .background(selectedIDs.contains(file.id) ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .alert("¿Borrar \(selectedIDs.count) archivos?", isPresented: $showConfirm) {
            Button("Borrar", role: .destructive) {
                onDeleteSelected(selectedFiles)
                selectedIDs.removeAll()
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

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
