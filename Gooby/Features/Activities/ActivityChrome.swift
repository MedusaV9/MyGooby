import SwiftUI

struct ActivityLanePage<Content: View>: View {
    var engine: GoobyEngine
    var lane: ActivityLane
    var heading: String? = nil
    var corner: String? = nil
    var cornerAction: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entered = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: 0x5C6B7A))
                            .frame(width: 36, height: 36)
                            .background(Color.white, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("look.back"))
                    Spacer()
                    if let corner, let cornerAction {
                        Button(action: cornerAction) {
                            Text("+ \(corner)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.22), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                ActivityMark(lane: lane)
                    .scaleEffect(1.55)
                    .frame(width: 58, height: 58)
                    .padding(.top, 2)
                Text(heading ?? engine.t(lane.titleKey))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .opacity(entered ? 1 : 0)
            .offset(y: entered ? 0 : 14)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background {
            ZStack(alignment: .top) {
                Color(hex: lane.canvas)
                Ellipse()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 560, height: 240)
                    .offset(y: -70)
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !entered else { return }
            if reduceMotion {
                entered = true
            } else {
                withAnimation(.spring(duration: 0.45)) { entered = true }
            }
        }
    }
}

struct ActivitySearchField: View {
    var prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(hex: 0x8B97A3))
            TextField(prompt, text: $text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ActivityFilterBar: View {
    var engine: GoobyEngine
    var filters: [String]
    var filter: String
    var starsOnly: Bool
    var onFilter: (String) -> Void
    var onStars: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { id in
                    chip(ActivityCatalog.filterTitle(id, engine), on: filter == id) { onFilter(id) }
                }
                chip(engine.t("activity.filter.stars"), on: starsOnly, action: onStars)
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(on ? Color(hex: 0x243041) : Color.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on ? Color.white : Color.white.opacity(0.22), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ActivityCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }
}

struct ActivityRowLabel: View {
    var title: String
    var detail: String
    var symbol: String
    var tint: UInt32
    var mark: String? = nil
    var badge: String = ""

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color(hex: tint))
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x243041))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0x7C8792))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            if !badge.isEmpty {
                HStack(spacing: 2) {
                    Text(badge)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x8B97A3))
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF0A020))
                }
                .accessibilityHidden(true)
            }
            if let mark {
                Image(systemName: mark)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x3EAE45))
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
}

struct ActivityStarButton: View {
    var on: Bool
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: on ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(on ? Color(hex: 0xE0A322) : Color(hex: 0xC5CED6))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(on ? "1" : "0")
    }
}

struct ActivityQuietNote: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActivityCapsuleLink<Destination: View>: View {
    var title: String
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x243041))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
