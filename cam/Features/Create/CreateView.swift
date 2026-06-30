import SwiftUI

struct CreateView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showCollageBuilder = false
    @State private var showScrapbook = false
    @State private var selectedLayout: CollageLayout?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Collage section
                    sectionHeader("Collage", subtitle: "Combine multiple photos")
                    layoutGrid

                    // Scrapbook section
                    sectionHeader("Scrapbook", subtitle: "Add stickers, text & frames")
                    scrapbookTemplates
                }
                .padding(.vertical, 16)
            }
            .background(Color.camBackground)
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showCollageBuilder) {
            if let layout = selectedLayout {
                CollageBuilderView(layout: layout)
            }
        }
        .sheet(isPresented: $showScrapbook) {
            ScrapbookView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Layout Grid

    private var layoutGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CollageLayout.allLayouts) { layout in
                    LayoutCard(layout: layout, isPro: subscriptionManager.isPro) {
                        if layout.isPro && !subscriptionManager.isPro {
                            showPaywall = true
                        } else {
                            selectedLayout = layout
                            showCollageBuilder = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Scrapbook Templates

    private var scrapbookTemplates: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 12) {
            ForEach(ScrapbookTemplate.all) { template in
                ScrapbookTemplateCard(template: template, isPro: subscriptionManager.isPro) {
                    if template.isPro && !subscriptionManager.isPro {
                        showPaywall = true
                    } else {
                        showScrapbook = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Layout Card

private struct LayoutCard: View {
    let layout: CollageLayout
    let isPro: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    LayoutPreviewShape(layout: layout)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if layout.isPro && !isPro {
                        ProBadge()
                            .padding(6)
                    }
                }
                Text(layout.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout Preview Shape

struct LayoutPreviewShape: View {
    let layout: CollageLayout

    var body: some View {
        GeometryReader { geo in
            ForEach(layout.slots) { slot in
                let frame = CGRect(
                    x: slot.frame.minX * geo.size.width + (slot.frame.minX > 0 ? 1.5 : 0),
                    y: slot.frame.minY * geo.size.height + (slot.frame.minY > 0 ? 1.5 : 0),
                    width: slot.frame.width * geo.size.width - (slot.frame.minX > 0 ? 1.5 : 0),
                    height: slot.frame.height * geo.size.height - (slot.frame.minY > 0 ? 1.5 : 0)
                )
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.camSurface)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
        .background(Color.camBackground)
    }
}

// MARK: - Scrapbook Template

struct ScrapbookTemplate: Identifiable {
    let id: String
    let name: String
    let isPro: Bool
    let backgroundColor: Color
    let icon: String

    static let all: [ScrapbookTemplate] = [
        ScrapbookTemplate(id: "blank", name: "Blank", isPro: false, backgroundColor: Color(white: 0.15), icon: "plus"),
        ScrapbookTemplate(id: "memory", name: "Memory", isPro: false, backgroundColor: Color(red: 0.95, green: 0.9, blue: 0.82), icon: "heart"),
        ScrapbookTemplate(id: "travel", name: "Travel", isPro: false, backgroundColor: Color(red: 0.82, green: 0.9, blue: 0.95), icon: "airplane"),
        ScrapbookTemplate(id: "baby", name: "Baby", isPro: true, backgroundColor: Color(red: 0.98, green: 0.88, blue: 0.92), icon: "star"),
        ScrapbookTemplate(id: "birthday", name: "Birthday", isPro: true, backgroundColor: Color(red: 0.95, green: 0.92, blue: 0.7), icon: "gift"),
        ScrapbookTemplate(id: "mood", name: "Mood Board", isPro: true, backgroundColor: Color(red: 0.88, green: 0.85, blue: 0.92), icon: "paintbrush"),
        ScrapbookTemplate(id: "recipe", name: "Recipe", isPro: true, backgroundColor: Color(red: 0.92, green: 0.88, blue: 0.82), icon: "fork.knife"),
        ScrapbookTemplate(id: "adventure", name: "Adventure", isPro: true, backgroundColor: Color(red: 0.85, green: 0.92, blue: 0.85), icon: "mountain.2"),
        ScrapbookTemplate(id: "gratitude", name: "Gratitude", isPro: true, backgroundColor: Color(red: 0.95, green: 0.85, blue: 0.85), icon: "hands.sparkles"),
    ]
}

private struct ScrapbookTemplateCard: View {
    let template: ScrapbookTemplate
    let isPro: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(template.backgroundColor)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: template.icon)
                                .font(.system(size: 22))
                                .foregroundColor(.black.opacity(0.4))
                            Text(template.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }

                if template.isPro && !isPro {
                    ProBadge()
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
