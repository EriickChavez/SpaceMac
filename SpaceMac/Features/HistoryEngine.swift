//
//  HistoryEngine.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation
import Combine

// R10 - Historial
// Guarda: qué borraste, cuándo, cuánto liberaste. Todo local, en tu Mac.
// R11 - Aviso Poco Espacio: avisa 1 vez cuando te quedan < 10GB.

public struct HistoryEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let fileName: String
    public let filePath: String
    public let sizeBytes: Int64
    public let date: Date
    public let risk: String

    public init(file: ScannedFile) {
        self.id = UUID()
        self.fileName = file.name
        self.filePath = file.path
        self.sizeBytes = file.sizeBytes
        self.date = Date()
        self.risk = file.risk.rawValue
    }
}

public final class HistoryEngine: ObservableObject {
    public static let shared = HistoryEngine()
    private init() { load() }

    @Published public var entries: [HistoryEntry] = []
    @Published public var lastLowSpaceAlertDate: Date? = nil

    private let storageKey = "SpaceMac.History.v1"
    private let alertKey = "SpaceMac.LastLowSpaceAlert.v1"

    public var totalFreed: Int64 {
        entries.map { $0.sizeBytes }.reduce(0, +)
    }

    public var freedToday: Int64 {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.filter { $0.date >= today }.map { $0.sizeBytes }.reduce(0, +)
    }

    public var freedThisWeek: Int64 {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return entries.filter { $0.date >= weekAgo }.map { $0.sizeBytes }.reduce(0, +)
    }

    // Se llama cada vez que borras un archivo (R02, uno por uno)
    public func add(_ file: ScannedFile) {
        let entry = HistoryEntry(file: file)
        entries.insert(entry, at: 0)
        save()
    }

    // R11: ¿Debo avisar de poco espacio? Solo 1 vez cada 24h, sin spam.
    public func shouldAlertLowSpace(freeBytes: Int64) -> Bool {
        let threshold: Int64 = 10_000_000_000 // 10GB
        if freeBytes > threshold { return false }
        if let last = lastLowSpaceAlertDate {
            // Si ya avisamos hace menos de 24h, no volvemos a avisar
            if Date().timeIntervalSince(last) < 24 * 60 * 60 { return false }
        }
        return true
    }

    public func markLowSpaceAlerted() {
        lastLowSpaceAlertDate = Date()
        UserDefaults.standard.set(Date(), forKey: alertKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = decoded
        }
        if let date = UserDefaults.standard.object(forKey: alertKey) as? Date {
            lastLowSpaceAlertDate = date
        }
    }

    public func clear() {
        entries.removeAll()
        save()
    }
}
