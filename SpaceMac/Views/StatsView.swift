//
//  StatsView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// Solo las stats. Recibe números, no sabe de dónde vienen.
public struct StatsView: View {
    var totalBytes: Int64
    var deletableBytes: Int64
    var fileCount: Int
    var blockedCount: Int
    var groupCount: Int
    var duplicatesWasted: Int64
    public init(totalBytes: Int64, deletableBytes: Int64, fileCount: Int, blockedCount: Int, groupCount: Int, duplicatesWasted: Int64) {
        self.totalBytes = totalBytes; self.deletableBytes = deletableBytes; self.fileCount = fileCount; self.blockedCount = blockedCount; self.groupCount = groupCount; self.duplicatesWasted = duplicatesWasted
    }
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "Total encontrado", value: formatBytes(totalBytes), icon: "internaldrive.fill", color: .blue)
                StatCard(title: "Puedes liberar", value: formatBytes(deletableBytes), icon: "trash.fill", color: .green)
                StatCard(title: "Archivos", value: "\(fileCount)", icon: "doc.fill", color: .orange)
                StatCard(title: "Bloqueados R01", value: "\(blockedCount)", icon: "shield.fill", color: .red)
            }
            HStack(spacing: 12) {
                StatCard(title: "Grupos duplicados", value: "\(groupCount)", icon: "doc.on.doc.fill", color: .purple)
                StatCard(title: "Desperdiciado en duplicados", value: formatBytes(duplicatesWasted), icon: "exclamationmark.triangle.fill", color: .yellow)
            }
        }
    }
    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}

public struct StatCard: View {
    var title: String; var value: String; var icon: String; var color: Color
    public init(title: String, value: String, icon: String, color: Color) { self.title = title; self.value = value; self.icon = icon; self.color = color }
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
            }
            Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color.gray.opacity(0.08)).cornerRadius(12)
    }
}
