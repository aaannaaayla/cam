import SwiftUI

enum GridPlatform: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .instagram: return "camera.filters"
        case .tiktok: return "music.note.tv.fill"
        }
    }

    var columns: Int { 3 }

    // Aspect ratio of each cell
    var cellAspectRatio: CGFloat {
        switch self {
        case .instagram: return 1.0     // square grid
        case .tiktok: return 9.0 / 16  // portrait grid
        }
    }

    var previewSlots: Int {
        switch self {
        case .instagram: return 12
        case .tiktok: return 9
        }
    }
}

struct GridPlan: Identifiable, Codable {
    let id: UUID
    var name: String
    var platform: String
    var slots: [GridSlot]
    var createdAt: Date
    var modifiedAt: Date

    init(platform: GridPlatform) {
        self.id = UUID()
        self.name = "\(platform.rawValue) Feed"
        self.platform = platform.rawValue
        self.slots = (0..<platform.previewSlots).map { GridSlot(position: $0) }
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

struct GridSlot: Identifiable, Codable {
    let id: UUID
    var position: Int
    var imageData: Data?
    var caption: String?
    var isPlanned: Bool

    init(position: Int) {
        self.id = UUID()
        self.position = position
        self.isPlanned = false
    }

    var hasContent: Bool { imageData != nil }
}
