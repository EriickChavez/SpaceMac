//
//  HeaderView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// Solo el header. Si quieres cambiar el título, solo tocas aquí.
public struct HeaderView: View {
    public init() {}
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("SpaceMac")
                    .font(.system(size: 32, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text("M1 • 2020")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
            }
            Text("MacBook Pro M1 2020 • 18 GB libres de 256 GB")
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("Seguridad primero: si no estamos 100% seguros, no se borra. (R01)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
