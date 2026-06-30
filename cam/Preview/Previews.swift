#if DEBUG
import SwiftUI

// Centralized SwiftUI previews + sample data so every screen renders in
// Xcode's canvas without a simulator, device, or camera.
//
// To use: open this file (or any view file) in Xcode and show the canvas with
// Editor ▸ Canvas (⌥⌘↩). Pick a preview from the dropdown at the top of the canvas.
// This whole file is compiled only in DEBUG and never ships in a release build.

enum PreviewData {

    /// A colorful sample "photo" so the editor, collage, and grid previews have
    /// real content to work with — rendered procedurally, no asset needed.
    static var sampleImage: UIImage {
        let size = CGSize(width: 900, height: 1100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let c = ctx.cgContext

            // Sky gradient — warm sunset
            let colors = [
                UIColor(red: 0.99, green: 0.85, blue: 0.62, alpha: 1).cgColor,
                UIColor(red: 0.97, green: 0.62, blue: 0.52, alpha: 1).cgColor,
                UIColor(red: 0.52, green: 0.42, blue: 0.64, alpha: 1).cgColor
            ]
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray, locations: [0, 0.55, 1])!
            c.drawLinearGradient(grad, start: .zero,
                                 end: CGPoint(x: 0, y: size.height), options: [])

            // Sun
            UIColor(white: 1, alpha: 0.92).setFill()
            c.fillEllipse(in: CGRect(x: size.width * 0.58, y: size.height * 0.14,
                                     width: 150, height: 150))

            // Rolling hills
            UIColor(red: 0.27, green: 0.33, blue: 0.30, alpha: 1).setFill()
            let hills = UIBezierPath()
            hills.move(to: CGPoint(x: 0, y: size.height))
            hills.addLine(to: CGPoint(x: 0, y: size.height * 0.72))
            hills.addQuadCurve(to: CGPoint(x: size.width * 0.5, y: size.height * 0.76),
                               controlPoint: CGPoint(x: size.width * 0.25, y: size.height * 0.62))
            hills.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.73),
                               controlPoint: CGPoint(x: size.width * 0.78, y: size.height * 0.86))
            hills.addLine(to: CGPoint(x: size.width, y: size.height))
            hills.close()
            hills.fill()
        }
    }

    static var sampleMediaItem: MediaItem { MediaItem(image: sampleImage) }

    /// Returns the shared subscription manager forced into a known tier.
    @MainActor static func manager(pro: Bool) -> SubscriptionManager {
        let m = SubscriptionManager.shared
        m.isPro = pro
        return m
    }
}

// MARK: - Binding wrappers (views that need @State for the canvas)

private struct FilterStripPreview: View {
    @State private var filter: FilterPreset = .original
    var body: some View {
        FilterStripView(selected: $filter, isPro: true, onProTap: {})
            .frame(height: 210)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.camBackground)
    }
}

private struct AdjustmentsPreview: View {
    @State private var adj = UserAdjustments()
    var body: some View {
        AdjustmentsView(adjustments: $adj, isPro: true)
            .frame(height: 210)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.camBackground)
    }
}

// MARK: - Full-screen previews

#Preview("App — Tab Bar") {
    ContentView()
        .environmentObject(PreviewData.manager(pro: true))
        .environmentObject(PhotoLibraryService.shared)
}

#Preview("Create") {
    CreateView()
        .environmentObject(PreviewData.manager(pro: false))
}

#Preview("Editor") {
    EditorView(mediaItem: PreviewData.sampleMediaItem, initialFilter: .original)
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Collage Builder") {
    CollageBuilderView(layout: CollageLayout.allLayouts[3])
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Scrapbook") {
    ScrapbookView()
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Planner — empty") {
    PlannerView()
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Grid Planner — Instagram") {
    GridEditorView(plan: GridPlan(platform: .instagram)) { _ in }
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Grid Planner — TikTok") {
    GridEditorView(plan: GridPlan(platform: .tiktok)) { _ in }
        .environmentObject(PreviewData.manager(pro: true))
}

#Preview("Paywall") {
    PaywallView()
        .environmentObject(PreviewData.manager(pro: false))
}

#Preview("Sticker Picker") {
    StickerPickerView { _ in }
}

// MARK: - Component previews

#Preview("Filter Strip") { FilterStripPreview() }

#Preview("Adjustments") { AdjustmentsPreview() }

#endif
