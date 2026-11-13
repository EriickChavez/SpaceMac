//
//  FileRowView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// Solo UNA fila. Si quieres cambiar cómo se ve un archivo, solo aquí.
public struct FileRowView: View {
    var file: ScannedFile
    var onDelete: (ScannedFile) -> Void
    public init(file: ScannedFile, onDelete: @escaping (ScannedFile) -> Void) { self.file = file; self.onDelete = onDelete }
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(colorForRisk(file.risk)).frame(width: 12, height: 12).padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name).font(.body.bold()).lineLimit(1)
                Text(file.path).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                HStack(spacing: 8) {
                    Text(formatBytes(file.sizeBytes)).font(.caption.bold()).lineLimit(1)
                    Text("• \(file.category)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Text("• \(file.risk.rawValue.uppercased())").font(.caption.bold()).foregroundStyle(colorForRisk(file.risk)).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 6) {
                if file.risk == .rojo {
                    HStack(spacing: 4) { Image(systemName: "lock.fill").font(.caption2); Text("Bloqueado R01").font(.caption.bold()).lineLimit(1) }.foregroundStyle(.red)
                    Text("Sistema / App / Privada").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    Button("Borrar este archivo") { onDelete(file) }.buttonStyle(.bordered).controlSize(.small)
                    Text("Se manda a Papelera").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(width: 150, alignment: .trailing)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color.gray.opacity(0.05)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.12), lineWidth: 1))
    }
    private func colorForRisk(_ risk: RiskLevel) -> Color {
        switch risk { case .verde: return .green; case .amarillo: return .yellow; case .rojo: return .red }
    }
    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}
