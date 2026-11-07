import SwiftUI

/// Shell entry for the shop, wardrobe, and room.
///
/// Call `setLanguageCode` when the app language changes and `bindAppDate` with the
/// simulated app date. Bind `bindWallet` to the shell currency, or leave it unset
/// to use the local star-spark balance (250 at first launch).
///
/// Destination ids match the adventures places: flower-meadow, cloud-land,
/// star-forest, sugar-island, crystal-lake, sunny-beach, moon-valley,
/// fairy-garden, snow-village, cherry-park.
@MainActor
enum ShopIntegration {
    static func shopScreen() -> some View {
        ShopFeatureScreen()
    }

    static func wardrobeScreen() -> some View {
        ShopWardrobeScreen()
    }

    static func roomScreen() -> some View {
        ShopRoomScreen()
    }

    /// Saved room, light, and worn clothes for the home screen. No editor chrome.
    static func roomPortrait() -> some View {
        ShopRoomPortrait()
    }

    /// Gooby in the saved outfit, without the room.
    static func dressedBunny() -> some View {
        ShopDressedBunny()
    }

    static func setLanguageCode(_ code: String) {
        ShopRoomStore.shared.setLanguage(code: code)
    }

    static func bindAppDate(_ provider: @escaping () -> Date) {
        ShopRoomStore.shared.bindDateProvider(provider)
    }

    static func noteAppDateChanged() {
        ShopRoomStore.shared.syncClock()
    }

    static func bindWallet(
        balance: @escaping () -> Int,
        debit: @escaping (Int) -> Bool,
        credit: @escaping (Int) -> Void
    ) {
        ShopRoomStore.shared.bindWallet(
            ShopWalletBridge(balance: balance, debit: debit, credit: credit)
        )
    }

    static func useInternalWallet() {
        ShopRoomStore.shared.bindWallet(nil)
    }

    static func refreshBalance() {
        ShopRoomStore.shared.refreshBalance()
    }

    static func balance() -> Int {
        ShopRoomStore.shared.shownBalance
    }

    static func equippedPieces() -> [String: String] {
        ShopRoomStore.shared.state.equipped
    }

    static func roomPlacements() -> [String: String] {
        ShopRoomStore.shared.state.placements
    }

    static func ownedIDs() -> Set<String> {
        Set(ShopRoomStore.shared.state.ownedIDs)
    }

    static func unlockedDestinationIDs() -> Set<String> {
        ShopRoomStore.shared.unlockedDestinationIDs()
    }

    static func activeDestinationID() -> String? {
        ShopRoomStore.shared.activeDestinationID()
    }

    static func lightingMode() -> String {
        ShopRoomStore.shared.lightingMode().rawValue
    }

    static func resolvedLighting() -> String {
        ShopRoomStore.shared.resolvedPhase().rawValue
    }

    enum Debug {
        @MainActor
        static func unlockAll() {
            ShopRoomStore.shared.debugUnlockAll()
        }

        @MainActor
        static func resetInventory() {
            ShopRoomStore.shared.debugResetInventory()
        }

        /// Works only while the internal wallet is active. Returns false if a shell wallet is bound.
        @MainActor
        static func setInternalBalance(_ amount: Int) -> Bool {
            ShopRoomStore.shared.debugSetBalance(amount)
        }

        @MainActor
        static func setSeed(_ seed: UInt64) {
            ShopRoomStore.shared.debugSetSeed(seed)
        }

        /// Overrides the app date used for daily offers and automatic light. Pass nil to follow `bindAppDate`.
        @MainActor
        static func setAppDate(_ date: Date?) {
            ShopRoomStore.shared.debugSetAppDate(date)
        }

        @MainActor
        static func setLighting(_ raw: String) -> Bool {
            ShopRoomStore.shared.debugSetLighting(raw)
        }

        @MainActor
        static func offerIDs(year: Int, month: Int, day: Int) -> [String] {
            ShopRoomStore.shared.debugOfferIDs(year: year, month: month, day: day)
        }

        @MainActor
        static func summary() -> String {
            ShopRoomStore.shared.debugSummary()
        }

        @MainActor
        static func json() -> String {
            ShopRoomStore.shared.debugJSON()
        }
    }
}

private struct ShopDressedBunny: View {
    @State private var store = ShopRoomStore.shared

    var body: some View {
        ShopBunnyView(
            worn: store.resolved(store.state.equipped),
            animated: true,
            language: store.language
        )
        .onAppear { store.syncClock() }
    }
}

private struct ShopRoomPortrait: View {
    @State private var store = ShopRoomStore.shared

    var body: some View {
        ShopRoomCanvas(
            placements: store.resolved(store.state.placements),
            worn: store.resolved(store.state.equipped),
            phase: store.resolvedPhase(),
            highlighted: nil,
            showsBunny: true,
            animatedBunny: true,
            language: store.language
        )
        .onAppear { store.syncClock() }
    }
}
