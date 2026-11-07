import AVFoundation
import Combine
import Foundation

enum SoundscapeKind: String, CaseIterable, Identifiable {
    case rain
    case ocean
    case forest
    case wind
    case fire
    case nature

    var id: String { rawValue }

    var title: CareString {
        switch self {
        case .rain: return .soundRain
        case .ocean: return .soundOcean
        case .forest: return .soundForest
        case .wind: return .soundWind
        case .fire: return .soundFire
        case .nature: return .soundNature
        }
    }

    fileprivate var seed: UInt64 {
        switch self {
        case .rain: return 11
        case .ocean: return 29
        case .forest: return 47
        case .wind: return 71
        case .fire: return 97
        case .nature: return 131
        }
    }
}

@MainActor
final class SoundscapePlayer: ObservableObject {
    @Published private(set) var current: SoundscapeKind?
    @Published private(set) var failed = false
    private var player: AVAudioPlayer?
    private var cache: [SoundscapeKind: Data] = [:]

    func toggle(_ kind: SoundscapeKind) {
        if current == kind {
            stop()
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let data = cache[kind] ?? SoundscapeSynth.wav(kind: kind)
            cache[kind] = data
            let next = try AVAudioPlayer(data: data)
            next.numberOfLoops = -1
            next.volume = 0.4
            next.prepareToPlay()
            guard next.play() else {
                failed = true
                current = nil
                player = nil
                return
            }
            player = next
            current = kind
            failed = false
        } catch {
            failed = true
            current = nil
            player = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        current = nil
    }
}

/// Quiet loops made on device. These are not recordings and never a network stream.
enum SoundscapeSynth {
    static func wav(kind: SoundscapeKind) -> Data {
        let sampleRate = 22_050
        let count = sampleRate * 8
        var noise = Noise(seed: kind.seed)
        var low = 0.0
        var band = 0.0
        var phase = 0.0
        var chirp = 0
        var chirpFreq = 880.0
        var chirpPhase = 0.0
        var samples: [Int16] = []
        samples.reserveCapacity(count)
        for index in 0..<count {
            let time = Double(index) / Double(sampleRate)
            let white = noise.next()
            let sample = render(
                kind: kind,
                time: time,
                white: white,
                sampleRate: sampleRate,
                low: &low,
                band: &band,
                phase: &phase,
                chirp: &chirp,
                chirpFreq: &chirpFreq,
                chirpPhase: &chirpPhase
            )
            let clipped = min(0.2, max(-0.2, sample))
            samples.append(Int16(clipped * 8_000))
        }
        return pcm16(samples: samples, sampleRate: sampleRate)
    }

    private static func render(
        kind: SoundscapeKind,
        time: Double,
        white: Double,
        sampleRate: Int,
        low: inout Double,
        band: inout Double,
        phase: inout Double,
        chirp: inout Int,
        chirpFreq: inout Double,
        chirpPhase: inout Double
    ) -> Double {
        switch kind {
        case .rain:
            low += (white - low) * 0.08
            let drip = sin(time * 2.7) > 0.985 ? sin(time * 90) * 0.12 : 0
            return low * 0.2 + drip
        case .ocean:
            low += (white - low) * 0.03
            let swell = 0.55 + 0.45 * sin(time * 0.7)
            return low * 0.26 * swell
        case .forest:
            low += (white - low) * 0.05
            band += (low - band) * 0.2
            if chirp <= 0 && white > 0.993 {
                chirp = sampleRate / 7
                chirpFreq = 740 + (white + 1) * 420
            }
            var bird = 0.0
            if chirp > 0 {
                chirpPhase += chirpFreq / Double(sampleRate)
                let envelope = Double(chirp) / Double(sampleRate / 7)
                bird = sin(chirpPhase * 2 * .pi) * 0.045 * envelope
                chirp -= 1
            }
            return (low - band) * 0.1 + bird
        case .wind:
            low += (white - low) * 0.14
            band += (low - band) * 0.18
            let gust = 0.4 + 0.6 * (0.5 + 0.5 * sin(time * 0.45))
            return (low - band) * 0.32 * gust
        case .fire:
            low += (white - low) * 0.02
            let crack = white > 0.975 ? white * 0.18 : 0
            return low * 0.16 + crack
        case .nature:
            low += (white - low) * 0.04
            let notes = [196.0, 247.0, 294.0, 330.0, 392.0]
            let note = notes[Int(time / 1.5) % notes.count]
            phase += note / Double(sampleRate)
            let tone = sin(phase * 2 * .pi) * 0.028
            return low * 0.07 + tone
        }
    }

    private static func pcm16(samples: [Int16], sampleRate: Int) -> Data {
        let dataBytes = samples.count * 2
        var bytes: [UInt8] = []
        bytes.reserveCapacity(44 + dataBytes)
        bytes.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        append(&bytes, UInt32(36 + dataBytes))
        bytes.append(contentsOf: [0x57, 0x41, 0x56, 0x45])
        bytes.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])
        append(&bytes, UInt32(16))
        append(&bytes, UInt16(1))
        append(&bytes, UInt16(1))
        append(&bytes, UInt32(sampleRate))
        append(&bytes, UInt32(sampleRate * 2))
        append(&bytes, UInt16(2))
        append(&bytes, UInt16(16))
        bytes.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        append(&bytes, UInt32(dataBytes))
        for sample in samples {
            let value = UInt16(bitPattern: sample)
            bytes.append(UInt8(value & 0xFF))
            bytes.append(UInt8((value >> 8) & 0xFF))
        }
        return Data(bytes)
    }

    private static func append(_ bytes: inout [UInt8], _ value: UInt32) {
        bytes.append(UInt8(value & 0xFF))
        bytes.append(UInt8((value >> 8) & 0xFF))
        bytes.append(UInt8((value >> 16) & 0xFF))
        bytes.append(UInt8((value >> 24) & 0xFF))
    }

    private static func append(_ bytes: inout [UInt8], _ value: UInt16) {
        bytes.append(UInt8(value & 0xFF))
        bytes.append(UInt8((value >> 8) & 0xFF))
    }
}

private struct Noise {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        let bits = state >> 33
        return Double(bits) / Double(1 << 31) * 2 - 1
    }
}
