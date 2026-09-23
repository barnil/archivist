import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {

    @State private var selectedFiles: [URL] = []
    @State private var isTargeted = false
    @State private var showImporter = false
    @State private var activityLog: [String] = []
    @State private var alertMessage: String?

    @StateObject private var processing = ProcessingState()

    var body: some View {

        ZStack {

            VStack(spacing: 0) {

                RetroHeader()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {

                        // MARK: Drop Zone

                        RetroDropZone(
                            isTargeted: isTargeted,
                            onSelectFile: {
                                showImporter = true
                            }
                        )
                        .onDrop(
                            of: [.fileURL],
                            isTargeted: $isTargeted
                        ) { providers in

                            handleDrop(providers)
                        }


                        // MARK: Loaded Files

                        if !selectedFiles.isEmpty {

                            RetroPanel(inset: true) {

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(
                                        "LOADED (\(selectedFiles.count)):"
                                    )
                                    .font(
                                        RetroFont.mono(
                                            11,
                                            weight: .bold
                                        )
                                    )

                                    ForEach(
                                        selectedFiles,
                                        id: \.self
                                    ) { url in

                                        Text(
                                            "• \(url.lastPathComponent)"
                                        )
                                        .font(
                                            RetroFont.mono(11)
                                        )
                                    }
                                }
                                .foregroundColor(
                                    RetroPalette.textDark
                                )
                            }
                        }


                        // MARK: Tools

                        toolGrid


                        // MARK: Activity

                        RetroPanel(inset: false) {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("ACTIVITY")
                                    .font(
                                        RetroFont.mono(
                                            12,
                                            weight: .bold
                                        )
                                    )

                                Divider()
                                    .background(
                                        RetroPalette.textDark
                                    )

                                if activityLog.isEmpty {

                                    Text("No recent files.")
                                        .font(
                                            RetroFont.mono(11)
                                        )

                                } else {

                                    ForEach(
                                        activityLog.suffix(6),
                                        id: \.self
                                    ) { line in

                                        Text(line)
                                            .font(
                                                RetroFont.mono(11)
                                            )
                                    }
                                }
                            }
                            .foregroundColor(
                                RetroPalette.textDark
                            )
                        }


                        // MARK: Privacy

                        PrivacyCard()
                    }
                    .padding(16)
                }
                .background(
                    RetroPalette.background
                )

                RetroStatusBar()
            }


            // MARK: Processing Overlay

            ProcessingOverlay(
                state: processing
            )
        }


        // MARK: File Importer

        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [
                .pdf,
                .jpeg,
                .png,
                .image
            ],
            allowsMultipleSelection: true
        ) { result in

            switch result {

            case .success(let urls):

                selectedFiles = urls

                activityLog.append(
                    "Loaded \(urls.count) file(s)"
                )

            case .failure(let error):

                alertMessage =
                    "Could not load files: \(error.localizedDescription)"
            }
        }


        // MARK: Alert

        .alert(
            "Archivist",
            isPresented: Binding(
                get: {
                    alertMessage != nil
                },
                set: { newValue in
                    if !newValue {
                        alertMessage = nil
                    }
                }
            )
        ) {

            Button("OK") {
                alertMessage = nil
            }

        } message: {

            Text(
                alertMessage ?? ""
            )
        }
    }


    // MARK: Tool Grid

    private var toolGrid: some View {

        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        return LazyVGrid(
            columns: columns,
            spacing: 10
        ) {

            RetroButton(
                title: "Merge"
            ) {
                runMerge()
            }

            RetroButton(
                title: "Split"
            ) {
                runSplit()
            }

            RetroButton(
                title: "Compress"
            ) {
                runCompress()
            }

            RetroButton(
                title: "PDF → JPG"
            ) {
                runPDFToImages()
            }

            RetroButton(
                title: "JPG → PDF"
            ) {
                runImagesToPDF()
            }

            RetroButton(
                title: "Rotate"
            ) {
                runRotate()
            }
        }
    }


    // MARK: Drag & Drop

    private func handleDrop(
        _ providers: [NSItemProvider]
    ) -> Bool {

        let group = DispatchGroup()

        var urls: [URL] = []

        let lock = NSLock()

        for provider in providers {

            group.enter()

            provider.loadDataRepresentation(
                forTypeIdentifier: UTType.fileURL.identifier
            ) { data, error in

                defer {
                    group.leave()
                }

                guard
                    error == nil,
                    let data,
                    let url = URL(
                        dataRepresentation: data,
                        relativeTo: nil
                    )
                else {
                    return
                }

                lock.lock()
                urls.append(url)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {

            if !urls.isEmpty {

                selectedFiles = urls

                activityLog.append(
                    "Dropped \(urls.count) file(s)"
                )
            }
        }

        return true
    }


    // MARK: File Size

    private func fileSizeLabel(
        for url: URL
    ) -> String {

        let attributes =
            try? FileManager.default.attributesOfItem(
                atPath: url.path
            )

        let bytes =
            attributes?[.size] as? Int64 ?? 0

        let mb =
            Double(bytes) / 1_048_576

        return String(
            format: "%.2f MB",
            mb
        )
    }


    // MARK: Merge

    private func runMerge() {

        guard selectedFiles.count >= 2 else {

            alertMessage =
                "Load at least two PDF files to merge."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: "\(selectedFiles.count) files",
            sizeLabel: fileSizeLabel(
                for: selectedFiles[0]
            ),
            steps: [
                "Reading documents",
                "Combining pages",
                "Writing output"
            ]
        ) {

            let out =
                try PDFEngine.merge(
                    urls: selectedFiles
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "Merged → \(out.lastPathComponent)"
                )
            }

            return "Saved \(out.lastPathComponent)"
        }
    }


    // MARK: Split

    private func runSplit() {

        guard let first = selectedFiles.first else {

            alertMessage =
                "Load a PDF file to split."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: first.lastPathComponent,
            sizeLabel: fileSizeLabel(
                for: first
            ),
            steps: [
                "Reading document",
                "Splitting pages",
                "Writing output"
            ]
        ) {

            let out =
                try PDFEngine.split(
                    url: first
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "Split → \(out.count) page files"
                )
            }

            return "Wrote \(out.count) files"
        }
    }


    // MARK: Compress

    private func runCompress() {

        guard let first = selectedFiles.first else {

            alertMessage =
                "Load a PDF file to compress."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: first.lastPathComponent,
            sizeLabel: fileSizeLabel(
                for: first
            ),
            steps: [
                "Reading document",
                "Re-rendering pages",
                "Writing output"
            ]
        ) {

            let out =
                try PDFEngine.compress(
                    url: first
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "Compressed → \(out.lastPathComponent)"
                )
            }

            return "Saved \(out.lastPathComponent)"
        }
    }


    // MARK: PDF → Images

    private func runPDFToImages() {

        guard let first = selectedFiles.first else {

            alertMessage =
                "Load a PDF file to convert."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: first.lastPathComponent,
            sizeLabel: fileSizeLabel(
                for: first
            ),
            steps: [
                "Reading document",
                "Rendering pages",
                "Writing JPGs"
            ]
        ) {

            let out =
                try PDFEngine.pdfToImages(
                    url: first
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "PDF → JPG: \(out.count) images"
                )
            }

            return "Wrote \(out.count) images"
        }
    }


    // MARK: Images → PDF

    private func runImagesToPDF() {

        guard !selectedFiles.isEmpty else {

            alertMessage =
                "Load one or more images to convert."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: "\(selectedFiles.count) images",
            sizeLabel: fileSizeLabel(
                for: selectedFiles[0]
            ),
            steps: [
                "Reading images",
                "Building pages",
                "Writing output"
            ]
        ) {

            let out =
                try PDFEngine.imagesToPDF(
                    urls: selectedFiles
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "JPG → PDF → \(out.lastPathComponent)"
                )
            }

            return "Saved \(out.lastPathComponent)"
        }
    }


    // MARK: Rotate

    private func runRotate() {

        guard let first = selectedFiles.first else {

            alertMessage =
                "Load a PDF file to rotate."

            return
        }

        processing.run(
            title: "ARCHIVIST PROCESSOR v1.0",
            inputName: first.lastPathComponent,
            sizeLabel: fileSizeLabel(
                for: first
            ),
            steps: [
                "Reading document",
                "Rotating pages",
                "Writing output"
            ]
        ) {

            let out =
                try PDFEngine.rotate(
                    url: first,
                    degrees: 90
                )

            DispatchQueue.main.async {

                activityLog.append(
                    "Rotated → \(out.lastPathComponent)"
                )
            }

            return "Saved \(out.lastPathComponent)"
        }
    }
}


#Preview {

    ContentView()
        .frame(
            width: 720,
            height: 600
        )
}
