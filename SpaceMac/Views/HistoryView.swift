//
//  HistoryView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// R10 Historial + R11 Aviso - Vista modular, partida en piezas
public struct HistoryView: View {
    @ObservedObject var history: HistoryEngine
    var freeBytes: Int64
    var onBack: () -> Void

    public init(history: HistoryEngine, freeBytes: Int64, onBack: @escaping () -> Void) {
        self.history = history
        self.freeBytes = freeBytes
        self.onBack = onBack
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerPart
            lowSpacePart
            statsPart
            listPart
            backPart
        }
    }

    private var headerPart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Historial (R10)")
                .font(.title2.bold())
                .lineLimit(1)
            Text("Todo lo que has liberado, con fecha y tamaño. Nada se borra sin tu permiso.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var lowSpacePart: some View {
        if history.shouldAlertLowSpace(freeBytes: freeBytes) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Te queda poco espacio (R11)")
                        .font(.headline)
                    Text("Te quedan \(formatBytes(freeBytes)) libres. ¿Quieres limpiar ahora?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Entendido") {
                    history.markLowSpaceAlerted()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(12)
        }
    }

    private var statsPart: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total liberado", value: formatBytes(history.totalFreed), icon: "trash.fill", color: .green)
            StatCard(title: "Hoy", value: formatBytes(history.freedToday), icon: "sun.max.fill", color: .orange)
            StatCard(title: "Esta semana", value: formatBytes(history.freedThisWeek), icon: "calendar", color: .blue)
            StatCard(title: "Archivos borrados", value: "\(history.entries.count)", icon: "doc.fill", color: .purple)
        }
    }

    @ViewBuilder
    private var listPart: some View {
        if history.entries.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Aún no has borrado nada")
                    .font(.headline)
                Text("Cuando borres tu primer archivo, aquí va a aparecer con fecha y tamaño.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(12)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(history.entries) { entry in
                    HistoryRow(entry: entry)
                }
            }
        }
    }

    private var backPart: some View {
        Button("← Volver a Resumen", action: onBack)
            .buttonStyle(.bordered)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}

public struct HistoryRow: View {
    var entry: HistoryEntry
    public init(entry: HistoryEntry) { self.entry = entry }
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fileName)
                    .font(.body.bold())
                    .lineLimit(1)
                Text(entry.filePath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatBytes(entry.sizeBytes))
                    .font(.caption.bold())
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter(); f.countStyle = .file; return f.string(fromByteCount: bytes)
    }
}
