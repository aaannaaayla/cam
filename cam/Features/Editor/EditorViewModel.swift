import SwiftUI
import CoreImage
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var selectedFilter: FilterPreset = .original
    @Published var adjustments: UserAdjustments = UserAdjustments()
    @Published var processedImage: UIImage?

    private let originalImage: UIImage
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private var processingTask: Task<Void, Never>?

    init(mediaItem: MediaItem, initialFilter: FilterPreset = .original) {
        self.originalImage = mediaItem.image ?? UIImage()
        self.processedImage = mediaItem.image
        self.selectedFilter = initialFilter
        observeChanges()
        // observeChanges() drops the initial value, so render the carried-over
        // filter once if it isn't the no-op Original.
        if initialFilter.id != FilterPreset.original.id {
            Task { await processImage() }
        }
    }

    private func observeChanges() {
        Task {
            for await _ in $selectedFilter.values.dropFirst() {
                await processImage()
            }
        }
        Task {
            for await _ in $adjustments.values.dropFirst() {
                await processImage()
            }
        }
    }

    func processImage() async {
        processingTask?.cancel()
        processingTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let filter = await self.selectedFilter
            let adj = await self.adjustments
            let original = await self.originalImage

            guard let ciImage = CIImage(image: original) else { return }
            try? Task.checkCancellation()

            // Apply selected filter preset
            var result = filter.apply(to: ciImage)

            // Apply user-level adjustments on top
            if adj.exposure != 0 {
                if let f = CIFilter(name: "CIExposureAdjust") {
                    f.setValue(result, forKey: kCIInputImageKey)
                    f.setValue(adj.exposure, forKey: kCIInputEVKey)
                    result = f.outputImage ?? result
                }
            }
            if adj.brightness != 0 || adj.contrast != 1 || adj.saturation != 1 {
                if let f = CIFilter(name: "CIColorControls") {
                    f.setValue(result, forKey: kCIInputImageKey)
                    f.setValue(adj.saturation, forKey: kCIInputSaturationKey)
                    f.setValue(adj.brightness, forKey: kCIInputBrightnessKey)
                    f.setValue(adj.contrast, forKey: kCIInputContrastKey)
                    result = f.outputImage ?? result
                }
            }
            if adj.sharpness > 0 {
                if let f = CIFilter(name: "CISharpenLuminance") {
                    f.setValue(result, forKey: kCIInputImageKey)
                    f.setValue(adj.sharpness, forKey: kCIInputSharpnessKey)
                    result = f.outputImage ?? result
                }
            }

            try? Task.checkCancellation()
            let ctx = await self.context
            guard let cgImage = ctx.createCGImage(result, from: result.extent) else { return }
            let output = UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
            await MainActor.run { self.processedImage = output }
        }
    }
}
