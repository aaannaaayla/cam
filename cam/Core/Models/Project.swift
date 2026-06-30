import SwiftUI

// MARK: - Collage / Scrapbook Project

enum ProjectType: String, Codable {
    case collage, scrapbook
}

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: ProjectType
    var layout: CollageLayout?
    var elements: [CanvasElement]
    var canvasAspectRatio: CGFloat
    var backgroundColor: CodableColor
    var createdAt: Date
    var modifiedAt: Date
    var thumbnailData: Data?

    init(name: String = "Untitled", type: ProjectType = .collage) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.elements = []
        self.canvasAspectRatio = 1.0
        self.backgroundColor = CodableColor(r: 1, g: 1, b: 1, a: 1)
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

struct CodableColor: Codable {
    var r, g, b, a: Double
    var color: Color { Color(red: r, green: g, blue: b, opacity: a) }
}

// MARK: - Canvas Elements

enum ElementType: String, Codable {
    case image, text, sticker, shape
}

struct CanvasElement: Identifiable, Codable {
    let id: UUID
    var type: ElementType
    var frame: CGRect
    var rotation: Double
    var zIndex: Int

    // Image
    var imageData: Data?

    // Text
    var text: String?
    var fontSize: Double?
    var fontWeight: String?
    var textColor: CodableColor?
    var textAlignment: String?

    // Sticker
    var stickerName: String?   // SF Symbol or asset name

    // Shape
    var shapeName: String?
    var fillColor: CodableColor?
    var strokeColor: CodableColor?
    var strokeWidth: Double?

    init(type: ElementType, frame: CGRect = .zero) {
        self.id = UUID()
        self.type = type
        self.frame = frame
        self.rotation = 0
        self.zIndex = 0
    }
}

// MARK: - Collage Layouts

struct CollageLayout: Identifiable, Codable {
    let id: String
    let name: String
    let slots: [LayoutSlot]
    let aspectRatio: CGFloat
    let isPro: Bool
}

struct LayoutSlot: Identifiable, Codable {
    let id: String
    let frame: CGRect  // normalized 0-1
}

extension CollageLayout {
    static let allLayouts: [CollageLayout] = [
        // Free layouts
        CollageLayout(id: "single", name: "Single", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        ], aspectRatio: 1.0, isPro: false),

        CollageLayout(id: "split_h", name: "Side by Side", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.497, height: 1)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0.503, y: 0, width: 0.497, height: 1))
        ], aspectRatio: 1.0, isPro: false),

        CollageLayout(id: "split_v", name: "Stack", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 1, height: 0.497)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0, y: 0.503, width: 1, height: 0.497))
        ], aspectRatio: 1.0, isPro: false),

        CollageLayout(id: "trio", name: "Trio", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 1, height: 0.497)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0, y: 0.503, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0.503, y: 0.503, width: 0.497, height: 0.497))
        ], aspectRatio: 1.0, isPro: false),

        // Pro layouts
        CollageLayout(id: "quad", name: "Quad", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0.503, y: 0, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0, y: 0.503, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s4", frame: CGRect(x: 0.503, y: 0.503, width: 0.497, height: 0.497))
        ], aspectRatio: 1.0, isPro: true),

        CollageLayout(id: "feature_left", name: "Feature Left", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.66, height: 1)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0.67, y: 0, width: 0.33, height: 0.497)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0.67, y: 0.503, width: 0.33, height: 0.497))
        ], aspectRatio: 1.0, isPro: true),

        CollageLayout(id: "feature_right", name: "Feature Right", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.33, height: 0.497)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0, y: 0.503, width: 0.33, height: 0.497)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0.34, y: 0, width: 0.66, height: 1))
        ], aspectRatio: 1.0, isPro: true),

        CollageLayout(id: "strip_3", name: "Strip", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.328, height: 1)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0.336, y: 0, width: 0.328, height: 1)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0.672, y: 0, width: 0.328, height: 1))
        ], aspectRatio: 0.75, isPro: true),

        CollageLayout(id: "banner_top", name: "Banner", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 1, height: 0.35)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0, y: 0.36, width: 0.497, height: 0.64)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0.503, y: 0.36, width: 0.497, height: 0.64))
        ], aspectRatio: 1.0, isPro: true),

        CollageLayout(id: "five", name: "Five", slots: [
            LayoutSlot(id: "s1", frame: CGRect(x: 0, y: 0, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s2", frame: CGRect(x: 0.503, y: 0, width: 0.497, height: 0.497)),
            LayoutSlot(id: "s3", frame: CGRect(x: 0, y: 0.503, width: 0.328, height: 0.497)),
            LayoutSlot(id: "s4", frame: CGRect(x: 0.336, y: 0.503, width: 0.328, height: 0.497)),
            LayoutSlot(id: "s5", frame: CGRect(x: 0.672, y: 0.503, width: 0.328, height: 0.497))
        ], aspectRatio: 1.0, isPro: true),
    ]

    static var free: [CollageLayout] { allLayouts.filter { !$0.isPro } }
    static var pro: [CollageLayout] { allLayouts.filter { $0.isPro } }
}
