//
//  ScanControlsView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// Solo los botones de escanear. Recibe closures, no conoce ScannerEngine por dentro.
public struct ScanControlsView: View {
    var isScanning: Bool
    var isAnalyzing: Bool
    var canAnalyze: Bool
    var onScan: () -> Void
    var onAnalyze: () -> Void
    public init(isScanning: Bool, isAnalyzing: Bool, canAnalyze: Bool, onScan: @escaping () -> Void, onAnalyze: @escaping () -> Void) {
        self.isScanning = isScanning; self.isAnalyzing = isAnalyzing; self.canAnalyze = canAnalyze; self.onScan = onScan; self.onAnalyze = onAnalyze
    }
    public var body: some View {
        HStack(spacing: 12) {
            Button(action: onScan) {
                HStack(spacing: 6) {
                    if isScanning { ProgressView().scaleEffect(0.8).frame(width: 16, height: 16) } else { Image(systemName: "magnifyingglass") }
                    Text(isScanning ? "Escaneando..." : "Escanear toda mi Mac (R04)").lineLimit(1)
                }
            }
            .buttonStyle(.borderedProminent).controlSize(.large).disabled(isScanning)
            Button("Analizar con IA uno por uno", action: onAnalyze)
                .buttonStyle(.bordered).disabled(!canAnalyze || isAnalyzing)
            Spacer()
            Text("Sin botón Borrar Todo (R02)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}
