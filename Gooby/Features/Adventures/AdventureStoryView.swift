import SwiftUI
import UIKit

enum AdventureStoryMode {
    case activeTrip
    case preview
}

struct AdventureStoryScreen: View {
    var bridge: AdventureBridge
    var store: AdventureStore
    var reduceMotion: Bool
    var mode: AdventureStoryMode

    @Environment(\.dismiss) private var dismiss
    @State private var result: AdventureJournalEntry?
    @State private var pinnedStoryID: String?
    @State private var choosing = false

    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }

    var body: some View {
        ZStack {
            AdventureScreenBackground()
            if let story, let place {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AdventureBackHeader(title: story.title.resolved(bridge.language), backTitle: copy.back) {
                            close()
                        }
                        ZStack {
                            AdventureSky(place: place, reducedMotion: reduceMotion)
                            AdventureBunnyView(pose: result == nil ? .think : .celebrate, reducedMotion: reduceMotion)
                                .padding(.top, 24)
                        }
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        Text(AdventureText.filled(story.body.resolved(bridge.language), name: bridge.displayName))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AdventurePalette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let result {
                            outcome(story: story, result: result)
                        } else {
                            Text(copy.chooseHint)
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(AdventurePalette.ink)
                            ForEach(story.choices) { choice in
                                Button {
                                    choose(choice)
                                } label: {
                                    Text(AdventureText.filled(choice.text.resolved(bridge.language), name: bridge.displayName))
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(AdventurePalette.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .background(AdventurePalette.pink.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                                .buttonStyle(AdventurePressStyle())
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 12) {
                    Text(copy.catalogError)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink)
                    AdventurePrimaryButton(title: copy.back) { close() }
                }
                .padding(24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if pinnedStoryID == nil {
                pinnedStoryID = liveStoryID
            }
        }
    }

    private var liveStoryID: String? {
        switch mode {
        case .activeTrip:
            return store.save.active?.storyID
        case .preview:
            return store.previewStoryID
        }
    }

    private var story: AdventureStoryDefinition? {
        let identifier = pinnedStoryID ?? liveStoryID
        guard let identifier else { return nil }
        return store.catalog.story(id: identifier)
    }

    private var place: AdventurePlaceDefinition? {
        guard let story else { return nil }
        return store.catalog.place(id: story.placeID)
    }

    private func choose(_ choice: AdventureChoiceDefinition) {
        guard result == nil, !choosing else { return }
        choosing = true
        if !reduceMotion {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        switch mode {
        case .activeTrip:
            guard let trip = store.save.active else {
                choosing = false
                return
            }
            result = store.claim(tripID: trip.id, choiceID: choice.id, bridge: bridge, wallNow: Date())
        case .preview:
            guard let id = store.previewStoryID else {
                choosing = false
                return
            }
            result = store.claimPreview(storyID: id, choiceID: choice.id, bridge: bridge, wallNow: Date())
        }
        if result == nil {
            choosing = false
        }
    }

    private func outcome(story: AdventureStoryDefinition, result: AdventureJournalEntry) -> some View {
        let choice = story.choices.first { $0.id == result.choiceID }
        return VStack(alignment: .leading, spacing: 12) {
            Text(copy.outcomeTitle)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AdventurePalette.ink)
            if let choice {
                Text(AdventureText.filled(choice.outcome.resolved(bridge.language), name: bridge.displayName))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if result.sparks > 0 {
                Text(copy.sparks(result.sparks))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AdventurePalette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AdventurePalette.yellow, in: Capsule())
            }
            if result.traitDeltas.isEmpty {
                Text(copy.steadyTraits)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.75))
            } else {
                traitRow(result.traitDeltas)
            }
            if let discoveryID = result.discoveryID, let found = store.catalog.discovery(id: discoveryID) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.newDiscovery)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AdventurePalette.ink.opacity(0.65))
                    Text(found.discovery.name.resolved(bridge.language))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink)
                    Text(found.discovery.detail.resolved(bridge.language))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink.opacity(0.8))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AdventurePalette.mint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else if choice?.discoveryID != nil && result.discoveryID == nil {
                Text(copy.alreadyKnown)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.75))
            }
            AdventurePrimaryButton(title: copy.home) { close() }
        }
    }

    private func traitRow(_ deltas: [String: Int]) -> some View {
        AdventureFlowRow {
            ForEach(AdventureTrait.allCases) { trait in
                if let amount = deltas[trait.rawValue], amount != 0 {
                    Text("+\(amount) \(copy.traitName(trait))")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AdventurePalette.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AdventurePalette.lavender, in: Capsule())
                }
            }
        }
    }

    private func close() {
        if mode == .preview {
            store.endPreview()
        }
        dismiss()
    }
}

struct AdventureFlowRow<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        AdventureWrappingHStack(content: content)
    }
}

/// Einfache umbrechende Reihe für wenige Kapseln.
struct AdventureWrappingHStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content() }
            VStack(alignment: .leading, spacing: 8) { content() }
        }
    }
}
