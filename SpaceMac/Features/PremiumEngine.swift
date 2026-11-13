//
//  PremiumEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// R12 - Feature Flags: prende/apaga features sin recompilar
// R15 - Gratis/Premium: Todo gratis, solo Carpetas Privadas ilimitadas es Premium
// R03 - Carpetas Privadas: carpetas que SpaceMac NUNCA toca

public enum Feature: String, CaseIterable {
    case scan, duplicates, routes, history, lowSpaceAlert, privateFolders, ai

    public var title: String {
        switch self {
        case .scan: return "Escanear (R04)"
        case .duplicates: return "Duplicados (R08) - Gratis"
        case .routes: return "Rutas (R09) - Gratis"
        case .history: return "Historial (R10) - Gratis"
        case .lowSpaceAlert: return "Aviso Poco Espacio (R11) - Gratis"
        case .privateFolders: return "Carpetas Privadas (R03) - Premium"
        case .ai: return "IA Local (R07) - Gratis"
        }
    }

    public var isFree: Bool {
        // R15: Todo gratis, solo Carpetas Privadas ilimitadas es Premium
        // 1 carpeta privada gratis, para probar. Ilimitadas = Premium.
        switch self {
        case .privateFolders: return false // Parcial: 1 gratis, ilimitadas Premium
        default: return true
        }
    }
}

public final class PremiumEngine: ObservableObject {
    public static let shared = PremiumEngine()
    private init() { load() }

    // R15: Por defecto, eres Gratis. Premium se activa con StoreKit (R13, al final).
    @Published public var isPremium: Bool = false

    // R12: Flags, todos prendidos por defecto
    @Published public var enabledFeatures: [Feature: Bool] = [
        .scan: true, .duplicates: true, .routes: true,
        .history: true, .lowSpaceAlert: true, .privateFolders: true, .ai: true
    ]

    // R03: Carpetas que NUNCA se tocan
    @Published public var privateFolders: [String] = []

    public var freePrivateFolderLimit: Int { 1 }

    public var canAddPrivateFolder: Bool {
        if isPremium { return true }
        return privateFolders.count < freePrivateFolderLimit
    }

    public var privateFolderMessage: String {
        if isPremium { return "Premium: Carpetas Privadas ilimitadas" }
        if privateFolders.isEmpty { return "Gratis: Puedes probar con 1 carpeta privada" }
        return "Gratis: Ya usaste tu 1 carpeta gratis. Premium = ilimitadas"
    }

    // R12: ¿Está prendida esta feature?
    public func isEnabled(_ feature: Feature) -> Bool {
        return enabledFeatures[feature] ?? true
    }

    public func setEnabled(_ feature: Feature, enabled: Bool) {
        enabledFeatures[feature] = enabled
        save()
    }

    // R03
    public func addPrivateFolder(_ path: String) -> Bool {
        if !canAddPrivateFolder { return false }
        if privateFolders.contains(path) { return false }
        privateFolders.append(path)
        save()
        return true
    }

    public func removePrivateFolder(_ path: String) {
        privateFolders.removeAll { $0 == path }
        save()
    }

    public func isPrivate(_ path: String) -> Bool {
        return privateFolders.contains { path.contains($0) || $0.contains(path) }
    }

    // Para pruebas: simular Premium sin pagar (solo en Debug, se quita en App Store)
    public func togglePremiumForTesting() {
        isPremium.toggle()
        save()
    }

    private let premiumKey = "SpaceMac.IsPremium.v1"
    private let flagsKey = "SpaceMac.Flags.v1"
    private let foldersKey = "SpaceMac.PrivateFolders.v1"

    private func save() {
        UserDefaults.standard.set(isPremium, forKey: premiumKey)
        UserDefaults.standard.set(privateFolders, forKey: foldersKey)
        let raw = enabledFeatures.map { "\($0.key.rawValue):\($0.value)" }
        UserDefaults.standard.set(raw, forKey: flagsKey)
    }

    private func load() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
        privateFolders = UserDefaults.standard.stringArray(forKey: foldersKey) ?? []
        if let raw = UserDefaults.standard.stringArray(forKey: flagsKey) {
            for item in raw {
                let parts = item.split(separator: ":")
                if parts.count == 2, let f = Feature(rawValue: String(parts[0])) {
                    enabledFeatures[f] = parts[1] == "true"
                }
            }
        }
    }
}
