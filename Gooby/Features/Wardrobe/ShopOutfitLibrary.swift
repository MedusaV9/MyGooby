import SwiftUI

struct ShopOutfitLibrary: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = ShopRoomStore.shared
    @State private var name = ""
    @State private var pendingDelete: ShopOutfit?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(ShopL10n.text(.namePlaceholder, store.language), text: $name)
                    Button(ShopL10n.text(.saveOutfit, store.language)) {
                        store.saveOutfit(named: name)
                        name = ""
                    }
                }
                if ordered.isEmpty {
                    Text(ShopL10n.text(.noOutfits, store.language))
                        .foregroundStyle(ShopTheme.ink.opacity(0.7))
                }
                ForEach(ordered) { outfit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(outfit.name)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(ShopTheme.ink)
                            Spacer()
                            if outfit.favorite {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(ShopTheme.pink)
                            }
                        }
                        Text(summary(outfit))
                            .font(ShopTheme.captionFont())
                            .foregroundStyle(ShopTheme.ink.opacity(0.7))
                            .lineLimit(2)
                        HStack {
                            Button(ShopL10n.text(.apply, store.language)) {
                                store.applyOutfit(id: outfit.id)
                                dismiss()
                            }
                            Button(ShopL10n.text(outfit.favorite ? .unfavorite : .favorite, store.language)) {
                                store.toggleOutfitFavorite(id: outfit.id)
                            }
                            Button(ShopL10n.text(.delete, store.language), role: .destructive) {
                                pendingDelete = outfit
                            }
                        }
                        .font(ShopTheme.captionFont())
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(ShopL10n.text(.outfits, store.language))
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
                    store.deleteOutfit(id: pendingDelete.id)
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

    private var ordered: [ShopOutfit] {
        store.state.outfits.sorted { lhs, rhs in
            if lhs.favorite != rhs.favorite { return lhs.favorite && !rhs.favorite }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private func summary(_ outfit: ShopOutfit) -> String {
        let names = outfit.pieces.keys.sorted().compactMap { key -> String? in
            guard let id = outfit.pieces[key] else { return nil }
            return ShopCatalog.byID[id]?.name(store.language)
        }
        if names.isEmpty {
            return ShopL10n.text(.none, store.language)
        }
        return names.joined(separator: ", ")
    }
}
