//
//  FooterView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI
public struct FooterView: View {
    public init() {}
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("SpaceMac • R01 Seguridad primero • R02 Sin Borrar Todo • R07 IA dentro de la app, gratis, sin internet • R08 Duplicados Gratis")
                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text("Nunca borramos el original sin tu permiso, uno por uno, y siempre a Papelera.")
                .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
