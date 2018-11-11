//
//  File.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/3/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import Cocoa

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
    let alternateTableImage: NSImage

    init?() {
        if let priImage = NSImage(named: "primary-aprs-icons") {
            primaryTableImage = priImage
        } else {
            return nil
        }

        if let altImage = NSImage(named: "alternate-aprs-icons") {
            alternateTableImage = altImage
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
        case "\\":
            useTableImage = alternateTableImage
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
