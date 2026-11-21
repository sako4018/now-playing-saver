import AppKit
import Foundation

/// Asks Spotify every second what is playing and saves it for the screen saver.
@MainActor
final class SpotifyReader: ObservableObject {
    @Published private(set) var state: NowPlayingState?
    @Published private(set) var lastError: String?

    private var timer: Timer?
    private var coverTrackID: String?
    private let writer = StateWriter()

    private let script = NSAppleScript(source: """
        tell application "Spotify"
            if player state is stopped then return {"stopped"}
            set t to current track
            return {player state as string, id of t, name of t, artist of t, album of t, artwork url of t, duration of t, player position}
        end tell
        """)

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        poll()
    }

    func poll() {
        // Do not start Spotify by asking it something when it is closed.
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client")
        if running.isEmpty {
            save(nil)
            return
        }

        var errorInfo: NSDictionary?
        guard let result = script?.executeAndReturnError(&errorInfo) else {
            lastError = errorInfo?[NSAppleScript.errorMessage] as? String ?? "AppleScript"
            return
        }
        lastError = nil

        if result.numberOfItems < 8 {
            save(nil)
            return
        }

        let trackID = text(result, 2)
        let artworkURL = text(result, 6)
        var newState = NowPlayingState(
            isPlaying: text(result, 1) == "playing",
            trackID: trackID,
            title: text(result, 3),
            artist: text(result, 4),
            album: text(result, 5),
            duration: number(result, 7) / 1000.0,   // Spotify gives milliseconds
            position: number(result, 8),
            updatedAt: Date(),
            coverFileName: state?.trackID == trackID ? state?.coverFileName : nil
        )

        if trackID != coverTrackID {
            coverTrackID = trackID
            downloadCover(from: artworkURL, trackID: trackID)
        }
        if newState.coverFileName == nil, coverTrackID == trackID, let name = writer.coverName(for: trackID), writer.coverExists(name) {
            newState.coverFileName = name
        }
        save(newState)
    }

    private func save(_ newState: NowPlayingState?) {
        state = newState
        writer.write(newState)
    }

    private func downloadCover(from address: String, trackID: String) {
        guard let url = URL(string: address) else { return }
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            writer.saveCover(data, for: trackID)
            // Store the file name right away so the saver gets the new cover quickly.
            if state?.trackID == trackID {
                var updated = state
                updated?.coverFileName = writer.coverName(for: trackID)
                save(updated)
            }
        }
    }

    // AppleScript lists start from 1.
    private func text(_ list: NSAppleEventDescriptor, _ index: Int) -> String {
        list.atIndex(index)?.stringValue ?? ""
    }

    private func number(_ list: NSAppleEventDescriptor, _ index: Int) -> Double {
        Double(text(list, index).replacingOccurrences(of: ",", with: ".")) ?? 0
    }
}
