//
//  Routes.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import Foundation

// R09 - Rutas por especialización
// Todos pueden usar todas las rutas. No hay bloqueo por perfil.

public enum DevRoute: String, CaseIterable, Identifiable {
    case web, ios, android, reactNative, backend, designer, architect, common
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .common: return "Común"
        case .web: return "Web"
        case .ios: return "iOS"
        case .android: return "Android"
        case .reactNative: return "React Native"
        case .backend: return "Backend"
        case .designer: return "Diseñador"
        case .architect: return "Arquitecto"
        }
    }

    public var icon: String {
        switch self {
        case .common: return "folder.fill"
        case .web: return "globe"
        case .ios: return "iphone"
        case .android: return "smartphone"
        case .reactNative: return "atom"
        case .backend: return "server.rack"
        case .designer: return "paintbrush.fill"
        case .architect: return "building.2.fill"
        }
    }

    public var description: String {
        switch self {
        case .common: return "Descargas, cachés generales, instaladores viejos"
        case .web: return "node_modules, builds, cachés de Vite / Next"
        case .ios: return "DerivedData, simuladores, archivos de Xcode"
        case .android: return "Gradle, emuladores, builds de Android"
        case .reactNative: return "Pods + node_modules + builds iOS y Android"
        case .backend: return "Docker, logs, bases de datos locales"
        case .designer: return "Cachés de Adobe, Figma, Sketch"
        case .architect: return "Renders, AutoCAD, cachés de modelado"
        }
    }

    public var paths: [String] {
        switch self {
        case .common:
            return ["~/Downloads", "~/Library/Caches", "~/Desktop"]
        case .web:
            return ["~/Library/Caches/node", "node_modules", ".next", ".vite", "dist"]
        case .ios:
            return ["~/Library/Developer/Xcode/DerivedData", "~/Library/Developer/CoreSimulator", "~/Library/Developer/Xcode/Archives"]
        case .android:
            return ["~/.gradle", "~/.android/avd", "android/build", "android/app/build"]
        case .reactNative:
            return ["node_modules", "ios/Pods", "ios/build", "android/build"]
        case .backend:
            return ["~/Library/Containers/com.docker", "*.log", "logs", ".docker"]
        case .designer:
            return ["~/Library/Caches/com.adobe", "~/Library/Caches/com.figma", "~/Library/Caches/com.bohemiancoding.sketch"]
        case .architect:
            return ["~/Library/Caches/Autodesk", "Renders", "*.dwg.bak"]
        }
    }
}
