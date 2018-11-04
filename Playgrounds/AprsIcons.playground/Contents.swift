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
    let primaryTableImage: NSImage

    init?() {
        if let image = NSImage(named: "aprs-symbols-24-0.png") {
            primaryTableImage = image
        } else {
            return nil
        }
    }

    func getImage(_ symbol: String) throws -> NSImage {
        let useTableImage: NSImage

        // determine symbol table
        switch symbol.first {
        case "/":
            useTableImage = primaryTableImage
        default:
            throw AprsIconError.invalidSymbol
        }

        // determine symbol
        guard let lookup = symbol.last else {
            throw AprsIconError.invalidSymbol
        }
        guard let symbolsIndex = symbols.firstIndex(of: String(lookup)) else {
            throw AprsIconError.invalidSymbol
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
        print("row = \(row), column = \(column)")

        // create new image by cropping the symbol table
        let cropRect = NSRect(x: column * 24, y: row * 24, width: 24, height: 24)
        let newRect = NSRect(origin: .zero, size: cropRect.size)
        let croppedImage = NSImage(size: newRect.size)

        croppedImage.lockFocus()
        useTableImage.draw(in: newRect, from: cropRect, operation: .copy, fraction: 1)
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

        let aprsIcon = AprsIcon()
        do {
            let iconImage = try aprsIcon?.getImage("/j")
            layer?.contents = iconImage
        } catch {
            fatalError("can't get icon image")
        }
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

let view: View = View(frame:NSRect(x: 0, y: 0, width: 240, height: 240))
PlaygroundPage.current.liveView = view
