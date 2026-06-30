import SwiftUI

// A gradient swatch representing each filter's visual character.
// In production, render a real sample image through the filter.
struct FilterThumbnailView: View {
    let preset: FilterPreset

    var body: some View {
        ZStack {
            LinearGradient(
                colors: swatchColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack {
                Spacer()
                Text(preset.name)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(.bottom, 4)
            }
        }
    }

    // Derive a representative color gradient from the filter's adjustments
    private var swatchColors: [Color] {
        let adj = preset.adjustments

        // B&W filters
        if adj.saturation < 0.15 {
            let bright = 0.3 + Double(adj.brightness + 0.5) * 0.5
            return [Color(white: bright * 0.6), Color(white: bright), Color(white: bright * 0.75)]
        }

        // Base palette - warm mid-range skin/nature tones
        var warm = SIMD3<Float>(0.85, 0.72, 0.60)
        var cool = SIMD3<Float>(0.60, 0.72, 0.80)

        // Saturation
        let sat = adj.saturation
        warm = mix(SIMD3<Float>(0.72, 0.72, 0.72), warm, t: sat)
        cool = mix(SIMD3<Float>(0.70, 0.70, 0.70), cool, t: sat)

        // Warmth tint
        if adj.warmth > 0 {
            let tint = SIMD3<Float>(1.0, 0.85, 0.60)
            warm = mix(warm, tint, t: adj.warmth * 0.5)
            cool = mix(cool, tint, t: adj.warmth * 0.3)
        } else if adj.warmth < 0 {
            let tint = SIMD3<Float>(0.70, 0.85, 1.0)
            warm = mix(warm, tint, t: abs(adj.warmth) * 0.5)
            cool = mix(cool, tint, t: abs(adj.warmth) * 0.3)
        }

        // Fade to lifted blacks
        if adj.fade > 0 {
            let lifted = SIMD3<Float>(0.75, 0.73, 0.70)
            warm = mix(warm, lifted, t: adj.fade * 0.6)
            cool = mix(cool, lifted, t: adj.fade * 0.4)
        }

        // Brightness
        let b = 1.0 + adj.brightness * 1.5
        warm = clamp(warm * b, min: 0, max: 1)
        cool = clamp(cool * b, min: 0, max: 1)

        // Sepia overlay
        if adj.sepia > 0 {
            let sepiaTone = SIMD3<Float>(0.85, 0.72, 0.53)
            warm = mix(warm, sepiaTone, t: adj.sepia * 0.7)
            cool = mix(cool, sepiaTone, t: adj.sepia * 0.5)
        }

        return [
            simdToColor(cool * 0.85),
            simdToColor(warm),
            simdToColor(cool * 0.9)
        ]
    }

    private func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        a + (b - a) * max(0, min(1, t))
    }

    private func simdToColor(_ v: SIMD3<Float>) -> Color {
        Color(red: Double(v.x), green: Double(v.y), blue: Double(v.z))
    }
}
