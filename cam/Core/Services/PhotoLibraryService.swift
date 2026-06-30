import Photos
import UIKit
import SwiftUI

@MainActor
class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    private init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        authorizationStatus = status
        return status
    }

    func saveImage(_ image: UIImage) async throws {
        let status = await requestAuthorization()
        guard status == .authorized || status == .limited else {
            throw LibraryError.notAuthorized
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }
    }

    func saveVideo(at url: URL) async throws {
        let status = await requestAuthorization()
        guard status == .authorized || status == .limited else {
            throw LibraryError.notAuthorized
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    enum LibraryError: LocalizedError {
        case notAuthorized
        var errorDescription: String? {
            switch self {
            case .notAuthorized: return "Please allow photo library access in Settings."
            }
        }
    }
}
