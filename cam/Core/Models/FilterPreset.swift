import CoreImage
import UIKit

struct FilterPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let isPro: Bool
    let category: Category
    let adjustments: FilterAdjustments

    enum Category: String, CaseIterable {
        case film = "Film"
        case moody = "Moody"
        case bright = "Bright"
        case aesthetic = "Aesthetic"
        case bw = "B&W"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FilterPreset, rhs: FilterPreset) -> Bool { lhs.id == rhs.id }

    func apply(to image: CIImage) -> CIImage {
        var result = image
        let adj = adjustments

        if adj.saturation != 1.0 || adj.brightness != 0.0 || adj.contrast != 1.0 {
            if let f = CIFilter(name: "CIColorControls") {
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(adj.saturation, forKey: kCIInputSaturationKey)
                f.setValue(adj.brightness, forKey: kCIInputBrightnessKey)
                f.setValue(adj.contrast, forKey: kCIInputContrastKey)
                result = f.outputImage ?? result
            }
        }

        if adj.warmth != 0.0 {
            if let f = CIFilter(name: "CITemperatureAndTint") {
                let neutral = CIVector(x: 6500 + CGFloat(adj.warmth * 2000), y: 0)
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(neutral, forKey: "inputNeutral")
                result = f.outputImage ?? result
            }
        }

        if adj.highlights != 0.0 || adj.shadows != 0.0 {
            if let f = CIFilter(name: "CIHighlightShadowAdjust") {
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(1.0 + adj.highlights, forKey: "inputHighlightAmount")
                f.setValue(adj.shadows, forKey: "inputShadowAmount")
                result = f.outputImage ?? result
            }
        }

        if adj.vignette > 0.0 {
            if let f = CIFilter(name: "CIVignette") {
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(adj.vignette, forKey: kCIInputIntensityKey)
                f.setValue(1.5, forKey: kCIInputRadiusKey)
                result = f.outputImage ?? result
            }
        }

        if adj.grain > 0.0 {
            let noise = CIFilter(name: "CIRandomGenerator")?.outputImage
            if let noise = noise, let blendFilter = CIFilter(name: "CISourceOverCompositing") {
                let scaledNoise = noise.applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputAVector": CIVector(x: adj.grain * 0.3, y: 0, z: 0, w: 0),
                    "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: adj.grain * 0.05)
                ]).cropped(to: result.extent)
                blendFilter.setValue(scaledNoise, forKey: kCIInputImageKey)
                blendFilter.setValue(result, forKey: kCIInputBackgroundImageKey)
                result = blendFilter.outputImage ?? result
            }
        }

        if adj.fade > 0.0 {
            if let f = CIFilter(name: "CIColorMatrix") {
                let scale = 1.0 - adj.fade * 0.15
                let bias = adj.fade * 0.08
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(CIVector(x: CGFloat(scale), y: 0, z: 0, w: 0), forKey: "inputRVector")
                f.setValue(CIVector(x: 0, y: CGFloat(scale), z: 0, w: 0), forKey: "inputGVector")
                f.setValue(CIVector(x: 0, y: 0, z: CGFloat(scale), w: 0), forKey: "inputBVector")
                f.setValue(CIVector(x: CGFloat(bias), y: CGFloat(bias), z: CGFloat(bias), w: 0), forKey: "inputBiasVector")
                result = f.outputImage ?? result
            }
        }

        if adj.sepia > 0.0 {
            if let f = CIFilter(name: "CISepiaTone") {
                f.setValue(result, forKey: kCIInputImageKey)
                f.setValue(adj.sepia, forKey: kCIInputIntensityKey)
                result = f.outputImage ?? result
            }
        }

        return result
    }
}

struct FilterAdjustments {
    var saturation: Float = 1.0
    var brightness: Float = 0.0
    var contrast: Float = 1.0
    var warmth: Float = 0.0
    var highlights: Float = 0.0
    var shadows: Float = 0.0
    var vignette: Float = 0.0
    var grain: Float = 0.0
    var fade: Float = 0.0
    var sepia: Float = 0.0
}

// MARK: - Preset Library
extension FilterPreset {

    static let original = FilterPreset(
        id: "original", name: "Original", isPro: false, category: .bright,
        adjustments: FilterAdjustments()
    )

    // Free filters
    static let allFree: [FilterPreset] = [
        original,
        FilterPreset(id: "linen", name: "Linen", isPro: false, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.85, brightness: 0.04, contrast: 0.95, warmth: 0.15, fade: 0.3)),
        FilterPreset(id: "bright", name: "Bright", isPro: false, category: .bright,
            adjustments: FilterAdjustments(saturation: 1.05, brightness: 0.08, contrast: 1.05)),
        FilterPreset(id: "warm", name: "Warm", isPro: false, category: .bright,
            adjustments: FilterAdjustments(saturation: 1.0, brightness: 0.02, contrast: 1.02, warmth: 0.4)),
        FilterPreset(id: "cool", name: "Cool", isPro: false, category: .bright,
            adjustments: FilterAdjustments(saturation: 0.95, brightness: 0.02, warmth: -0.3)),
        FilterPreset(id: "fade", name: "Fade", isPro: false, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.8, contrast: 0.9, fade: 0.6)),
        FilterPreset(id: "matte", name: "Matte", isPro: false, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.75, contrast: 0.88, fade: 0.5, vignette: 0.2)),
        FilterPreset(id: "bw", name: "B&W", isPro: false, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, contrast: 1.1)),
        FilterPreset(id: "golden", name: "Golden", isPro: false, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 1.1, brightness: 0.05, warmth: 0.5, highlights: 0.1)),
        FilterPreset(id: "haze", name: "Haze", isPro: false, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.7, brightness: 0.06, contrast: 0.85, fade: 0.45, vignette: 0.15)),
        FilterPreset(id: "pop", name: "Pop", isPro: false, category: .bright,
            adjustments: FilterAdjustments(saturation: 1.3, brightness: 0.04, contrast: 1.15)),
        FilterPreset(id: "vintage", name: "Vintage", isPro: false, category: .film,
            adjustments: FilterAdjustments(saturation: 0.8, brightness: -0.02, contrast: 0.95, warmth: 0.3, vignette: 0.35, grain: 0.4, fade: 0.25, sepia: 0.15)),
    ]

    // Pro filters
    static let allPro: [FilterPreset] = [
        // Film series
        FilterPreset(id: "pro_portra", name: "Portra", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 0.9, brightness: 0.03, contrast: 0.93, warmth: 0.25, highlights: 0.05, shadows: 0.1, fade: 0.2, grain: 0.25)),
        FilterPreset(id: "pro_kodak", name: "Kodak", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 1.05, brightness: 0.04, contrast: 0.97, warmth: 0.2, highlights: 0.08, grain: 0.3, fade: 0.15)),
        FilterPreset(id: "pro_fuji", name: "Fuji", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 1.1, brightness: 0.02, contrast: 1.0, warmth: -0.1, highlights: -0.05, grain: 0.2)),
        FilterPreset(id: "pro_ilford", name: "Ilford", isPro: true, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, brightness: -0.03, contrast: 1.2, vignette: 0.4, grain: 0.45)),
        FilterPreset(id: "pro_ektar", name: "Ektar", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 1.25, brightness: 0.02, contrast: 1.1, warmth: 0.15, vignette: 0.2, grain: 0.15)),
        FilterPreset(id: "pro_cinestill", name: "Cinestill", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 0.95, brightness: 0.04, contrast: 0.95, warmth: 0.35, highlights: 0.15, vignette: 0.3, grain: 0.35)),
        FilterPreset(id: "pro_disposable", name: "Disposable", isPro: true, category: .film,
            adjustments: FilterAdjustments(saturation: 0.85, brightness: 0.06, contrast: 0.92, warmth: 0.2, vignette: 0.5, grain: 0.6, fade: 0.3)),

        // Moody series
        FilterPreset(id: "pro_shadow", name: "Shadow", isPro: true, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.7, brightness: -0.06, contrast: 1.1, shadows: -0.15, vignette: 0.5)),
        FilterPreset(id: "pro_deep", name: "Deep", isPro: true, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.85, brightness: -0.04, contrast: 1.15, warmth: -0.15, vignette: 0.4)),
        FilterPreset(id: "pro_noir", name: "Noir", isPro: true, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, brightness: -0.05, contrast: 1.3, vignette: 0.6)),
        FilterPreset(id: "pro_moody", name: "Moody", isPro: true, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.75, brightness: -0.02, contrast: 1.05, warmth: 0.1, shadows: -0.1, vignette: 0.35, grain: 0.2)),
        FilterPreset(id: "pro_cinematic", name: "Cinematic", isPro: true, category: .moody,
            adjustments: FilterAdjustments(saturation: 0.8, brightness: 0.0, contrast: 1.08, warmth: 0.08, highlights: -0.1, shadows: 0.05, vignette: 0.45)),

        // Aesthetic series
        FilterPreset(id: "pro_cream", name: "Cream", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.75, brightness: 0.07, contrast: 0.88, warmth: 0.3, fade: 0.4)),
        FilterPreset(id: "pro_blush", name: "Blush", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.8, brightness: 0.06, contrast: 0.9, warmth: 0.25, fade: 0.35)),
        FilterPreset(id: "pro_sage", name: "Sage", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.7, brightness: 0.04, contrast: 0.92, warmth: -0.2, fade: 0.25)),
        FilterPreset(id: "pro_dusty", name: "Dusty", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.65, brightness: 0.05, contrast: 0.88, warmth: 0.15, fade: 0.5, grain: 0.2)),
        FilterPreset(id: "pro_peach", name: "Peach", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.85, brightness: 0.07, contrast: 0.93, warmth: 0.35, fade: 0.2)),
        FilterPreset(id: "pro_morning", name: "Morning", isPro: true, category: .aesthetic,
            adjustments: FilterAdjustments(saturation: 0.9, brightness: 0.09, contrast: 0.95, warmth: 0.2, highlights: 0.08, fade: 0.15)),

        // Bright series
        FilterPreset(id: "pro_clean", name: "Clean", isPro: true, category: .bright,
            adjustments: FilterAdjustments(saturation: 0.95, brightness: 0.06, contrast: 1.0, warmth: 0.05, highlights: 0.05)),
        FilterPreset(id: "pro_airy", name: "Airy", isPro: true, category: .bright,
            adjustments: FilterAdjustments(saturation: 0.85, brightness: 0.1, contrast: 0.9, warmth: 0.1, highlights: 0.12, fade: 0.2)),
        FilterPreset(id: "pro_sunlit", name: "Sunlit", isPro: true, category: .bright,
            adjustments: FilterAdjustments(saturation: 1.1, brightness: 0.08, contrast: 1.05, warmth: 0.4, highlights: 0.1)),
        FilterPreset(id: "pro_overexposed", name: "Overexposed", isPro: true, category: .bright,
            adjustments: FilterAdjustments(saturation: 0.7, brightness: 0.15, contrast: 0.85, highlights: 0.2, fade: 0.3)),

        // B&W series
        FilterPreset(id: "pro_silver", name: "Silver", isPro: true, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, brightness: 0.04, contrast: 1.05, grain: 0.15)),
        FilterPreset(id: "pro_fade_bw", name: "Faded", isPro: true, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, brightness: 0.05, contrast: 0.9, fade: 0.4, grain: 0.3)),
        FilterPreset(id: "pro_contrast_bw", name: "Stark", isPro: true, category: .bw,
            adjustments: FilterAdjustments(saturation: 0.0, brightness: -0.02, contrast: 1.4, vignette: 0.3)),
    ]

    static var all: [FilterPreset] { allFree + allPro }
}
