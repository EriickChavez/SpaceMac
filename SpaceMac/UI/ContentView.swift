//
//  ContentView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

//
//  ContentView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI
import Combine

// SpaceMac - ContentView MODULAR V5 - Completo
// body = sidebar + detail, detail = header + content + footer
// Cada parte es una var chiquita, para que el compilador no se ahogue.
// R01 a R12, R15, Espacio Hormiga, Duplicados, Rutas, Historial, Privadas

public struct ContentView: View {
    @StateObject private var scanner = ScannerEngine()
    @StateObject private var downloader = ModelDownloader.shared
    @StateObject private var aiService = EmbeddedAIService.shared
    @StateObject private var duplicateEngine = DuplicateEngine.shared
    @StateObject private var history = HistoryEngine.shared
    @StateObject private var premium = PremiumEngine.shared
    @StateObject private var antEngine = AntSpaceEngine.shared

    @State private var query = ""
    @State private var selectedCategory: String = "Todo"
    @State private var showOnlyDeletable = false
    @State private var fileToDelete: ScannedFile? = nil
    @State private var showDeleteConfirm = false
    @State private var deletedMessage: String? = nil
    @State private var selectedSidebar: String = "Resumen"
    @State private var selectedAntFolder: AntFolder? = nil

    private let categories = ["Todo", "Caché", "Dev iOS", "Sistema", "App"]
    public init() {}

    // MARK: - Datos calculados
    private var filteredFiles: [ScannedFile] {
        var list = scanner.files
        if selectedCategory != "Todo" {
            list = list.filter { $0.category == selectedCategory }
        }
        if !query.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        if showOnlyDeletable {
            list = list.filter { $0.risk != .rojo }
        }
        return list
    }

    private var totalBytes: Int64 {
        scanner.files.map { $0.sizeBytes }.reduce(0, +)
    }

    private var deletableBytes: Int64 {
        scanner.files.filter { $0.risk != .rojo }.map { $0.sizeBytes }.reduce(0, +)
    }

    private var duplicatesWasted: Int64 {
        duplicateEngine.groups.map { $0.wastedBytes }.reduce(0, +)
    }

    private var blockedCount: Int {
        scanner.files.filter { $0.risk == .rojo }.count
    }

    // MARK: - Body partido en 2: sidebar + detail
    public var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
    }

    // MARK: - Sidebar solo
    private var sidebarView: some View {
        List(selection: $selectedSidebar) {
            Section("SpaceMac") {
                Label("Resumen", systemImage: "chart.pie.fill").tag("Resumen")
            }
            Section("Inteligente") {
                Label("Duplicados R08 - Gratis", systemImage: "doc.on.doc").tag("Duplicados")
                Label("Rutas R09", systemImage: "folder.fill.badge.person.crop").tag("Rutas")
            }
            Section("Ajustes") {
                Label("Carpetas Privadas R03 - Premium", systemImage: "lock.fill").tag("Privadas")
                Label("Historial R10", systemImage: "clock.fill").tag("Historial")
            }
            Section("Extra") {
                Label("Espacio Hormiga 🐜", systemImage: "ant.fill").tag("Hormiga")
            }
        }
        .navigationTitle("SpaceMac")
        .listStyle(.sidebar)
    }

    // MARK: - Detail solo
    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView()
                AIBannerView(downloader: downloader, aiService: aiService)
                mainContentView
                FooterView()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            downloader.checkOnLaunch()
        }
        .alert("¿Borrar este archivo?", isPresented: $showDeleteConfirm, presenting: fileToDelete) { file in
            Button("Borrar - Mandar a Papelera", role: .destructive) {
                deleteOne(file)
            }
            Button("Cancelar", role: .cancel) {}
        } message: { file in
            Text("Se borrará:\n\(file.name)\n\(file.path)\n\nTamaño: \(formatBytes(file.sizeBytes))\n\nSe manda a Papelera, no se borra para siempre.")
        }
    }

    // MARK: - Contenido principal - partido por secciones
    @ViewBuilder
    private var mainContentView: some View {
        if selectedSidebar == "Duplicados" {
            duplicatesContentView
        } else if selectedSidebar == "Rutas" {
            routesContentView
        } else if selectedSidebar == "Hormiga" {
            hormigaContentView
        } else if selectedSidebar == "Historial" {
            historyContentView
        } else if selectedSidebar == "Privadas" {
            privadasContentView
        } else {
            summaryContentView
        }
    }

    private var duplicatesContentView: some View {
        DuplicatesView(
            duplicateEngine: duplicateEngine,
            onSearch: {
                Task {
                    _ = await duplicateEngine.findDuplicates(in: scanner.files)
                }
            },
            onDelete: { fileToDelete = $0; showDeleteConfirm = true },
            onDeleteSelected: { files in
                deleteSelected(files)
            },
            onBack: { selectedSidebar = "Resumen" },
            canSearch: !scanner.files.isEmpty
        )
    }

    private var routesContentView: some View {
        RoutesView(
            allFiles: scanner.files,
            onDelete: { fileToDelete = $0; showDeleteConfirm = true },
            onDeleteSelected: { files in
                deleteSelected(files)
            }
        )
    }

    @ViewBuilder
    private var hormigaContentView: some View {
        if let selectedAntFolder = selectedAntFolder {
            AntFolderDetailView(
                folder: selectedAntFolder,
                onDeleteOne: { fileToDelete = $0; showDeleteConfirm = true },
                onDeleteSelected: { files in
                    deleteSelected(files)
                },
                onBack: { self.selectedAntFolder = nil }
            )
        } else {
            AntSpaceView(
                antEngine: antEngine,
                onAnalyze: {
                    Task {
                        let home = FileManager.default.homeDirectoryForCurrentUser.path
                        await antEngine.analyze(foldersToCheck: [
                            "\(home)/Library/Developer/Xcode/DerivedData",
                            "\(home)/Library/Developer/CoreSimulator",
                            "\(home)/Library/Caches",
                            "\(home)/Downloads",
                            "\(home)/Desktop"
                        ])
                    }
                },
                onOpenFolder: { selectedAntFolder = $0 }
            )
        }
    }

    private var historyContentView: some View {
        HistoryView(
            history: history,
            freeBytes: 18_000_000_000,
            onBack: { selectedSidebar = "Resumen" }
        )
    }

    private var privadasContentView: some View {
        PrivateFoldersView(premium: premium)
    }

    private var summaryContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScanControlsView(
                isScanning: scanner.isScanning,
                isAnalyzing: aiService.isAnalyzing,
                canAnalyze: !scanner.files.isEmpty,
                onScan: {
                    Task {
                        _ = await scanner.scan()
                        _ = await duplicateEngine.findDuplicates(in: scanner.files)
                    }
                },
                onAnalyze: { Task { await analyzeAllOneByOne() } }
            )
            StatsView(
                totalBytes: totalBytes,
                deletableBytes: deletableBytes,
                fileCount: scanner.files.count,
                blockedCount: blockedCount,
                groupCount: duplicateEngine.groups.count,
                duplicatesWasted: duplicatesWasted
            )
            FiltersView(
                query: $query,
                selectedCategory: $selectedCategory,
                showOnlyDeletable: $showOnlyDeletable,
                categories: categories
            )
            FilesListView(
                files: filteredFiles,
                totalFiles: scanner.files.count,
                deletedMessage: deletedMessage,
                isAIReady: downloader.isDownloaded,
                onDelete: { fileToDelete = $0; showDeleteConfirm = true },
                onDeleteSelected: { files in
                    deleteSelected(files)
                },
                onShowDuplicates: { selectedSidebar = "Duplicados" },
                hasDuplicates: !duplicateEngine.groups.isEmpty,
                duplicateCount: duplicateEngine.groups.count
            )
        }
    }

    // MARK: - Acciones
    private func deleteOne(_ file: ScannedFile) {
        // BONUS R03: Si es privado, ni lo intentamos borrar
        if PremiumEngine.shared.isPrivate(file.path) {
            deletedMessage = "🔒 Protegido por R03: \(file.name) está en una Carpeta Privada. SpaceMac nunca lo toca."
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                deletedMessage = nil
            }
            fileToDelete = nil
            return
        }

        if file.risk == .rojo {
            deletedMessage = "⛔ Bloqueado por R01: \(file.name) es del sistema. No se puede borrar."
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                deletedMessage = nil
            }
            fileToDelete = nil
            return
        }

        do {
            try ProtectionEngine.shared.deleteOne(file)

            // FIX: Actualizar en Main, para que SwiftUI sí se entere
            Task { @MainActor in
                // 1. Quitar de la lista principal
                scanner.files.removeAll { $0.id == file.id }

                // 2. Quitar de Duplicados también, si estaba ahí
                duplicateEngine.groups = duplicateEngine.groups.map { group in
                    var g = group
                    g.files.removeAll { $0.id == file.id }
                    return g
                }.filter { $0.files.count >= 2 }

                // 3. Guardar en Historial
                history.add(file)

                // 4. Limpiar el archivo a borrar, para que no se quede pegado
                fileToDelete = nil

                deletedMessage = "Se mandó a Papelera: \(file.name) - \(formatBytes(file.sizeBytes))"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    deletedMessage = nil
                }
            }

            // Re-buscar duplicados en segundo plano, sin bloquear la UI
            Task {
                _ = await duplicateEngine.findDuplicates(in: scanner.files)
            }
        } catch {
            deletedMessage = "No se pudo borrar: \(error.localizedDescription)"
            fileToDelete = nil
        }
    }

    // MARK: - Multiselector: borra solo los que tú elegiste
    // Nunca Borrar Todo. Solo los que vienen en `files`, que tú marcaste con checkbox.
    // Por dentro los borra uno por uno, a Papelera, y actualiza todo al instante.
    private func deleteSelected(_ files: [ScannedFile]) {
        var deletedCount = 0
        var deletedBytes: Int64 = 0
        var blockedCount = 0

        for file in files {
            // Seguridad: aunque se haya colado, nunca Rojo ni Privado
            if file.risk == .rojo {
                blockedCount += 1
                continue
            }
            if PremiumEngine.shared.isPrivate(file.path) {
                blockedCount += 1
                continue
            }

            do {
                try ProtectionEngine.shared.deleteOne(file)
                deletedCount += 1
                deletedBytes += file.sizeBytes
            } catch {
                continue
            }
        }

        let deletedIDs = Set(files.map { $0.id })

        // Quitar de todo al mismo tiempo, en Main, para que SwiftUI sí se entere
        Task { @MainActor in
            scanner.files.removeAll { deletedIDs.contains($0.id) }

            duplicateEngine.groups = duplicateEngine.groups.map { group in
                var g = group
                g.files.removeAll { deletedIDs.contains($0.id) }
                return g
            }.filter { $0.files.count >= 2 }

            for file in files {
                if deletedIDs.contains(file.id) && file.risk != .rojo && !PremiumEngine.shared.isPrivate(file.path) {
                    history.add(file)
                }
            }

            if deletedCount > 0 {
                deletedMessage = "Se mandaron a Papelera \(deletedCount) archivos que seleccionaste - \(formatBytes(deletedBytes))"
                if blockedCount > 0 {
                    deletedMessage! += " (\(blockedCount) bloqueados por seguridad, no se tocaron)"
                }
            } else {
                deletedMessage = "No se borró nada. Todos los seleccionados estaban bloqueados por seguridad."
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                deletedMessage = nil
            }
        }

        Task {
            _ = await duplicateEngine.findDuplicates(in: scanner.files)
        }
    }

    private func analyzeAllOneByOne() async {
        for file in scanner.files {
            let analyzed = await aiService.analyzeOne(file)
            await MainActor.run {
                if let index = scanner.files.firstIndex(where: { $0.id == file.id }) {
                    scanner.files[index] = analyzed
                }
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
