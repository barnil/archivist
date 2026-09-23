import Foundation
import PDFKit
import AppKit

enum PDFEngine {

    // MARK: - Errors

    enum EngineError: LocalizedError {
        case couldNotLoad
        case couldNotWrite
        case noPages
        case unsupportedFile

        var errorDescription: String? {
            switch self {
            case .couldNotLoad:
                return "Could not read the selected file."

            case .couldNotWrite:
                return "Could not write the output file."

            case .noPages:
                return "The document contains no pages."

            case .unsupportedFile:
                return "The selected file is not supported."
            }
        }
    }


    // MARK: - Security Scoped Access

    private static func withSecurityScopedAccess<T>(
        to urls: [URL],
        operation: () throws -> T
    ) throws -> T {

        var accessedURLs: [URL] = []

        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                accessedURLs.append(url)
            }
        }

        defer {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }


    // MARK: - Output URL

    private static func outputURL(
        basedOn url: URL,
        suffix: String,
        ext: String = "pdf"
    ) -> URL {

        let directory = url.deletingLastPathComponent()

        let name = url
            .deletingPathExtension()
            .lastPathComponent

        return directory.appendingPathComponent(
            "\(name)_\(suffix).\(ext)"
        )
    }


    // MARK: - MERGE

    static func merge(
        urls: [URL]
    ) throws -> URL {

        guard !urls.isEmpty else {
            throw EngineError.noPages
        }

        return try withSecurityScopedAccess(to: urls) {

            let mergedDocument = PDFDocument()

            var outputPageIndex = 0

            for url in urls {

                guard let document = PDFDocument(url: url) else {
                    throw EngineError.couldNotLoad
                }

                guard document.pageCount > 0 else {
                    continue
                }

                for pageIndex in 0..<document.pageCount {

                    guard let page = document.page(at: pageIndex) else {
                        continue
                    }

                    mergedDocument.insert(
                        page,
                        at: outputPageIndex
                    )

                    outputPageIndex += 1
                }
            }

            guard mergedDocument.pageCount > 0 else {
                throw EngineError.noPages
            }

            let output = outputURL(
                basedOn: urls[0],
                suffix: "merged"
            )

            guard mergedDocument.write(to: output) else {
                throw EngineError.couldNotWrite
            }

            return output
        }
    }


    // MARK: - SPLIT

    static func split(
        url: URL
    ) throws -> [URL] {

        return try withSecurityScopedAccess(to: [url]) {

            guard let document = PDFDocument(url: url) else {
                throw EngineError.couldNotLoad
            }

            guard document.pageCount > 0 else {
                throw EngineError.noPages
            }

            var outputFiles: [URL] = []

            for pageIndex in 0..<document.pageCount {

                guard let page = document.page(at: pageIndex) else {
                    continue
                }

                let singlePageDocument = PDFDocument()

                singlePageDocument.insert(
                    page,
                    at: 0
                )

                let output = outputURL(
                    basedOn: url,
                    suffix: "page\(pageIndex + 1)"
                )

                guard singlePageDocument.write(to: output) else {
                    throw EngineError.couldNotWrite
                }

                outputFiles.append(output)
            }

            return outputFiles
        }
    }


    // MARK: - COMPRESS

    static func compress(
        url: URL,
        imageSize: CGSize = CGSize(
            width: 1200,
            height: 1600
        )
    ) throws -> URL {

        return try withSecurityScopedAccess(to: [url]) {

            guard let document = PDFDocument(url: url) else {
                throw EngineError.couldNotLoad
            }

            guard document.pageCount > 0 else {
                throw EngineError.noPages
            }

            let compressedDocument = PDFDocument()

            for pageIndex in 0..<document.pageCount {

                guard let page = document.page(at: pageIndex) else {
                    continue
                }

                /*
                 Rasterize the page at a reduced resolution.

                 This is intentionally simple for the first version.
                 The final compression engine can later offer:
                 - Low
                 - Medium
                 - High
                 - Custom DPI
                 - Image quality
                */

                let image = page.thumbnail(
                    of: imageSize,
                    for: .mediaBox
                )

                guard let compressedPage = PDFPage(
                    image: image
                ) else {
                    continue
                }

                compressedDocument.insert(
                    compressedPage,
                    at: compressedDocument.pageCount
                )
            }

            guard compressedDocument.pageCount > 0 else {
                throw EngineError.couldNotWrite
            }

            let output = outputURL(
                basedOn: url,
                suffix: "compressed"
            )

            guard compressedDocument.write(to: output) else {
                throw EngineError.couldNotWrite
            }

            return output
        }
    }


    // MARK: - PDF → JPG

    static func pdfToImages(
        url: URL,
        imageSize: CGSize = CGSize(
            width: 1600,
            height: 2200
        )
    ) throws -> [URL] {

        return try withSecurityScopedAccess(to: [url]) {

            guard let document = PDFDocument(url: url) else {
                throw EngineError.couldNotLoad
            }

            guard document.pageCount > 0 else {
                throw EngineError.noPages
            }

            var outputFiles: [URL] = []

            let directory = url.deletingLastPathComponent()

            let baseName = url
                .deletingPathExtension()
                .lastPathComponent

            for pageIndex in 0..<document.pageCount {

                guard let page = document.page(at: pageIndex) else {
                    continue
                }

                let image = page.thumbnail(
                    of: imageSize,
                    for: .mediaBox
                )

                guard
                    let tiffData = image.tiffRepresentation,
                    let bitmap = NSBitmapImageRep(data: tiffData),
                    let jpegData = bitmap.representation(
                        using: .jpeg,
                        properties: [
                            .compressionFactor: 0.9
                        ]
                    )
                else {
                    continue
                }

                let output = directory.appendingPathComponent(
                    "\(baseName)_page\(pageIndex + 1).jpg"
                )

                try jpegData.write(
                    to: output
                )

                outputFiles.append(output)
            }

            return outputFiles
        }
    }


    // MARK: - JPG / Images → PDF

    static func imagesToPDF(
        urls: [URL]
    ) throws -> URL {

        guard let firstURL = urls.first else {
            throw EngineError.noPages
        }

        return try withSecurityScopedAccess(to: urls) {

            let document = PDFDocument()

            for url in urls {

                guard let image = NSImage(
                    contentsOf: url
                ) else {
                    continue
                }

                guard let page = PDFPage(
                    image: image
                ) else {
                    continue
                }

                document.insert(
                    page,
                    at: document.pageCount
                )
            }

            guard document.pageCount > 0 else {
                throw EngineError.couldNotLoad
            }

            let output = outputURL(
                basedOn: firstURL,
                suffix: "combined"
            )

            guard document.write(to: output) else {
                throw EngineError.couldNotWrite
            }

            return output
        }
    }


    // MARK: - ROTATE

    static func rotate(
        url: URL,
        degrees: Int
    ) throws -> URL {

        return try withSecurityScopedAccess(to: [url]) {

            guard let document = PDFDocument(url: url) else {
                throw EngineError.couldNotLoad
            }

            guard document.pageCount > 0 else {
                throw EngineError.noPages
            }

            for pageIndex in 0..<document.pageCount {

                guard let page = document.page(
                    at: pageIndex
                ) else {
                    continue
                }

                // PDFKit stores rotation as an integer.
                // Normalize it to 0...359 degrees.

                var newRotation =
                    (page.rotation + degrees) % 360

                if newRotation < 0 {
                    newRotation += 360
                }

                page.rotation = newRotation
            }

            let output = outputURL(
                basedOn: url,
                suffix: "rotated"
            )

            guard document.write(to: output) else {
                throw EngineError.couldNotWrite
            }

            return output
        }
    }
}
