import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var camera = CameraManager()
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedFilter: FilterPreset = .original
    @State private var showFilterStrip = true
    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var capturedMedia: MediaItem?
    @State private var holdingShutter = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isAuthorized {
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        // Live Metal preview — applies selected filter in real-time
                        LiveFilterPreviewView(camera: camera, selectedFilter: selectedFilter)
                            .ignoresSafeArea()

                        VStack(spacing: 0) {
                            // Top controls
                            topBar
                                .padding(.top, geo.safeAreaInsets.top + 8)

                            Spacer()

                            // Filter strip
                            if showFilterStrip {
                                FilterStripView(
                                    selected: $selectedFilter,
                                    isPro: subscriptionManager.isPro,
                                    onProTap: { showPaywall = true }
                                )
                                .padding(.bottom, 12)
                            }

                            // Bottom controls
                            bottomBar
                                .padding(.bottom, geo.safeAreaInsets.bottom + 12)
                        }
                    }
                }
            } else {
                cameraPermissionView
            }
        }
        .task { await camera.requestAuthorization() }
        .onAppear { camera.startSession() }
        .onDisappear { camera.stopSession() }
        .sheet(isPresented: $showEditor) {
            if let media = capturedMedia {
                EditorView(mediaItem: media)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: camera.capturedImage) { _, image in
            guard let image else { return }
            capturedMedia = MediaItem(image: image)
            showEditor = true
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Flash
            Button(action: { camera.toggleFlash() }) {
                Image(systemName: flashIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Filter toggle
            Button(action: { withAnimation { showFilterStrip.toggle() } }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(showFilterStrip ? Color.camAccent : .white)
                    .frame(width: 44, height: 44)
            }

            // Switch camera
            Button(action: { camera.switchCamera() }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 40) {
            // Last captured / gallery
            Button(action: {}) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                    }
            }

            // Shutter
            shutterButton

            // Mode toggle
            VStack(spacing: 4) {
                Button(action: {
                    if camera.captureMode == .video && !subscriptionManager.isPro {
                        showPaywall = true
                        return
                    }
                    withAnimation {
                        camera.captureMode = camera.captureMode == .photo ? .video : .photo
                    }
                }) {
                    Image(systemName: camera.captureMode == .photo ? "video" : "camera")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .overlay(alignment: .topTrailing) {
                            if !subscriptionManager.isPro && camera.captureMode == .photo {
                                ProBadge()
                            }
                        }
                }
                Text(camera.captureMode == .photo ? "Video" : "Photo")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var shutterButton: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 74, height: 74)

            if camera.captureMode == .photo {
                Circle()
                    .fill(Color.white)
                    .frame(width: camera.isRecording ? 28 : 62)
                    .animation(.spring(response: 0.2), value: camera.isRecording)
            } else {
                RoundedRectangle(cornerRadius: camera.isRecording ? 6 : 31)
                    .fill(camera.isRecording ? Color.red : Color.red)
                    .frame(width: camera.isRecording ? 28 : 62, height: camera.isRecording ? 28 : 62)
                    .animation(.spring(response: 0.3), value: camera.isRecording)
            }
        }
        .onTapGesture {
            if camera.captureMode == .photo {
                camera.capturePhoto()
            } else {
                if camera.isRecording {
                    camera.stopVideoRecording()
                } else {
                    camera.startVideoRecording()
                }
            }
        }
    }

    // MARK: - Permission View

    private var cameraPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.camAccent)
            Text("Camera Access Needed")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("cam needs camera access to capture your content.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.camAccent)
        }
    }

    private var flashIcon: String {
        switch camera.flashMode {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        default: return "bolt.slash.fill"
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = camera.previewLayer {
            layer.frame = uiView.bounds
            if layer.superlayer == nil {
                uiView.layer.insertSublayer(layer, at: 0)
            }
        }
    }
}
