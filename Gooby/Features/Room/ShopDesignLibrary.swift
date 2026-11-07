import SwiftUI

struct ShopDesignLibrary: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = ShopRoomStore.shared
    @State private var name = ""
    @State private var pendingDelete: ShopRoomDesign?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(ShopL10n.text(.namePlaceholder, store.language), text: $name)
                    Button(ShopL10n.text(.saveDesign, store.language)) {
                        store.saveDesign(named: name)
                        name = ""
                    }
                }
                if ordered.isEmpty {
                    Text(ShopL10n.text(.noDesigns, store.language))
                        .foregroundStyle(ShopTheme.ink.opacity(0.7))
                }
                ForEach(ordered) { design in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(design.name)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(ShopTheme.ink)
                            Spacer()
                            if design.favorite {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(ShopTheme.pink)
                            }
                        }
                        Text(summary(design))
                            .font(ShopTheme.captionFont())
                            .foregroundStyle(ShopTheme.ink.opacity(0.7))
                            .lineLimit(3)
                        HStack {
                            Button(ShopL10n.text(.apply, store.language)) {
                                store.applyDesign(id: design.id)
                                dismiss()
                            }
                            Button(ShopL10n.text(design.favorite ? .unfavorite : .favorite, store.language)) {
                                store.toggleDesignFavorite(id: design.id)
                            }
                            Button(ShopL10n.text(.delete, store.language), role: .destructive) {
                                pendingDelete = design
                            }
                        }
                        .font(ShopTheme.captionFont())
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(ShopL10n.text(.designs, store.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ShopL10n.text(.done, store.language)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(
            ShopL10n.text(.delete, store.language),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(ShopL10n.text(.delete, store.language), role: .destructive) {
                if let pendingDelete {
                    store.deleteDesign(id: pendingDelete.id)
                }
                pendingDelete = nil
            }
            Button(ShopL10n.text(.cancel, store.language), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            if let pendingDelete {
                Text(ShopL10n.format(.deleteQuestion, store.language, pendingDelete.name))
            }
        }
    }

    private var ordered: [ShopRoomDesign] {
        store.state.roomDesigns.sorted { lhs, rhs in
            if lhs.favorite != rhs.favorite { return lhs.favorite && !rhs.favorite }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private func summary(_ design: ShopRoomDesign) -> String {
        let light = ShopDaylight(rawValue: design.lightingMode) ?? .auto
        let names = design.placements.keys.sorted().compactMap { key -> String? in
            guard let id = design.placements[key] else { return nil }
            return ShopCatalog.byID[id]?.name(store.language)
        }
        let pieces = names.isEmpty ? ShopL10n.text(.none, store.language) : names.joined(separator: ", ")
        return "\(ShopL10n.daylight(light, store.language)) · \(pieces)"
    }
}
