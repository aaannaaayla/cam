import SwiftUI
import UIKit

// Sticker catalog backed by Noto Emoji PNGs (Apache 2.0, from scripts/setup-assets.sh).
// Falls back to SF Symbol names when PNGs aren't bundled yet.

struct StickerPack: Identifiable {
    let id: String
    let name: String
    let emoji: String       // display icon for the pack tab
    let stickers: [Sticker]
}

struct Sticker: Identifiable {
    let id: String
    let displayName: String
    // PNG from Noto Emoji bundle — nil if setup script hasn't run
    var image: UIImage? {
        UIImage(named: id) ?? UIImage(named: "emoji_u\(id.lowercased())")
    }
    // SF Symbol fallback
    let sfSymbol: String
}

extension StickerPack {
    static let all: [StickerPack] = [
        StickerPack(id: "hearts", name: "Hearts", emoji: "❤️", stickers: [
            Sticker(id: "2764", displayName: "Heart", sfSymbol: "heart.fill"),
            Sticker(id: "1F495", displayName: "Two Hearts", sfSymbol: "suit.heart.fill"),
            Sticker(id: "1F496", displayName: "Sparkle Heart", sfSymbol: "heart.circle.fill"),
            Sticker(id: "1F497", displayName: "Growing Heart", sfSymbol: "heart.square.fill"),
            Sticker(id: "1F499", displayName: "Blue Heart", sfSymbol: "heart.fill"),
            Sticker(id: "1F49A", displayName: "Green Heart", sfSymbol: "heart.fill"),
            Sticker(id: "1F49B", displayName: "Yellow Heart", sfSymbol: "heart.fill"),
            Sticker(id: "1F49C", displayName: "Purple Heart", sfSymbol: "heart.fill"),
            Sticker(id: "1F9E1", displayName: "Orange Heart", sfSymbol: "heart.fill"),
        ]),
        StickerPack(id: "stars", name: "Stars", emoji: "⭐️", stickers: [
            Sticker(id: "2B50", displayName: "Star", sfSymbol: "star.fill"),
            Sticker(id: "1F31F", displayName: "Glowing Star", sfSymbol: "star.circle.fill"),
            Sticker(id: "1F4AB", displayName: "Dizzy", sfSymbol: "sparkles"),
            Sticker(id: "2728", displayName: "Sparkles", sfSymbol: "sparkle"),
            Sticker(id: "1F320", displayName: "Shooting Star", sfSymbol: "star.leadinghalf.filled"),
            Sticker(id: "1F308", displayName: "Rainbow", sfSymbol: "rainbow"),
        ]),
        StickerPack(id: "nature", name: "Nature", emoji: "🌸", stickers: [
            Sticker(id: "1F33A", displayName: "Hibiscus", sfSymbol: "leaf.fill"),
            Sticker(id: "1F33B", displayName: "Sunflower", sfSymbol: "sun.max.fill"),
            Sticker(id: "1F337", displayName: "Tulip", sfSymbol: "leaf"),
            Sticker(id: "1F338", displayName: "Cherry Blossom", sfSymbol: "leaf.circle"),
            Sticker(id: "1F339", displayName: "Rose", sfSymbol: "leaf.arrow.circlepath"),
            Sticker(id: "1F340", displayName: "Four Leaf Clover", sfSymbol: "leaf.circle.fill"),
            Sticker(id: "1F341", displayName: "Maple Leaf", sfSymbol: "leaf"),
            Sticker(id: "1F344", displayName: "Mushroom", sfSymbol: "chart.pie.fill"),
            Sticker(id: "1F332", displayName: "Evergreen", sfSymbol: "tree.fill"),
        ]),
        StickerPack(id: "expressions", name: "Expressions", emoji: "😊", stickers: [
            Sticker(id: "1F600", displayName: "Grin", sfSymbol: "face.smiling"),
            Sticker(id: "1F601", displayName: "Beam", sfSymbol: "face.smiling.inverse"),
            Sticker(id: "1F602", displayName: "Joy", sfSymbol: "face.smiling"),
            Sticker(id: "1F604", displayName: "Smile", sfSymbol: "smiley"),
            Sticker(id: "1F60D", displayName: "Heart Eyes", sfSymbol: "heart.eyes"),
            Sticker(id: "1F618", displayName: "Kiss", sfSymbol: "face.smiling"),
            Sticker(id: "1F970", displayName: "Smiling with Hearts", sfSymbol: "face.smiling"),
            Sticker(id: "1F929", displayName: "Star Struck", sfSymbol: "star"),
        ]),
        StickerPack(id: "celebration", name: "Celebration", emoji: "🎉", stickers: [
            Sticker(id: "1F389", displayName: "Party Popper", sfSymbol: "party.popper"),
            Sticker(id: "1F38A", displayName: "Confetti", sfSymbol: "sparkles"),
            Sticker(id: "1F381", displayName: "Gift", sfSymbol: "gift.fill"),
            Sticker(id: "1F382", displayName: "Birthday Cake", sfSymbol: "birthday.cake"),
            Sticker(id: "1F383", displayName: "Jack-o-Lantern", sfSymbol: "moon.stars.fill"),
            Sticker(id: "1F388", displayName: "Balloon", sfSymbol: "balloon.fill"),
        ]),
        StickerPack(id: "baby", name: "Baby & Family", emoji: "👶", stickers: [
            Sticker(id: "1F476", displayName: "Baby", sfSymbol: "person.fill"),
            Sticker(id: "1F37C", displayName: "Baby Bottle", sfSymbol: "drop.fill"),
            Sticker(id: "1F9F8", displayName: "Teddy Bear", sfSymbol: "teddybear.fill"),
            Sticker(id: "1F6BC", displayName: "Baby Stroller", sfSymbol: "figure.and.child.holdinghands"),
            Sticker(id: "1F45F", displayName: "Sneaker", sfSymbol: "figure.walk"),
            Sticker(id: "1FAB6", displayName: "Feather", sfSymbol: "wind"),
        ]),
        StickerPack(id: "food", name: "Food", emoji: "🍓", stickers: [
            Sticker(id: "1F352", displayName: "Cherries", sfSymbol: "circle.fill"),
            Sticker(id: "1F353", displayName: "Strawberry", sfSymbol: "heart.fill"),
            Sticker(id: "1F36A", displayName: "Cookie", sfSymbol: "circle.fill"),
            Sticker(id: "1F36B", displayName: "Chocolate", sfSymbol: "square.fill"),
            Sticker(id: "1F370", displayName: "Cake Slice", sfSymbol: "birthday.cake"),
            Sticker(id: "1F382", displayName: "Cake", sfSymbol: "birthday.cake.fill"),
        ]),
    ]
}

// MARK: - Custom Fonts

struct ScrapbookFont: Identifiable {
    let id: String
    let displayName: String
    let fontName: String    // Registered PostScript name after loading
    let style: String       // "handwritten" | "serif" | "sans" | "bold"
}

extension ScrapbookFont {
    // These map to .ttf files in cam/Resources/Fonts/ (downloaded by setup-assets.sh)
    static let bundled: [ScrapbookFont] = [
        ScrapbookFont(id: "system",   displayName: "System",   fontName: "System",              style: "sans"),
        ScrapbookFont(id: "caveat",   displayName: "Caveat",   fontName: "Caveat-Regular",       style: "handwritten"),
        ScrapbookFont(id: "playfair", displayName: "Playfair", fontName: "PlayfairDisplay-Regular", style: "serif"),
        ScrapbookFont(id: "dm_sans",  displayName: "DM Sans",  fontName: "DMSans-Regular",       style: "sans"),
    ]

    func font(size: CGFloat, bold: Bool = false) -> UIFont {
        let postScriptName = bold ? fontName.replacingOccurrences(of: "-Regular", with: "-Bold") : fontName
        return UIFont(name: postScriptName, size: size) ?? .systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    func swiftUIFont(size: CGFloat, bold: Bool = false) -> Font {
        let name = bold ? fontName.replacingOccurrences(of: "-Regular", with: "-Bold") : fontName
        if fontName == "System" { return bold ? .system(size: size, weight: .bold) : .system(size: size) }
        return .custom(name, size: size)
    }
}

// MARK: - Font Loader

final class FontLoader {
    static let shared = FontLoader()
    private var loaded: Set<String> = []

    func loadBundledFonts() {
        for font in ScrapbookFont.bundled where font.fontName != "System" {
            loadIfNeeded(named: font.fontName)
            let boldName = font.fontName.replacingOccurrences(of: "-Regular", with: "-Bold")
            loadIfNeeded(named: boldName)
        }
    }

    private func loadIfNeeded(named name: String) {
        guard !loaded.contains(name) else { return }
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
              let data = try? Data(contentsOf: url) as CFData,
              let provider = CGDataProvider(data: data),
              let cgFont = CGFont(provider)
        else { return }
        CTFontManagerRegisterGraphicsFont(cgFont, nil)
        loaded.insert(name)
    }
}
