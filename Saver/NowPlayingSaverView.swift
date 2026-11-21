import ScreenSaver
import os

/// Step 1 test: shows which shared folders the screen saver can read.
final class NowPlayingSaverView: ScreenSaverView {
    private let log = Logger(subsystem: "com.sako4018.NowPlayingSaver", category: "saver")
    private var lines: [String] = []

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0
        runDiagnostics()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func animateOneFrame() {
        runDiagnostics()
        needsDisplay = true
    }

    private func runDiagnostics() {
        var result = [
            "host: \(Bundle.main.bundleIdentifier ?? "?")",
            "NSHomeDirectory: \(NSHomeDirectory())"
        ]
        for (label, folder) in SharedLocation.candidateFolders() {
            let file = folder.appendingPathComponent(SharedLocation.stateFileName)
            if let data = try? Data(contentsOf: file) {
                let preview = String(decoding: data.prefix(60), as: UTF8.self)
                result.append("\(label): OK \(data.count)B \(preview)")
            } else {
                result.append("\(label): NO")
            }
        }
        if result != lines {
            for line in result {
                log.notice("NPS \(line, privacy: .public)")
            }
        }
        lines = result
    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        let size: CGFloat = isPreview ? 7 : 20
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: size, weight: .regular),
            .foregroundColor: NSColor.white
        ]
        var y = bounds.height - size * 3
        for line in lines {
            (line as NSString).draw(at: NSPoint(x: size, y: y), withAttributes: attributes)
            y -= size * 1.5
        }
    }
}
