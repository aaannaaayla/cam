import SwiftUI
import Photos
import PhotosUI

struct LibraryView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var recentPhotos: [UIImage] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showEditor = false
    @State private var authStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()

                Group {
                    switch authStatus {
                    case .authorized, .limited:
                        photoGrid
                    case .denied, .restricted:
                        permissionDenied
                    default:
                        requestPermissionView
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await checkAuthorization() }
        .sheet(isPresented: $showEditor) {
            if let img = selectedImage {
                EditorView(mediaItem: MediaItem(image: img))
            }
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                spacing: 2
            ) {
                ForEach(recentPhotos, id: \.self) { photo in
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .onTapGesture {
                            selectedImage = photo
                            showEditor = true
                        }
                }
            }
        }
    }

    private var permissionDenied: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(Color.camAccent.opacity(0.5))
            Text("Photos Access Denied")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Enable photo library access in Settings to browse your photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered).tint(Color.camAccent)
            Spacer()
        }
    }

    private var requestPermissionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(Color.camAccent.opacity(0.5))
            Text("Your Photos")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Allow cam to access your photos to edit them with filters and layouts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 40)
            Button("Allow Access") {
                Task { await requestAndLoad() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color.camBackground)
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(Color.camAccent)
            .clipShape(Capsule())
            Spacer()
        }
    }

    private func checkAuthorization() async {
        authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authStatus == .authorized || authStatus == .limited {
            await loadPhotos()
        }
    }

    private func requestAndLoad() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authStatus = status
        if status == .authorized || status == .limited {
            await loadPhotos()
        }
    }

    private func loadPhotos() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 120
        let result = PHAsset.fetchAssets(with: .image, options: options)

        var images: [UIImage] = []
        let manager = PHImageManager.default()
        let reqOptions = PHImageRequestOptions()
        reqOptions.isSynchronous = true
        reqOptions.deliveryMode = .fastFormat
        reqOptions.resizeMode = .fast

        result.enumerateObjects { asset, _, _ in
            manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300),
                                 contentMode: .aspectFill, options: reqOptions) { img, _ in
                if let img { images.append(img) }
            }
        }
        recentPhotos = images
    }
}
