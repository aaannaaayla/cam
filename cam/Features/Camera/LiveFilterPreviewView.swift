import SwiftUI
import AVFoundation
import MetalKit
import CoreImage

// Real-time camera preview that applies a CIFilter to every frame via Metal.
// Replaces the plain AVCaptureVideoPreviewLayer so "what you see is what you get."

final class LiveFilterPreviewCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate {
    private weak var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var ciContext: CIContext?
    private var currentCIImage: CIImage?
    private let lock = NSLock()

    var selectedFilter: FilterPreset = .original

    override init() { super.init() }

    /// Wires the coordinator to the on-screen MTKView. Called from makeUIView so
    /// the displayed view is the one we render into.
    func configure(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
        else { return }

        self.commandQueue = queue
        self.ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB()
        ])

        metalView.device = device
        metalView.framebufferOnly = false
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = self
        self.metalView = metalView
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var ciImage = CIImage(cvImageBuffer: imageBuffer)

        // Apply the selected filter to the live frame
        ciImage = selectedFilter.apply(to: ciImage)

        lock.lock()
        currentCIImage = ciImage
        lock.unlock()

        Task { @MainActor in self.metalView?.setNeedsDisplay() }
    }

    // MARK: MTKViewDelegate

    func draw(in view: MTKView) {
        lock.lock()
        let image = currentCIImage
        lock.unlock()

        guard let ciImage = image,
              let ciContext = ciContext,
              let commandQueue = commandQueue,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        let drawableSize = view.drawableSize
        guard ciImage.extent.width > 0, ciImage.extent.height > 0 else { return }

        let scaleX = drawableSize.width  / ciImage.extent.width
        let scaleY = drawableSize.height / ciImage.extent.height
        let scale = max(scaleX, scaleY)

        let scaledW = ciImage.extent.width  * scale
        let scaledH = ciImage.extent.height * scale
        let offsetX = (drawableSize.width  - scaledW) / 2
        let offsetY = (drawableSize.height - scaledH) / 2

        let scaled = ciImage
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        ciContext.render(
            scaled,
            to: drawable.texture,
            commandBuffer: commandBuffer,
            bounds: CGRect(origin: .zero, size: drawableSize),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

// MARK: - SwiftUI wrapper

struct LiveFilterPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraManager
    var selectedFilter: FilterPreset

    func makeCoordinator() -> LiveFilterPreviewCoordinator {
        LiveFilterPreviewCoordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = true
        metalView.autoResizeDrawable = true
        metalView.contentMode = .scaleAspectFill
        metalView.clipsToBounds = true

        // Wire the coordinator to THIS view, then start feeding it camera frames.
        context.coordinator.configure(metalView: metalView)
        context.coordinator.selectedFilter = selectedFilter
        camera.setVideoOutput(delegate: context.coordinator)
        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.selectedFilter = selectedFilter
    }
}

// MARK: - CameraManager video data output

extension CameraManager {
    func setVideoOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard !session.outputs.contains(where: { $0 is AVCaptureVideoDataOutput }) else { return }

        session.beginConfiguration()

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        let queue = DispatchQueue(label: "com.annayladesigns.cam.videoOutput", qos: .userInteractive)
        videoDataOutput.setSampleBufferDelegate(delegate, queue: queue)

        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            if let connection = videoDataOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }

        session.commitConfiguration()
    }
}
