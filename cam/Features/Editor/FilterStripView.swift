import SwiftUI

struct FilterStripView: View {
    @Binding var selected: FilterPreset
    let isPro: Bool
    let onProTap: () -> Void

    @State private var categoryFilter: FilterPreset.Category? = nil

    private var visibleFilters: [FilterPreset] {
        let all = FilterPreset.all
        guard let cat = categoryFilter else { return all }
        return all.filter { $0.category == cat }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(title: "All", isSelected: categoryFilter == nil) {
                        categoryFilter = nil
                    }
                    ForEach(FilterPreset.Category.allCases, id: \.self) { cat in
                        CategoryChip(title: cat.rawValue, isSelected: categoryFilter == cat) {
                            categoryFilter = cat == categoryFilter ? nil : cat
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Filter thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(visibleFilters) { preset in
                        FilterCell(
                            preset: preset,
                            isSelected: selected.id == preset.id,
                            isPro: isPro,
                            onTap: {
                                if preset.isPro && !isPro {
                                    onProTap()
                                } else {
                                    withAnimation(.spring(response: 0.2)) {
                                        selected = preset
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? Color.camBackground : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? Color.camAccent : Color.camSurface)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Filter Cell

private struct FilterCell: View {
    let preset: FilterPreset
    let isSelected: Bool
    let isPro: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.camSurface)
                        .frame(width: 70, height: 70)
                        .overlay {
                            FilterThumbnailView(preset: preset)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.camAccent : Color.clear, lineWidth: 2)
                        }

                    if preset.isPro && !isPro {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.camPro)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }

                Text(preset.name)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.camAccent : .white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
