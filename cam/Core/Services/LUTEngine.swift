import CoreImage
import UIKit

// Parses standard .cube LUT files and converts them to CIColorCube filters.
// Supports 1D and 3D LUT files; 3D is the standard for film emulation.
// No external dependencies — just Core Image's CIColorCube filter.

enum LUTEngineError: Error {
    case fileNotFound(String)
    case parseError(String)
    case unsupportedSize
}

final class LUTEngine {
    static let shared = LUTEngine()

    private var cache: [String: CIFilter] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - Public API

    /// Load a .cube file from the app bundle and return a configured CIColorCube filter.
    /// Results are cached — the file is only parsed once per session.
    func filter(named name: String) -> CIFilter? {
        let key = name

        lock.lock()
        if let cached = cache[key] { lock.unlock(); return cached }
        lock.unlock()

        guard let url = bundleURL(for: name) else {
            // Silently fall back — the setup script may not have been run yet.
            return nil
        }

        do {
            let filter = try parseCube(at: url)
            lock.lock()
            cache[key] = filter
            lock.unlock()
            return filter
        } catch {
            print("[LUTEngine] Failed to parse '\(name)': \(error)")
            return nil
        }
    }

    /// Apply a named LUT to a CIImage. Falls back to the original image if the LUT isn't found.
    func apply(lut name: String, to image: CIImage) -> CIImage {
        guard let f = filter(named: name) else { return image }
        f.setValue(image, forKey: kCIInputImageKey)
        return f.outputImage ?? image
    }

    // MARK: - Parser

    private func parseCube(at url: URL) throws -> CIFilter {
        let content = try String(contentsOf: url, encoding: .utf8)
        var size = 0
        var data: [Float] = []
        var is3D = false

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // Parse size declarations
            if trimmed.uppercased().hasPrefix("LUT_3D_SIZE") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                size = Int(parts.last ?? "") ?? 0
                is3D = true
                continue
            }
            if trimmed.uppercased().hasPrefix("LUT_1D_SIZE") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                size = Int(parts.last ?? "") ?? 0
                is3D = false
                continue
            }

            // Skip metadata lines we don't need
            let upper = trimmed.uppercased()
            if upper.hasPrefix("TITLE") || upper.hasPrefix("DOMAIN_MIN") ||
               upper.hasPrefix("DOMAIN_MAX") || upper.hasPrefix("LUT_IN") ||
               upper.hasPrefix("LUT_OUT") { continue }

            // Parse a data row: three space-separated floats
            let components = trimmed
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .compactMap { Float($0) }

            if components.count == 3 {
                data.append(components[0])  // R
                data.append(components[1])  // G
                data.append(components[2])  // B
                data.append(1.0)            // A (CIColorCube requires RGBA)
            }
        }

        guard size > 0 else { throw LUTEngineError.parseError("No LUT size declaration found") }
        guard !data.isEmpty else { throw LUTEngineError.parseError("No data rows found") }

        // CIColorCube only supports 3D LUTs; CIColorCubeWithColorSpace for HDR.
        // Max dimension supported is 64 (64³ = 262,144 entries).
        guard size <= 64 else { throw LUTEngineError.unsupportedSize }

        let filterName = is3D ? "CIColorCube" : "CIColorCube"
        guard let ciFilter = CIFilter(name: filterName) else {
            throw LUTEngineError.parseError("CIColorCube unavailable")
        }

        let byteCount = data.count * MemoryLayout<Float>.size
        let cubeData = Data(bytes: data, count: byteCount)

        ciFilter.setValue(size, forKey: "inputCubeDimension")
        ciFilter.setValue(cubeData, forKey: "inputCubeData")

        return ciFilter
    }

    // MARK: - Bundle Resolution

    private func bundleURL(for name: String) -> URL? {
        // Try Resources/LUTs/ directory first, then bundle root
        let cleanName = name.hasSuffix(".cube") ? String(name.dropLast(5)) : name

        if let url = Bundle.main.url(forResource: cleanName, withExtension: "cube", subdirectory: "LUTs") {
            return url
        }
        if let url = Bundle.main.url(forResource: cleanName, withExtension: "cube") {
            return url
        }
        return nil
    }

    // MARK: - Available LUTs

    /// Returns the names of all .cube files currently bundled in the app.
    static var availableLUTNames: [String] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "cube", subdirectory: "LUTs") else {
            return []
        }
        return urls.map { $0.deletingPathExtension().lastPathComponent }.sorted()
    }
}

// MARK: - CIImage extension

extension CIImage {
    func applyingLUT(named name: String) -> CIImage {
        LUTEngine.shared.apply(lut: name, to: self)
    }
}
