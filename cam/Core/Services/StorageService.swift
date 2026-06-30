import Foundation
import UIKit

class StorageService {
    static let shared = StorageService()
    private let fileManager = FileManager.default

    private var projectsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Projects", isDirectory: true)
    }

    private var gridsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Grids", isDirectory: true)
    }

    private init() {
        try? fileManager.createDirectory(at: projectsURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: gridsURL, withIntermediateDirectories: true)
    }

    // MARK: - Projects

    func saveProject(_ project: Project) throws {
        let data = try JSONEncoder().encode(project)
        let url = projectsURL.appendingPathComponent("\(project.id.uuidString).json")
        try data.write(to: url)
    }

    func loadProjects() throws -> [Project] {
        let urls = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: nil)
        return try urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? JSONDecoder().decode(Project.self, from: Data(contentsOf: $0)) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func deleteProject(_ project: Project) throws {
        let url = projectsURL.appendingPathComponent("\(project.id.uuidString).json")
        try fileManager.removeItem(at: url)
    }

    // MARK: - Grid Plans

    func saveGridPlan(_ plan: GridPlan) throws {
        let data = try JSONEncoder().encode(plan)
        let url = gridsURL.appendingPathComponent("\(plan.id.uuidString).json")
        try data.write(to: url)
    }

    func loadGridPlans() throws -> [GridPlan] {
        let urls = try fileManager.contentsOfDirectory(at: gridsURL, includingPropertiesForKeys: nil)
        return try urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? JSONDecoder().decode(GridPlan.self, from: Data(contentsOf: $0)) }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func deleteGridPlan(_ plan: GridPlan) throws {
        let url = gridsURL.appendingPathComponent("\(plan.id.uuidString).json")
        try fileManager.removeItem(at: url)
    }

    // MARK: - Exports

    var exportsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Exports", isDirectory: true)
    }

    func exportURL(for name: String, extension ext: String) -> URL {
        let ts = Int(Date().timeIntervalSince1970)
        return exportsURL.appendingPathComponent("\(name)_\(ts).\(ext)")
    }
}
