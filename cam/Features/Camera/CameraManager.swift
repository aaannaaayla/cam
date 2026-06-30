import AVFoundation
import CoreImage
import UIKit
import Combine

enum CameraError: LocalizedError {
    case notAuthorized, setupFailed, captureFailed
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Camera access denied. Enable in Settings."
        case .setupFailed: return "Camera setup failed."
        case .captureFailed: return "Failed to capture media."
        }
    }
}

enum CaptureMode { case photo, video }
enum CameraPosition { case back, front }

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isRecording: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var captureMode: CaptureMode = .photo
    @Published var position: CameraPosition = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var error: CameraError?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var recordingURL: URL?
    var onVideoCaptured: ((URL) -> Void)?
    var onPhotoCaptured: ((UIImage) -> Void)?

    override init() {
        super.init()
    }

    func requestAuthorization() async {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch videoStatus {
        case .authorized:
            isAuthorized = true
            await setupSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            if granted { await setupSession() }
        default:
            isAuthorized = false
        }
    }

    private func setupSession() async {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = bestCamera(for: position),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            session.commitConfiguration()
            error = .setupFailed
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer

        let session = self.session
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }

    func startSession() {
        guard !session.isRunning else { return }
        let session = self.session
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        let session = self.session
        Task.detached(priority: .background) {
            session.stopRunning()
        }
    }

    func switchCamera() {
        position = position == .back ? .front : .back
        Task { await switchInput() }
    }

    private func switchInput() async {
        guard let newDevice = bestCamera(for: position),
              let newInput = try? AVCaptureDeviceInput(device: newDevice)
        else { return }

        session.beginConfiguration()
        if let current = currentInput { session.removeInput(current) }
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentInput = newInput
        }
        session.commitConfiguration()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startVideoRecording() {
        guard !isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        recordingURL = url
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
    }

    func stopVideoRecording() {
        guard isRecording else { return }
        movieOutput.stopRecording()
        isRecording = false
    }

    func toggleFlash() {
        switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
    }

    private func bestCamera(for position: CameraPosition) -> AVCaptureDevice? {
        let pos: AVCaptureDevice.Position = position == .back ? .back : .front
        let types: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera
        ]
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: pos)
        return session.devices.first
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                  didFinishProcessingPhoto photo: AVCapturePhoto,
                                  error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor in
            self.capturedImage = image
            self.onPhotoCaptured?(image)
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                                 didFinishRecordingTo url: URL,
                                 from connections: [AVCaptureConnection],
                                 error: Error?) {
        Task { @MainActor in
            if error == nil {
                self.onVideoCaptured?(url)
            }
        }
    }
}
