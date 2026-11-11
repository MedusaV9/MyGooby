import SwiftUI

struct SettingsSleepingHead: View {
    var engine: GoobyEngine

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -7) {
                Text(line)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 280)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Look.shadow, radius: 8, y: 3)
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
            }
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color(hex: 0xF3D7C3))
                    .frame(width: 176, height: 46)
                    .offset(y: 8)
                Ellipse()
                    .fill(Color(hex: 0xE7C4A8))
                    .frame(width: 118, height: 22)
                    .offset(y: 12)
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: .sleep,
                    reduceMotion: engine.reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 210, height: 148)
                .offset(y: 16)
                .accessibilityHidden(true)
            }
            .frame(height: 156)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(line)
    }

    private var line: String {
        let keys = ["look.sleep.1", "look.sleep.2", "look.sleep.3"]
        let index = SettingsSleepingHead.index(for: engine.dayKey(), count: keys.count)
        return engine.tf(keys[index], petName)
    }

    private var petName: String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    private static func index(for day: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var hash = 0
        for byte in day.utf8 {
            hash = (hash &* 33 &+ Int(byte)) & 0x7FFF_FFFF
        }
        return hash % count
    }
}
