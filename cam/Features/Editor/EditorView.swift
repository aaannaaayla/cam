import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct EditorView: View {
    let mediaItem: MediaItem
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var vm: EditorViewModel

    @State private var activeTab: EditorTab = .filters
    @State private var showSaveSuccess = false
    @State private var showPaywall = false
    @State private var isSaving = false

    enum EditorTab: String, CaseIterable {
        case filters = "Filters"
        case adjust = "Adjust"
    }

    init(mediaItem: MediaItem, initialFilter: FilterPreset = .original) {
        self.mediaItem = mediaItem
        _vm = StateObject(wrappedValue: EditorViewModel(mediaItem: mediaItem, initialFilter: initialFilter))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Preview
                    imagePreview
                        .padding(.vertical, 16)

                    // Tab selector
                    tabSelector

                    // Controls
                    Group {
                        if activeTab == .filters {
                            FilterStripView(
                                selected: $vm.selectedFilter,
                                isPro: subscriptionManager.isPro,
                                onProTap: { showPaywall = true }
                            )
                        } else {
                            AdjustmentsView(adjustments: $vm.adjustments, isPro: subscriptionManager.isPro)
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await save() } }) {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.camAccent)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .overlay(alignment: .top) {
            if showSaveSuccess {
                saveToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height * 1.2)
            Group {
                if let processed = vm.processedImage {
                    Image(uiImage: processed)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: size)
                } else if let original = mediaItem.image {
                    Image(uiImage: original)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: size)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 320)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation { activeTab = tab } }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundColor(activeTab == tab ? .white : .white.opacity(0.5))
                        Rectangle()
                            .fill(activeTab == tab ? Color.camAccent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color.camSurface)
    }

    // MARK: - Save Toast

    private var saveToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Saved to Photos")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.camSurface.cornerRadius(20))
        .padding(.top, 16)
    }

    private func save() async {
        isSaving = true
        guard let image = vm.processedImage else { isSaving = false; return }
        let quality: CGFloat = subscriptionManager.isPro ? 1.0 : 0.85
        guard let data = image.jpegData(compressionQuality: quality) else { isSaving = false; return }
        guard let final = UIImage(data: data) else { isSaving = false; return }
        try? await PhotoLibraryService.shared.saveImage(final)
        isSaving = false
        withAnimation { showSaveSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveSuccess = false }
            dismiss()
        }
    }
}
