//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

// APRS primary symbol table, index 0 is not used.
let symbols = [" ", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+",
               ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7",
               "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C",
               "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
               "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[",
               "\\", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g",
               "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s",
               "t", "w", "x", "y", "z", "{", "|", "}", "~"]

enum AprsIconError: Error {
    case invalidSymbol
    case imageProcessingError
}

public class AprsIcon {

    static let shared = AprsIcon()

    private let primaryTableImage: NSImage
    private let alternateTableImage: NSImage
    private let overlayImage: NSImage

    private init?() {
        if let priImage = NSImage(named: "primary-aprs-icons") {
            primaryTableImage = priImage
        } else {
            print("missing primary aprs icons image")
            return nil
        }

        if let altImage = NSImage(named: "alternate-aprs-icons") {
            alternateTableImage = altImage
        } else {
            print("missing alternate aprs icons image")
            return nil
        }

        if let overlayImage = NSImage(named: "aprs-overlays") {
            self.overlayImage = overlayImage
        } else {
            return nil
        }
    }

    func getImage(_ symbol: String) throws -> NSImage {
        guard let symbolIdentifier = symbol.first else {
            throw AprsIconError.invalidSymbol
        }
        guard let symbolCode = symbol.last else {
            throw AprsIconError.invalidSymbol
        }

        switch symbolIdentifier {

        case "/":
            guard let symbolImage = getSymbol(symbolCode,
                                              withTableImage: primaryTableImage) else {
                                                throw AprsIconError.imageProcessingError
            }
            return symbolImage

        case "\\":
            guard let symbolImage = getSymbol(symbolCode,
                                              withTableImage: alternateTableImage) else {
                                                throw AprsIconError.imageProcessingError
            }
            return symbolImage

        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C",
             "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
             "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z":
            guard let symbolImage = getSymbolWithOverlay(symbolIdentifier: symbolIdentifier,
                                                         symbolCode: symbolCode) else {
                                                            throw AprsIconError.imageProcessingError
            }
            return symbolImage

        case "a", "b", "c", "d", "e", "f", "g", "h", "i", "j":
            throw AprsIconError.invalidSymbol

        default:
            throw AprsIconError.invalidSymbol
        }
    }

    func getSymbol(_ symbolCode: Character, withTableImage image: NSImage) -> NSImage? {
        guard let symbol = getIconImage(symbolCode, withTableImage: image) else {
            return nil
        }
        return symbol
    }

    func getSymbolWithOverlay(symbolIdentifier: Character,
                              symbolCode: Character) -> NSImage? {
        guard let overlayImage = getIconImage(symbolIdentifier,
                                              withTableImage: overlayImage) else {
                                                return nil
        }
        guard let baseImage = getIconImage(symbolCode,
                                           withTableImage: alternateTableImage) else {
                                            return nil
        }

        baseImage.lockFocus()
        overlayImage.draw(in: NSRect(origin: .zero, size: baseImage.size),
                          from: NSRect(origin: .zero, size: overlayImage.size),
                          operation: .sourceOver, fraction: 1)
        baseImage.unlockFocus()

        return baseImage
    }

    private func getIconImage(_ symbolCode: Character, withTableImage image: NSImage)
        -> NSImage? {
            // determine symbol
            guard let symbolsIndex = symbols.firstIndex(of: String(symbolCode)) else {
                return nil
            }

            // calculate position of icon in the image
            let row: Int
            if (symbolsIndex % 16) == 0 {
                row = 5 - ((symbolsIndex / 16) - 1)
            } else {
                row = 5 - (symbolsIndex / 16)
            }

            let column: Int
            if (symbolsIndex % 16) == 0 {
                column = 15
            } else {
                column = (symbolsIndex % 16) - 1
            }

            // create new image by cropping the symbol table
            let cropRect = NSRect(x: column * 24, y: row * 24, width: 24, height: 24)
            let newRect = NSRect(origin: .zero, size: cropRect.size)
            let croppedImage = NSImage(size: newRect.size)

            croppedImage.lockFocus()
            image.draw(in: newRect, from: cropRect, operation: .copy, fraction: 1)
            croppedImage.unlockFocus()

            return croppedImage
    }

}

class View: NSView {

    override var isFlipped: Bool { return true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.wantsLayer = true
        layer = CALayer()

        let bgColor = NSColor.white
        layer?.backgroundColor = bgColor.cgColor
        layer?.masksToBounds = false

        do {
            let iconImage = try AprsIcon.shared?.getImage("S#")
            layer?.contents = iconImage
        } catch {
            fatalError("can't get icon image")
        }
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

let view: View = View(frame:NSRect(x: 0, y: 0, width: 24, height: 24))
PlaygroundPage.current.liveView = view
