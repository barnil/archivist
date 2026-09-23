import SwiftUI

// MARK: - Beveled panel (used for the drop zone, activity list, status card)
struct RetroPanel<Content: View>: View {
    var inset: Bool = false // true = "pressed in" look, false = "raised" look
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(RetroMetrics.panelPadding)
            .background(RetroPalette.panel)
            .overlay(bevelBorder)
    }

    private var bevelBorder: some View {
        GeometryReader { _ in
            Rectangle()
                .strokeBorder(RetroPalette.textDark, lineWidth: 1)
            // top/left light edge, bottom/right dark edge to fake a bevel
            VStack {
                HStack {
                    Rectangle().fill(inset ? RetroPalette.bevelDark : RetroPalette.bevelLight)
                        .frame(height: 1)
                }
                Spacer()
            }
            HStack {
                VStack {
                    Rectangle().fill(inset ? RetroPalette.bevelDark : RetroPalette.bevelLight)
                        .frame(width: 1)
                }
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle().fill(inset ? RetroPalette.bevelLight : RetroPalette.bevelDark)
                    .frame(height: 1)
            }
            HStack {
                Spacer()
                Rectangle().fill(inset ? RetroPalette.bevelLight : RetroPalette.bevelDark)
                    .frame(width: 1)
            }
        }
    }
}

// MARK: - Physical push button
struct RetroButtonStyle: ButtonStyle {
    var tint: Color = RetroPalette.panel
    var minWidth: CGFloat = 120

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(RetroFont.pixel(13))
            .foregroundColor(RetroPalette.textDark)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(minWidth: minWidth)
            .background(tint)
            .overlay(
                Rectangle().strokeBorder(RetroPalette.textDark, lineWidth: RetroMetrics.borderWidth)
            )
            .overlay(alignment: .topLeading) {
                Rectangle().fill(pressed ? RetroPalette.bevelDark : RetroPalette.bevelLight)
                    .frame(height: 2)
            }
            .overlay(alignment: .bottomTrailing) {
                Rectangle().fill(pressed ? RetroPalette.bevelLight : RetroPalette.bevelDark)
                    .frame(height: 2)
            }
            .offset(y: pressed ? RetroMetrics.pressedOffset : 0)
            .shadow(color: RetroPalette.textDark.opacity(pressed ? 0 : 0.35),
                    radius: 0, x: pressed ? 0 : 3, y: pressed ? 0 : 3)
            .animation(.linear(duration: 0.05), value: pressed)
    }
}

struct RetroButton: View {
    let title: String
    var tint: Color = RetroPalette.panel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
        }
        .buttonStyle(RetroButtonStyle(tint: tint))
    }
}

// MARK: - Header bar ("ARCHIVIST.EXE" title strip)
struct RetroHeader: View {
    var body: some View {
        HStack {
            Text("▣ ARCHIVIST.EXE")
                .font(RetroFont.pixel(14))
            Spacer()
            Text("_  □  X")
                .font(RetroFont.mono(12))
        }
        .foregroundColor(RetroPalette.panel)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RetroPalette.textDark)
    }
}

// MARK: - Footer status bar ("OFFLINE MODE / FILES NEVER LEAVE THIS MAC")
struct RetroStatusBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(RetroPalette.accent).frame(width: 8, height: 8)
                Text("OFFLINE MODE").font(RetroFont.mono(11, weight: .bold))
            }
            Spacer()
            Text("FILES NEVER LEAVE THIS MAC").font(RetroFont.mono(11, weight: .bold))
        }
        .foregroundColor(RetroPalette.textDark)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RetroPalette.highlight)
        .overlay(Rectangle().stroke(RetroPalette.textDark, lineWidth: 1))
    }
}

// MARK: - Drop zone
struct RetroDropZone: View {
    var isTargeted: Bool
    let onSelectFile: () -> Void

    var body: some View {
        RetroPanel(inset: true) {
            VStack(spacing: 14) {
                Text(isTargeted ? "RELEASE TO LOAD" : "DROP PDF FILE HERE")
                    .font(RetroFont.pixel(15))
                    .foregroundColor(RetroPalette.textDark)
                RetroButton(title: "Select File", action: onSelectFile)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        }
        .background(isTargeted ? RetroPalette.highlight.opacity(0.4) : Color.clear)
    }
}

// MARK: - Pixel-style progress bar (block characters, chunky segments)
struct PixelProgressBar: View {
    let progress: Double // 0...1
    var segments: Int = 24

    var body: some View {
        GeometryReader { geo in
            let filled = Int(progress * Double(segments))
            HStack(spacing: 2) {
                ForEach(0..<segments, id: \.self) { i in
                    Rectangle()
                        .fill(i < filled ? RetroPalette.accent : RetroPalette.panel)
                }
            }
            .overlay(Rectangle().stroke(RetroPalette.textDark, lineWidth: 1))
        }
        .frame(height: 16)
    }
}

// MARK: - Fake "system" terminal shown while processing
struct StatusTerminal: View {
    let title: String
    let inputName: String
    let sizeLabel: String
    let progress: Double
    let logLines: [String]
    let statusText: String

    var body: some View {
        RetroPanel(inset: false) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(RetroFont.mono(12, weight: .bold))
                Divider().background(RetroPalette.textDark)
                Text("INPUT: \(inputName)").font(RetroFont.mono(11))
                Text("SIZE: \(sizeLabel)").font(RetroFont.mono(11))
                PixelProgressBar(progress: progress)
                Text("\(Int(progress * 100))%").font(RetroFont.mono(11))
                ForEach(logLines, id: \.self) { line in
                    Text("> \(line)").font(RetroFont.mono(11))
                }
                Text("STATUS: \(statusText)")
                    .font(RetroFont.mono(11, weight: .bold))
                    .foregroundColor(statusText == "DONE" ? RetroPalette.accent : RetroPalette.warning)
            }
        }
        .foregroundColor(RetroPalette.textDark)
        .frame(maxWidth: 380)
    }
}

// MARK: - Privacy card ("NETWORK ACCESS DISABLED" etc.)
struct PrivacyCard: View {
    var body: some View {
        RetroPanel(inset: false) {
            VStack(alignment: .leading, spacing: 6) {
                Text("[LOCK] LOCAL PROCESSING").font(RetroFont.mono(12, weight: .bold))
                Divider().background(RetroPalette.textDark)
                privacyRow("NETWORK ACCESS", "DISABLED")
                privacyRow("CLOUD STORAGE", "NONE")
                privacyRow("TELEMETRY", "NONE")
                privacyRow("FILE RETENTION", "NONE")
                Divider().background(RetroPalette.textDark)
                Text("STATUS: SECURE")
                    .font(RetroFont.mono(12, weight: .bold))
                    .foregroundColor(RetroPalette.accent)
            }
        }
        .foregroundColor(RetroPalette.textDark)
    }

    private func privacyRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(RetroFont.mono(11))
            Spacer()
            Text("........ \(value)").font(RetroFont.mono(11))
        }
    }
}
