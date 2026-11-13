//
//  PrivateFoldersView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// R03 Carpetas Privadas + R12 Flags + R15 Premium - Vista modular
public struct PrivateFoldersView: View {
    @ObservedObject var premium: PremiumEngine
    @State private var newPath: String = ""
    @State private var message: String? = nil

    public init(premium: PremiumEngine) { self.premium = premium }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerPart
            premiumCardPart
            addPart
            listPart
            flagsPart
        }
    }

    private var headerPart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Carpetas Privadas (R03)")
                .font(.title2.bold())
                .lineLimit(1)
            Text("Carpetas que SpaceMac NUNCA tocará. Ni escanear, ni borrar, ni analizar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var premiumCardPart: some View {
        HStack(spacing: 12) {
            Image(systemName: premium.isPremium ? "crown.fill" : "lock.fill")
                .font(.title2)
                .foregroundStyle(premium.isPremium ? .yellow : .blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(premium.isPremium ? "Eres Premium" : "Eres Gratis - Todo gratis, excepto esto")
                    .font(.headline)
                Text(premium.privateFolderMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(premium.isPremium ? "Simular Gratis" : "Simular Premium") {
                premium.togglePremiumForTesting()
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }

    private var addPart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("/Users/tu-usuario/Proyectos", text: $newPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.monospaced())
                Button("Agregar") {
                    let path = newPath.trimmingCharacters(in: .whitespaces)
                    if path.isEmpty { return }
                    if premium.addPrivateFolder(path) {
                        message = "Agregada: \(path) - SpaceMac nunca la tocará"
                        newPath = ""
                    } else {
                        message = "No se pudo. Ya usaste tu 1 gratis. Premium = ilimitadas."
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newPath.isEmpty || !premium.canAddPrivateFolder)
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Ejemplos: /Users/tu-usuario/Documents/Trabajo - /Users/tu-usuario/Proyectos")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var listPart: some View {
        if premium.privateFolders.isEmpty {
            Text("No tienes carpetas privadas todavía. Agrega una y SpaceMac la respetará siempre.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(premium.privateFolders, id: \.self) { folder in
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text(folder)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Quitar") {
                            premium.removePrivateFolder(folder)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
    }

    private var flagsPart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Feature Flags (R12) - Para desarrolladores")
                .font(.headline)
            Text("Si una feature se rompe, la apagas y la app sigue funcionando.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Feature.allCases, id: \.rawValue) { feature in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.caption.bold())
                        Text(feature.isFree ? "Gratis" : "1 gratis, ilimitado Premium")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { premium.isEnabled(feature) },
                        set: { premium.setEnabled(feature, enabled: $0) }
                    ))
                    .labelsHidden()
                }
                .padding(10)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
}
