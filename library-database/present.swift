import AppKit

private let interval: TimeInterval = 3

private struct DemoReply: Decodable {
    let title: String?
    let hint: String?
    let output: String?
    let done: Bool?
    let error: String?
}

private final class DemoSession {
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()

    init() throws {
        let script = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("present.py")
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [script.path]
        process.standardInput = input
        process.standardOutput = output
        try process.run()
    }

    func next() throws -> DemoReply {
        try input.fileHandleForWriting.write(contentsOf: Data([10]))
        var reply = Data()
        // The worker sends one JSON line per request and keeps the pipe open.
        while reply.last != 10 {
            let chunk = output.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            reply.append(chunk)
        }
        return try JSONDecoder().decode(DemoReply.self, from: reply)
    }

    deinit {
        // EOF closes the worker's generator and its in-memory DB.
        try? input.fileHandleForWriting.close()
        try? output.fileHandleForReading.close()
    }
}

private final class Presentation: NSObject, NSWindowDelegate {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 960, height: 660),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    let button = NSButton(title: "시연 시작", target: nil, action: nil)
    let status = NSTextField(labelWithString: "3초 간격 · 같은 버튼으로 일시정지와 재개")
    let title = NSTextField(wrappingLabelWithString: "도서 대여 데이터베이스")
    let hint = NSTextField(wrappingLabelWithString: "시연 시작을 누르면 빈 임시 DB에서 시작합니다.")
    let output = NSTextView()
    private var session: DemoSession?
    private var timer: Timer?
    private var number = 0

    override init() {
        super.init()
        window.title = "도서 대여 · 자동 시연"
        window.minSize = NSSize(width: 600, height: 400)
        window.delegate = self
        window.center()

        button.target = self
        button.action = #selector(toggle)
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 118).isActive = true
        status.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        status.textColor = .secondaryLabelColor
        title.font = .systemFont(ofSize: 25, weight: .bold)
        hint.font = .systemFont(ofSize: 16)
        for label in [title, hint] {
            label.setContentCompressionResistancePriority(.required, for: .vertical)
        }

        output.isEditable = false
        output.isRichText = false
        output.isVerticallyResizable = true
        output.isHorizontallyResizable = false
        output.autoresizingMask = [.width]
        output.textContainer?.widthTracksTextView = true
        output.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        output.textContainerInset = NSSize(width: 16, height: 14)
        let scroll = NSScrollView()
        scroll.borderType = .bezelBorder
        scroll.hasVerticalScroller = true
        scroll.documentView = output

        let header = NSStackView(views: [status, NSView(), button])
        header.alignment = .centerY
        let layout = NSStackView(views: [header, title, hint, scroll])
        layout.orientation = .vertical
        layout.alignment = .leading
        layout.spacing = 12
        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = content
        content.addSubview(layout)
        layout.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layout.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            layout.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            layout.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            layout.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -22),
            header.widthAnchor.constraint(equalTo: layout.widthAnchor),
            title.widthAnchor.constraint(equalTo: layout.widthAnchor),
            hint.widthAnchor.constraint(equalTo: layout.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: layout.widthAnchor),
        ])
    }

    @objc func toggle() {
        if session == nil {
            do {
                session = try DemoSession()
                number = 0
                advance()
            } catch {
                finish("시연 시작 오류", detail: error.localizedDescription)
            }
        } else if let timer = timer {
            timer.invalidate()
            self.timer = nil
            status.stringValue = "\(number)단계 · 일시정지"
            button.title = "재개"
        } else {
            schedule()
        }
    }

    private func schedule() {
        status.stringValue = "\(number)단계 · 3초 간격으로 재생 중"
        button.title = "일시정지"
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.advance()
        }
    }

    private func advance() {
        timer = nil
        guard let session = session else { return }
        do {
            let reply = try session.next()
            if let error = reply.error {
                finish("시연 중 오류", detail: error)
            } else if reply.done == true {
                finish("시연 완료")
            } else {
                number += 1
                title.stringValue = reply.title ?? ""
                hint.stringValue = reply.hint ?? ""
                hint.isHidden = hint.stringValue.isEmpty
                output.string = reply.output ?? ""
                output.scrollRangeToVisible(NSRange(location: 0, length: 0))
                schedule()
            }
        } catch {
            finish("시연 실행 오류", detail: error.localizedDescription)
        }
    }

    private func finish(_ message: String, detail: String? = nil) {
        session = nil
        status.stringValue = message
        button.title = "다시 시연"
        if let detail = detail {
            title.stringValue = message
            hint.isHidden = true
            output.string = detail
        }
    }

    func windowWillClose(_ notification: Notification) {
        timer?.invalidate()
        session = nil
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
private let presentation = Presentation()
presentation.window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
app.run()
