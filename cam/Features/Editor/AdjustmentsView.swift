import SwiftUI

struct AdjustmentsView: View {
    @Binding var adjustments: UserAdjustments
    let isPro: Bool

    private struct AdjSlider {
        let label: String
        let icon: String
        let range: ClosedRange<Float>
        let isPro: Bool
        let keyPath: WritableKeyPath<UserAdjustments, Float>
    }

    private let freeSliders: [AdjSlider] = [
        AdjSlider(label: "Brightness", icon: "sun.max", range: -0.5...0.5, isPro: false, keyPath: \.brightness),
        AdjSlider(label: "Contrast", icon: "circle.lefthalf.filled", range: 0.5...1.5, isPro: false, keyPath: \.contrast),
        AdjSlider(label: "Saturation", icon: "drop", range: 0...2, isPro: false, keyPath: \.saturation),
        AdjSlider(label: "Warmth", icon: "thermometer.medium", range: -1...1, isPro: false, keyPath: \.warmth),
    ]

    private let proSliders: [AdjSlider] = [
        AdjSlider(label: "Exposure", icon: "camera.aperture", range: -2...2, isPro: true, keyPath: \.exposure),
        AdjSlider(label: "Highlights", icon: "sun.min", range: -1...1, isPro: true, keyPath: \.highlights),
        AdjSlider(label: "Shadows", icon: "moon", range: -1...1, isPro: true, keyPath: \.shadows),
        AdjSlider(label: "Sharpness", icon: "diamond", range: 0...1, isPro: true, keyPath: \.sharpness),
        AdjSlider(label: "Vignette", icon: "circle.inset.filled", range: 0...1, isPro: true, keyPath: \.vignette),
        AdjSlider(label: "Grain", icon: "film.stack", range: 0...1, isPro: true, keyPath: \.grain),
        AdjSlider(label: "Fade", icon: "square.dashed", range: 0...1, isPro: true, keyPath: \.fade),
    ]

    private var visibleSliders: [AdjSlider] {
        freeSliders + (isPro ? proSliders : [])
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(visibleSliders, id: \.label) { slider in
                    AdjustmentKnob(
                        label: slider.label,
                        icon: slider.icon,
                        value: Binding(
                            get: { adjustments[keyPath: slider.keyPath] },
                            set: { adjustments[keyPath: slider.keyPath] = $0 }
                        ),
                        range: slider.range,
                        defaultValue: defaultValue(for: slider.keyPath)
                    )
                }

                if !isPro {
                    ProUpgradeCell()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func defaultValue(for kp: WritableKeyPath<UserAdjustments, Float>) -> Float {
        switch kp {
        case \.contrast, \.saturation: return 1.0
        default: return 0.0
        }
    }
}

// MARK: - Adjustment Knob

private struct AdjustmentKnob: View {
    let label: String
    let icon: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float

    @GestureState private var dragOffset: CGFloat = 0
    @State private var baseValue: Float = 0

    private var normalizedValue: Float {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.camBorder, lineWidth: 2)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(normalizedValue))
                    .stroke(Color.camAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isAtDefault ? .white.opacity(0.5) : .white)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let delta = Float(-gesture.translation.height / 120)
                        value = max(range.lowerBound, min(range.upperBound, baseValue + delta))
                    }
                    .onEnded { _ in baseValue = value }
            )
            .onTapGesture(count: 2) {
                withAnimation { value = defaultValue; baseValue = defaultValue }
            }

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)

            Text(displayValue)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(isAtDefault ? .white.opacity(0.3) : Color.camAccent)
        }
        .frame(width: 70)
    }

    private var isAtDefault: Bool { abs(value - defaultValue) < 0.01 }

    private var displayValue: String {
        let normalized = (value - defaultValue) * 100
        return String(format: "%+.0f", normalized)
    }
}

// MARK: - Pro Upgrade Cell

private struct ProUpgradeCell: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.camAccentSoft)
                    .frame(width: 56, height: 56)
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.camAccent)
            }
            Text("More")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            Text("Pro")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.camAccent)
        }
        .frame(width: 70)
    }
}
