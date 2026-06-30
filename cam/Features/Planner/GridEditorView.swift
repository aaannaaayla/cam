import SwiftUI
import PhotosUI

// The main full-screen grid planner for one plan

struct GridEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var plan: GridPlan
    private let onSave: (GridPlan) -> Void

    @State private var selectedSlotIndex: Int? = nil
    @State private var photosItem: [PhotosPickerItem] = []
    @State private var showImagePicker = false
    @State private var draggedSlot: GridSlot? = nil
    @State private var showPaywall = false

    private var platform: GridPlatform {
        GridPlatform.allCases.first { $0.rawValue == plan.platform } ?? .instagram
    }

    init(plan: GridPlan, onSave: @escaping (GridPlan) -> Void) {
        _plan = State(initialValue: plan)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Profile header mockup
                    profileHeader
                        .padding(.bottom, 8)

                    // Grid
                    gridView

                    Spacer()

                    // Instructions
                    Text("Tap a slot to add a photo · Drag to rearrange")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = plan
                        updated.modifiedAt = Date()
                        onSave(updated)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.camAccent)
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $photosItem, maxSelectionCount: 1, matching: .images)
        .onChange(of: photosItem) { _, items in
            Task {
                guard let item = items.first,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let idx = selectedSlotIndex
                else { return }
                plan.slots[idx].imageData = data
                plan.slots[idx].isPlanned = true
                photosItem = []
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Profile Header Mockup

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.camSurface)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.3))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("your_handle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    statView("\(plan.slots.filter(\.hasContent).count)", "Posts")
                    statView("—", "Followers")
                    statView("—", "Following")
                }
            }

            Spacer()

            if platform == .instagram {
                Image(systemName: "camera.filters")
                    .foregroundColor(.white.opacity(0.3))
            } else {
                Image(systemName: "music.note.tv.fill")
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func statView(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        GeometryReader { geo in
            let cols = platform.columns
            let spacing: CGFloat = 2
            let cellW = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            let cellH = cellW / platform.cellAspectRatio

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellW), spacing: spacing), count: cols),
                spacing: spacing
            ) {
                ForEach(Array(plan.slots.enumerated()), id: \.element.id) { (index, slot) in
                    GridCellView(
                        slot: slot,
                        index: index,
                        cellSize: CGSize(width: cellW, height: cellH),
                        isSelected: selectedSlotIndex == index
                    )
                    .frame(width: cellW, height: cellH)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSlotIndex = index
                        showImagePicker = true
                    }
                    .contextMenu {
                        if slot.hasContent {
                            Button(role: .destructive) {
                                plan.slots[index].imageData = nil
                                plan.slots[index].isPlanned = false
                            } label: {
                                Label("Remove Photo", systemImage: "trash")
                            }
                        }
                    }
                    .draggable(slot.id.uuidString) {
                        GridCellDragPreview(slot: slot, size: CGSize(width: cellW, height: cellH))
                    }
                    .dropDestination(for: String.self) { ids, _ in
                        guard let draggedIDStr = ids.first,
                              let draggedID = UUID(uuidString: draggedIDStr),
                              let fromIndex = plan.slots.firstIndex(where: { $0.id == draggedID })
                        else { return false }
                        plan.slots.swapAt(fromIndex, index)
                        return true
                    }
                }

                // Add more slots button (Pro only for extra rows)
                if subscriptionManager.isPro && plan.slots.count < 30 {
                    Button(action: {
                        let newSlot = GridSlot(position: plan.slots.count)
                        plan.slots.append(newSlot)
                    }) {
                        ZStack {
                            Color.camSurface
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .frame(width: cellW, height: cellH)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: calculateGridHeight(geo: UIScreen.main.bounds))
    }

    private func calculateGridHeight(geo: CGRect) -> CGFloat {
        let cols = platform.columns
        let spacing: CGFloat = 2
        let cellW = (geo.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
        let cellH = cellW / platform.cellAspectRatio
        let rows = ceil(Double(plan.slots.count) / Double(cols))
        return cellH * CGFloat(rows) + spacing * CGFloat(rows - 1) + 20
    }
}

// MARK: - Grid Cell View

private struct GridCellView: View {
    let slot: GridSlot
    let index: Int
    let cellSize: CGSize
    let isSelected: Bool

    var body: some View {
        ZStack {
            if let data = slot.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color(white: 0.15)
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.25))
                    Text("\(index + 1)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .overlay {
            if isSelected {
                Color.camAccent.opacity(0.2)
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.camAccent, lineWidth: 2)
            }
        }
    }
}

private struct GridCellDragPreview: View {
    let slot: GridSlot
    let size: CGSize

    var body: some View {
        Group {
            if let data = slot.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .opacity(0.85)
            } else {
                Color.camSurface
                    .frame(width: size.width, height: size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
