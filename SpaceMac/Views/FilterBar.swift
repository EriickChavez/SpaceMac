//
//  FilterBar.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// FilterBar - Reutilizable en TODAS las listas de SpaceMac
// Buscador + Filtro por tamaño + Filtro por riesgo + Filtro por tipo

public struct FileFilters: Equatable {
    public var query: String = ""
    public var minSize: SizeFilter = .all
    public var risk: RiskFilter = .all
    public var type: TypeFilter = .all

    public init() {}
}

public enum SizeFilter: String, CaseIterable, Identifiable {
    case all, small, medium, large, huge
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .all: return "Todos los tamaños"
        case .small: return "< 1MB"
        case .medium: return "1MB - 100MB"
        case .large: return "100MB - 1GB"
        case .huge: return "> 1GB"
        }
    }
    public func matches(_ bytes: Int64) -> Bool {
        switch self {
        case .all: return true
        case .small: return bytes < 1_000_000
        case .medium: return bytes >= 1_000_000 && bytes < 100_000_000
        case .large: return bytes >= 100_000_000 && bytes < 1_000_000_000
        case .huge: return bytes >= 1_000_000_000
        }
    }
}

public enum RiskFilter: String, CaseIterable, Identifiable {
    case all, verde, amarillo, rojo
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .all: return "Todos"
        case .verde: return "🟢 Seguro"
        case .amarillo: return "🟡 Revisar"
        case .rojo: return "🔴 No tocar"
        }
    }
    public func matches(_ risk: RiskLevel) -> Bool {
        if self == .all { return true }
        switch self {
        case .verde: return risk == .verde
        case .amarillo: return risk == .amarillo
        case .rojo: return risk == .rojo
        case .all: return true
        }
    }
}

public enum TypeFilter: String, CaseIterable, Identifiable {
    case all, image, video, audio, code, document, archive, other
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .all: return "Todos los tipos"
        case .image: return "🖼️ Imágenes"
        case .video: return "🎬 Videos"
        case .audio: return "🎵 Audio"
        case .code: return "💻 Código"
        case .document: return "📄 Documentos"
        case .archive: return "📦 Archivos / DMG"
        case .other: return "Otros"
        }
    }
    public func matches(_ name: String) -> Bool {
        let lower = name.lowercased()
        switch self {
        case .all: return true
        case .image: return lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".heic") || lower.hasSuffix(".webp") || lower.hasSuffix(".gif")
        case .video: return lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v")
        case .audio: return lower.hasSuffix(".mp3") || lower.hasSuffix(".wav") || lower.hasSuffix(".m4a")
        case .code: return lower.hasSuffix(".js") || lower.hasSuffix(".ts") || lower.hasSuffix(".swift") || lower.hasSuffix(".py") || lower.hasSuffix(".json") || lower.hasSuffix(".log")
        case .document: return lower.hasSuffix(".pdf") || lower.hasSuffix(".txt") || lower.hasSuffix(".doc") || lower.hasSuffix(".docx")
        case .archive: return lower.hasSuffix(".zip") || lower.hasSuffix(".dmg") || lower.hasSuffix(".pkg") || lower.hasSuffix(".rar")
        case .other: return true
        }
    }
}

public extension Array where Element == ScannedFile {
    func applying(_ filters: FileFilters) -> [ScannedFile] {
        var list = self
        if !filters.query.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(filters.query) || $0.path.localizedCaseInsensitiveContains(filters.query) }
        }
        list = list.filter { filters.minSize.matches($0.sizeBytes) }
        list = list.filter { filters.risk.matches($0.risk) }
        list = list.filter { filters.type.matches($0.name) }
        return list
    }
}

public struct FilterBar: View {
    @Binding var filters: FileFilters
    var resultCount: Int

    public init(filters: Binding<FileFilters>, resultCount: Int) {
        self._filters = filters
        self.resultCount = resultCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchPart
            chipsPart
            resultPart
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(12)
    }

    private var searchPart: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar por nombre o ruta... ej: foto, .log, node_modules", text: $filters.query)
                .textFieldStyle(.roundedBorder)
            if !filters.query.isEmpty {
                Button("Limpiar") { filters.query = "" }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private var chipsPart: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Tamaño:")
                    .font(.caption.bold())
                    .frame(width: 60, alignment: .leading)
                Picker("Tamaño", selection: $filters.minSize) {
                    ForEach(SizeFilter.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Text("Riesgo:")
                    .font(.caption.bold())
                    .frame(width: 60, alignment: .leading)
                Picker("Riesgo", selection: $filters.risk) {
                    ForEach(RiskFilter.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Text("Tipo:")
                    .font(.caption.bold())
                    .frame(width: 60, alignment: .leading)
                Picker("Tipo", selection: $filters.type) {
                    ForEach(TypeFilter.allCases) { f in
                        Text(f.title).tag(f)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                if filters.query != "" || filters.minSize != .all || filters.risk != .all || filters.type != .all {
                    Button("Limpiar todos los filtros") {
                        filters = FileFilters()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Text("Filtros activos")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var resultPart: some View {
        Text("\(resultCount) archivos con estos filtros")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
