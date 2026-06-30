import SwiftUI
import AVFoundation
import MetalKit
import CoreImage

// Real-time camera preview that applies a CIFilter to every frame via Metal.
// Replaces the plain AVCaptureVideoPreviewLayer so "what you see is what you get."

final class LiveFilterPreviewCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate {
    private let metalView: MTKView
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext
    private var currentCIImage: CIImage?
    private let lock = NSLock()

    var selectedFilter: FilterPreset = .original

    init(metalView: MTKView) {
        self.metalView = metalView

        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
        else { fatalError("Metal is required for live filter preview") }

        self.commandQueue = queue
        self.ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            .outputColorSpace: CGColorSpaceCreateDeviceRGB()
        ])

        metalView.device = device
        metalView.framebufferOnly = false
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm

        super.init()
        metalView.delegate = self
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var ciImage = CIImage(cvImageBuffer: imageBuffer)

        // Mirror front-camera output
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }

        // Apply the selected filter
        ciImage = selectedFilter.apply(to: ciImage)

        lock.lock()
        currentCIImage = ciImage
        lock.unlock()

        metalView.setNeedsDisplay()
    }

    // MTKViewDelegate
    func draw(in view: MTKView) {
        lock.lock()
        let image = currentCIImage
        lock.unlock()

        guard let ciImage = image,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        let drawableSize = view.drawableSize
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

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = true
        metalView.autoResizeDrawable = true
        metalView.contentMode = .scaleAspectFill
        metalView.clipsToBounds = true
        return metalView
    }

    func makeCoordinator() -> LiveFilterPreviewCoordinator {
        let metalView = MTKView()
        let coordinator = LiveFilterPreviewCoordinator(metalView: metalView)
        camera.setVideoOutput(delegate: coordinator)
        return coordinator
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.selectedFilter = selectedFilter

        // Re-wire the Metal view if needed (e.g. on first appearance)
        if uiView.device == nil {
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            uiView.device = device
            uiView.framebufferOnly = false
            uiView.colorPixelFormat = .bgra8Unorm
            uiView.delegate = context.coordinator
        }
    }
}

// MARK: - CameraManager extension for video data output

extension CameraManager {
    func setVideoOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard session.isRunning == false || !session.outputs.contains(where: { $0 is AVCaptureVideoDataOutput }) else { return }

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
            // Prefer portrait orientation
            if let connection = videoDataOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }
        }

        session.commitConfiguration()
    }
}
