import SwiftUI

struct ActivitySkyView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var arrived = false

    private var calm: Bool { reduceMotion || systemReduce }

    var body: some View {
        ZStack {
            ActivitySkyBackdrop(reduceMotion: calm)
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(engine.t("look.back"))
                        Spacer()
                    }
                    ActivityPilot(engine: engine, reduceMotion: calm, arrived: arrived)
                        .padding(.bottom, 4)
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Array(ActivityLane.allCases.enumerated()), id: \.element.id) { index, lane in
                            NavigationLink {
                                ActivityDestination(engine: engine, reduceMotion: calm, lane: lane)
                            } label: {
                                ActivitySkyTile(title: engine.t(lane.tileKey), lane: lane)
                            }
                            .buttonStyle(ActivityPressStyle(reduceMotion: calm))
                            .opacity(arrived || calm ? 1 : 0)
                            .offset(y: arrived || calm ? 0 : 12)
                            .animation(
                                calm ? nil : .spring(duration: 0.45).delay(0.04 * Double(index)),
                                value: arrived
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !arrived else { return }
            if calm {
                arrived = true
            } else {
                withAnimation(.spring(duration: 0.7, bounce: 0.2)) { arrived = true }
            }
        }
    }
}

struct ActivityDestination: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var lane: ActivityLane

    var body: some View {
        switch lane {
        case .ideas:
            ActivityIdeasView(engine: engine)
        case .reflections:
            ActivityReflectionsView(engine: engine, reduceMotion: reduceMotion)
        case .kindness:
            ActivityKindnessView(engine: engine, reduceMotion: reduceMotion)
        default:
            ActivityLaneView(engine: engine, reduceMotion: reduceMotion, lane: lane)
        }
    }
}
