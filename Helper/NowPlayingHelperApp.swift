import SwiftUI

@main
struct NowPlayingHelperApp: App {
    @StateObject private var reader = SpotifyReader()

    var body: some Scene {
        MenuBarExtra {
            if let state = reader.state {
                Text(state.title)
                Text(state.artist)
                Text(state.isPlaying ? "▶︎ Свири" : "⏸ Пауза")
            } else {
                Text("Spotify не свири")
            }
            if let error = reader.lastError {
                Divider()
                Text("Грешка: \(error)")
            }
            Divider()
            Button("Изход") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: reader.state?.isPlaying == true ? "music.note" : "music.note.list")
        }
    }
}
