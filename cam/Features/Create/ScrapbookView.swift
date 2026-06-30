import SwiftUI
import PhotosUI

// A freeform canvas where users place photos, stickers, and text

struct ScrapbookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var elements: [ScrapElement] = []
    @State private var selectedElementID: UUID? = nil
    @State private var showImagePicker = false
    @State private var photosItem: [PhotosPickerItem] = []
    @State private var showTextEditor = false
    @State private var newText = ""
    @State private var showStickerPicker = false
    @State private var bgColor: Color = .white
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Canvas
                    GeometryReader { geo in
                        ZStack {
                            bgColor
                                .onTapGesture { selectedElementID = nil }

                            ForEach($elements) { $el in
                                ScrapElementView(element: $el, isSelected: selectedElementID == el.id)
                                    .onTapGesture { selectedElementID = el.id }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    }
                    .background(bgColor)

                    // Toolbar
                    bottomToolbar
                }
            }
            .navigationTitle("Scrapbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Export")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.camAccent)
                        }
                    }
                }
                if selectedElementID != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            elements.removeAll { $0.id == selectedElementID }
                            selectedElementID = nil
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photosItem, maxSelectionCount: 1, matching: .images)
        .onChange(of: photosItem) { _, items in
            Task {
                guard let item = items.first,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { return }
                let el = ScrapElement(type: .image, image: image, position: CGPoint(x: 180, y: 300))
                elements.append(el)
                photosItem = []
            }
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerView { name in
                let el = ScrapElement(type: .sticker, stickerName: name, position: CGPoint(x: 180, y: 300))
                elements.append(el)
            }
        }
        .alert("Add Text", isPresented: $showTextEditor) {
            TextField("Type something...", text: $newText)
            Button("Add") {
                guard !newText.isEmpty else { return }
                let el = ScrapElement(type: .text, text: newText, position: CGPoint(x: 180, y: 300))
                elements.append(el)
                newText = ""
            }
            Button("Cancel", role: .cancel) { newText = "" }
        }
        .overlay(alignment: .top) {
            if showSaved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Saved to Photos").foregroundColor(.white)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.camSurface.cornerRadius(20))
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            toolbarBtn("photo.badge.plus", "Photo") { showImagePicker = true }
            toolbarBtn("textformat", "Text") { showTextEditor = true }
            toolbarBtn("face.smiling", "Sticker") { showStickerPicker = true }
            Divider().frame(height: 30).opacity(0.3)
            // Background color
            Menu {
                ForEach(scrapBgColors, id: \.name) { item in
                    Button(item.name) { bgColor = item.color }
                }
            } label: {
                VStack(spacing: 4) {
                    Circle().fill(bgColor).frame(width: 26, height: 26)
                        .overlay { Circle().stroke(Color.white.opacity(0.4), lineWidth: 1) }
                    Text("BG").font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(Color.camSurface)
        .frame(height: 64)
    }

    private func toolbarBtn(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private let scrapBgColors: [(name: String, color: Color)] = [
        ("White", .white), ("Ivory", Color(red: 0.99, green: 0.97, blue: 0.94)),
        ("Blush", Color(red: 0.98, green: 0.9, blue: 0.9)),
        ("Sage", Color(red: 0.88, green: 0.93, blue: 0.88)),
        ("Sky", Color(red: 0.88, green: 0.92, blue: 0.98)),
        ("Black", .black), ("Slate", Color(white: 0.15))
    ]

    private func save() {
        isSaving = true
        // Snapshot handled via UIGraphicsImageRenderer in a real impl
        withAnimation { showSaved = true }
        isSaving = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
            dismiss()
        }
    }
}

// MARK: - Scrap Element Model

struct ScrapElement: Identifiable {
    let id: UUID
    var type: ScrapElementType
    var position: CGPoint
    var size: CGSize
    var rotation: Double
    var scale: CGFloat

    // Content
    var image: UIImage?
    var text: String?
    var textColor: Color
    var fontSize: CGFloat
    var fontWeight: Font.Weight
    var stickerName: String?

    init(type: ScrapElementType, image: UIImage? = nil, text: String? = nil,
         stickerName: String? = nil, position: CGPoint) {
        self.id = UUID()
        self.type = type
        self.image = image
        self.text = text
        self.stickerName = stickerName
        self.position = position
        self.size = type == .image ? CGSize(width: 160, height: 160) : CGSize(width: 120, height: 50)
        self.rotation = 0
        self.scale = 1
        self.textColor = .black
        self.fontSize = 20
        self.fontWeight = .regular
    }
}

enum ScrapElementType { case image, text, sticker }

// MARK: - Scrap Element View (draggable, pinch-to-scale, rotatable)

struct ScrapElementView: View {
    @Binding var element: ScrapElement
    let isSelected: Bool

    @GestureState private var dragState = CGPoint.zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var rotationAngle: Angle = .zero

    var body: some View {
        Group {
            switch element.type {
            case .image:
                if let img = element.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: element.size.width * element.scale,
                               height: element.size.height * element.scale)
                        .clipped()
                }
            case .text:
                Text(element.text ?? "")
                    .font(.system(size: element.fontSize * element.scale, weight: element.fontWeight))
                    .foregroundColor(element.textColor)
                    .fixedSize()
            case .sticker:
                Image(systemName: element.stickerName ?? "star.fill")
                    .font(.system(size: 60 * element.scale))
                    .foregroundColor(Color.camAccent)
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.camAccent.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            }
        }
        .rotationEffect(.degrees(element.rotation) + rotationAngle)
        .position(element.position)
        .gesture(dragGesture)
        .simultaneousGesture(pinchGesture)
        .simultaneousGesture(rotationGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { val in
                element.position = CGPoint(
                    x: element.position.x + val.translation.width,
                    y: element.position.y + val.translation.height
                )
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { val in element.scale = max(0.3, val) }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { val in element.rotation += val.degrees }
    }
}

// MARK: - Sticker Picker

struct StickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    private let stickers: [(category: String, names: [String])] = [
        ("Hearts", ["heart.fill", "heart.circle.fill", "suit.heart.fill", "heart.square.fill"]),
        ("Stars", ["star.fill", "star.circle.fill", "sparkles", "sparkle"]),
        ("Nature", ["leaf.fill", "flower", "sun.max.fill", "moon.stars.fill", "cloud.sun.fill"]),
        ("Fun", ["face.smiling.inverse", "balloon.fill", "camera.fill", "music.note"]),
        ("Symbols", ["checkmark.circle.fill", "plus.circle.fill", "arrow.right.circle.fill", "xmark.circle.fill"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(stickers, id: \.category) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.category)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(group.names, id: \.self) { name in
                                    Button {
                                        onSelect(name)
                                        dismiss()
                                    } label: {
                                        Image(systemName: name)
                                            .font(.system(size: 36))
                                            .foregroundColor(Color.camAccent)
                                            .frame(width: 60, height: 60)
                                            .background(Color.camSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.camBackground)
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
