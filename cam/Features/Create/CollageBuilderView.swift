import SwiftUI
import PhotosUI

struct CollageBuilderView: View {
    let layout: CollageLayout
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var slotImages: [String: UIImage] = [:]
    @State private var selectedSlotID: String? = nil
    @State private var showImagePicker = false
    @State private var photosItem: [PhotosPickerItem] = []
    @State private var backgroundColor: Color = .white
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Canvas
                    GeometryReader { geo in
                        let size = min(geo.size.width - 40, geo.size.height * 0.6)
                        CollageCanvas(
                            layout: layout,
                            slotImages: slotImages,
                            selectedSlotID: $selectedSlotID,
                            backgroundColor: backgroundColor,
                            size: size,
                            onSlotTap: { slotID in
                                selectedSlotID = slotID
                                showImagePicker = true
                            }
                        )
                        .frame(width: size, height: size)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                    .frame(height: 340)

                    // Background color picker
                    bgColorPicker

                    Spacer()
                }
            }
            .navigationTitle(layout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveCollage) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Export")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.camAccent)
                        }
                    }
                    .disabled(isSaving || slotImages.isEmpty)
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photosItem, maxSelectionCount: 1, matching: .images)
        .onChange(of: photosItem) { _, items in
            Task {
                guard let item = items.first,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let slotID = selectedSlotID
                else { return }
                slotImages[slotID] = image
                photosItem = []
            }
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

    private var bgColorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Background")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(bgColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if color == backgroundColor {
                                    Circle().stroke(Color.white, lineWidth: 2).padding(3)
                                }
                            }
                            .onTapGesture { withAnimation { backgroundColor = color } }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private let bgColors: [Color] = [
        .white, Color(white: 0.95), Color(white: 0.9),
        Color(red: 0.97, green: 0.95, blue: 0.9),
        Color(red: 0.95, green: 0.9, blue: 0.9),
        Color(red: 0.9, green: 0.92, blue: 0.95),
        Color(red: 0.9, green: 0.95, blue: 0.9),
        .black, Color(white: 0.1), Color(white: 0.2)
    ]

    private func saveCollage() {
        isSaving = true
        let size: CGFloat = subscriptionManager.isPro ? 3000 : 1800
        let renderer = ImageRenderer(content:
            CollageCanvas(
                layout: layout,
                slotImages: slotImages,
                selectedSlotID: .constant(nil),
                backgroundColor: backgroundColor,
                size: size,
                onSlotTap: { _ in }
            )
            .frame(width: size, height: size)
        )
        renderer.scale = 1.0
        guard let image = renderer.uiImage else { isSaving = false; return }
        Task {
            try? await PhotoLibraryService.shared.saveImage(image)
            isSaving = false
            withAnimation { showSaved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showSaved = false }
                dismiss()
            }
        }
    }
}

// MARK: - Collage Canvas

struct CollageCanvas: View {
    let layout: CollageLayout
    let slotImages: [String: UIImage]
    @Binding var selectedSlotID: String?
    let backgroundColor: Color
    let size: CGFloat
    let onSlotTap: (String) -> Void

    var body: some View {
        ZStack {
            backgroundColor

            ForEach(layout.slots) { slot in
                let frame = CGRect(
                    x: slot.frame.minX * size,
                    y: slot.frame.minY * size,
                    width: slot.frame.width * size - (slot.frame.maxX < 1 ? 2 : 0),
                    height: slot.frame.height * size - (slot.frame.maxY < 1 ? 2 : 0)
                )
                CollageSlotView(
                    slotID: slot.id,
                    image: slotImages[slot.id],
                    isSelected: selectedSlotID == slot.id,
                    frame: frame,
                    onTap: { onSlotTap(slot.id) }
                )
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

private struct CollageSlotView: View {
    let slotID: String
    let image: UIImage?
    let isSelected: Bool
    let frame: CGRect
    let onTap: () -> Void

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color(white: 0.18)
                VStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.camAccent, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
