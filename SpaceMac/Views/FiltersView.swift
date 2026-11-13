//
//  FiltersView.swift
//  SpaceMac
//
//  Created by Erick Chavez on 12/11/26.
//

import SwiftUI

// Solo filtros. Usa @Binding, el padre guarda el valor.
public struct FiltersView: View {
    @Binding var query: String
    @Binding var selectedCategory: String
    @Binding var showOnlyDeletable: Bool
    var categories: [String]
    public init(query: Binding<String>, selectedCategory: Binding<String>, showOnlyDeletable: Binding<Bool>, categories: [String]) {
        self._query = query; self._selectedCategory = selectedCategory; self._showOnlyDeletable = showOnlyDeletable; self.categories = categories
    }
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Buscar archivo...", text: $query).textFieldStyle(.plain)
            }
            .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Color.gray.opacity(0.08)).cornerRadius(10)
            HStack(spacing: 12) {
                Text("Categoría").font(.caption).foregroundStyle(.secondary).frame(width: 70, alignment: .leading)
                Picker("", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().frame(maxWidth: .infinity)
                Toggle("Solo borrables", isOn: $showOnlyDeletable).toggleStyle(.switch).frame(width: 140, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
