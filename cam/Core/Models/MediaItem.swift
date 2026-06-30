import SwiftUI
import Photos

enum MediaType {
    case photo, video
}

struct MediaItem: Identifiable, Equatable {
    let id: UUID
    var image: UIImage?
    var videoURL: URL?
    var mediaType: MediaType
    var appliedFilterID: String?
    var customAdjustments: UserAdjustments?
    var createdAt: Date

    init(image: UIImage) {
        self.id = UUID()
        self.image = image
        self.mediaType = .photo
        self.createdAt = Date()
    }

    init(videoURL: URL) {
        self.id = UUID()
        self.videoURL = videoURL
        self.mediaType = .video
        self.createdAt = Date()
    }

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool { lhs.id == rhs.id }
}

struct UserAdjustments: Codable {
    var brightness: Float = 0.0    // -1 to 1
    var contrast: Float = 1.0      // 0.5 to 1.5
    var saturation: Float = 1.0    // 0 to 2
    var warmth: Float = 0.0        // -1 to 1
    var highlights: Float = 0.0    // -1 to 1
    var shadows: Float = 0.0       // -1 to 1
    var sharpness: Float = 0.0     // 0 to 1
    var vignette: Float = 0.0      // 0 to 1
    var grain: Float = 0.0         // 0 to 1
    var fade: Float = 0.0          // 0 to 1
    var exposure: Float = 0.0      // -2 to 2 (EV)

    var isModified: Bool {
        brightness != 0 || contrast != 1 || saturation != 1 ||
        warmth != 0 || highlights != 0 || shadows != 0 ||
        sharpness != 0 || vignette != 0 || grain != 0 ||
        fade != 0 || exposure != 0
    }
}
