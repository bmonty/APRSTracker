//
//  AX25.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/22/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

struct AX25Data: APRSData {
    typealias APRSDataElement = AX25Frame
    var protocolName = "AX25_FRAME"
    var data: AX25Frame
    
    init(data: AX25Frame) {
        self.data = data
    }
}

struct AX25Frame {
    let source: String
    let destination: String
    let digipeaters: [String]?
    let informationType: String
    let information: String
}

class AX25 {

    // MARK: - Constants
    let ax25MinAddresses: Int = 2
    let ax25MaxAddresses: Int = 10
    let ax25MaxRepeaters: Int = 8
    let ax25MaxAddressLen: Int = 12
    let ax25MaxDigipeaterBytes: Int = 56
    let ax25MinInfoLen: Int = 1
    let ax25MaxInfoLen: Int = 2048
    let ax25MinPacketLen: Int = 2 * 7 + 1
    let ax25MaxPacketLen: Int = 10 * 7 + 2 + 3 + 2048
    
    let ax25UiFrame: Int = 3
    let ax25NoLayer3: UInt8 = 0xF0
    
    let ssidHMask: UInt8 = 0x80
    let ssidHShift: Int = 7
    let ssidRrMask: UInt8 = 0x60
    let ssidRrShift: Int = 5
    let ssidSsidMask: UInt8 = 0x1E
    let ssidSsidShift: Int = 1
    let ssidLastMask: UInt8 = 0x01
    
    // MARK: - Properties
    var delegate: APRSParser?

    // MARK: - Methods
    private func parse(frame: Data) {
        let frameSize = frame.distance(from: frame.startIndex, to: frame.endIndex)
        if frameSize < ax25MinPacketLen || frameSize > ax25MaxPacketLen {
            print("AX25 frame is not within allowable range of \(ax25MinPacketLen) to \(ax25MaxPacketLen).")
            return
        }
        
        var ssid: UInt8 = 0
        var isGenericDigipeaterPath = false
        
        // get destination
        var destination = String()
        for byte in frame.startIndex..<frame.startIndex + 6 {
            let char = frame[byte] >> 1 & 0x7F
            if char == 0x20 { break }
            guard let destinationTemp = String(bytes: [char], encoding: .ascii) else { return }
            destination.append(destinationTemp)
        }
        ssid = (frame[frame.startIndex + 6] & ssidSsidMask) >> ssidSsidShift
        if ssid != 0 {
            destination.append("-\(ssid)")
            isGenericDigipeaterPath = true
        }
        
        // get source
        var source = String()
        for byte in frame.startIndex + 7..<frame.startIndex + 13 {
            let char = frame[byte] >> 1 & 0x7F
            if char == 0x20 { break }
            guard let sourceTemp = String(bytes: [char], encoding: .ascii) else { return }
            source.append(sourceTemp)
        }
        ssid = (frame[frame.startIndex + 13] & ssidSsidMask) >> ssidSsidShift
        if ssid != 0 {
            source.append("-\(ssid)")
        }
        
        // get digipeater addresses
        var digipeaters: [String] = []
        var digipeaterBytes = 0
        if !isGenericDigipeaterPath {
            var numberOfDigipeaters = 0
            let digipeaterStart = frame.startIndex + 14
            var a = digipeaterStart
            while a < frame.endIndex {
                if (frame[a] & ssidLastMask) > 0 {
                    digipeaterBytes += 1
                    break
                } else {
                    a += 1
                    digipeaterBytes += 1
                }
            }
            
            if (digipeaterBytes % 7) == 0 {
                numberOfDigipeaters = digipeaterBytes / 7
            } else {
                return
            }
            
            for digipeaterNum in 0..<numberOfDigipeaters {
                var digipeater = String()
                for byte in digipeaterStart + (digipeaterNum * 7)..<digipeaterStart + (digipeaterNum * 7) + 6 {
                    let char = frame[byte] >> 1 & 0x7F
                    if char == 0x20 { break }
                    guard let digipeaterTemp = String(bytes: [char], encoding: .ascii) else { return }
                    digipeater.append(digipeaterTemp)
                }
                ssid = (frame[digipeaterStart + (digipeaterNum * 7) + 6] & ssidSsidMask) >> ssidSsidShift
                if ssid != 0 {
                    digipeater.append("-\(ssid)")
                }
                
                digipeaters.append(digipeater)
            }
        }
        
        // get information field
        let informationStart = frame.startIndex + 14 + digipeaterBytes + 2
        
        let informationTypeData = frame[informationStart]
        guard let informationType = String(bytes: [informationTypeData], encoding: .ascii) else { return }
        let informationData = frame[informationStart + 1..<frame.endIndex]
        guard let information = String(bytes: informationData, encoding: .ascii) else { return }

        // create the AX25Frame Struct
        let ax25Frame = AX25Frame(source: source, destination: destination, digipeaters: digipeaters, informationType: informationType, information: information)
        
        let ax25Data = AX25Data(data: ax25Frame)
        delegate?.receivedData(data: ax25Data)
    }
}

// MARK: - Extensions
extension AX25: APRSParser {

    func receivedData<T: APRSData>(data: T) {
        guard let inputData = data.data as? Data else {
            return
        }
        parse(frame: inputData)
    }
    
}
