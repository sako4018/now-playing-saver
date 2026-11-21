import Foundation

/// Writes state.json and the cover image into the shared folders.
struct StateWriter {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private var folders: [URL] {
        SharedLocation.candidateFolders().map { $0.url }
    }

    func write(_ state: NowPlayingState?) {
        let data: Data
        if let state, let encoded = try? encoder.encode(state) {
            data = encoded
        } else {
            data = Data("{}".utf8)   // nothing is playing
        }
        for folder in folders {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? data.write(to: folder.appendingPathComponent(SharedLocation.stateFileName), options: .atomic)
        }
    }

    func coverName(for trackID: String) -> String? {
        let safe = trackID.map { $0.isLetter || $0.isNumber ? $0 : "_" }
        return safe.isEmpty ? nil : "cover-\(String(safe)).jpg"
    }

    func coverExists(_ name: String) -> Bool {
        guard let first = folders.first else { return false }
        return FileManager.default.fileExists(atPath: first.appendingPathComponent(name).path)
    }

    func saveCover(_ data: Data, for trackID: String) {
        guard let name = coverName(for: trackID) else { return }
        for folder in folders {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            // Keep only the newest cover so the folder does not grow.
            if let old = try? FileManager.default.contentsOfDirectory(atPath: folder.path) {
                for file in old where file.hasPrefix("cover-") && file != name {
                    try? FileManager.default.removeItem(at: folder.appendingPathComponent(file))
                }
            }
            try? data.write(to: folder.appendingPathComponent(name), options: .atomic)
        }
    }
}
