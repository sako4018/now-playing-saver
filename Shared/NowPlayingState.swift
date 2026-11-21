import Foundation

/// What is playing right now. The helper writes it, the screen saver reads it.
struct NowPlayingState: Codable, Equatable {
    var isPlaying: Bool
    var trackID: String
    var title: String
    var artist: String
    var album: String
    /// Song length in seconds.
    var duration: Double
    /// Position in seconds at the moment `updatedAt`.
    var position: Double
    var updatedAt: Date
    /// File name of the cover image next to state.json (nil until it is downloaded).
    var coverFileName: String?
}

enum SharedLocation {
    static let folderName = "NowPlayingSaver"
    static let stateFileName = "state.json"
    static let saverContainerID = "com.apple.ScreenSaver.Engine.legacyScreenSaver"

    /// The real home folder, even when the code runs inside a sandbox.
    static func realHomeDirectory() -> String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return String(cString: dir)
        }
        return NSHomeDirectory()
    }

    /// All folders tried during the step 1 test, with a short label for each.
    static func candidateFolders() -> [(label: String, url: URL)] {
        let home = URL(fileURLWithPath: realHomeDirectory())
        return [
            ("container", home.appendingPathComponent("Library/Containers/\(saverContainerID)/Data/Library/Application Support/\(folderName)")),
            ("appSupport", home.appendingPathComponent("Library/Application Support/\(folderName)")),
            ("usersShared", URL(fileURLWithPath: "/Users/Shared/\(folderName)")),
            ("tmp", URL(fileURLWithPath: "/private/tmp/\(folderName)"))
        ]
    }
}
