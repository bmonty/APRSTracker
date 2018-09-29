//
//  AX25.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/22/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

class AX25: NSObject {

    var frame: Data
    var numberOfAddresses: Int = -1
    
    enum ax25Position {
        case destination
        case source
        case repeater1
        case repeater2
        case repeater3
        case repeater4
        case repeater5
        case repeater6
        case repeater7
        case repeater8
    }
    
    let ax25MinAddresses: Int = 2
    let ax25MaxAddresses: Int = 10
    let ax25MaxRepeaters: Int = 8
    let ax25MaxAddressLen: Int = 12
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
 
    init?(withFrame frame: Data) {
        self.frame = frame
        
        super.init()
        
        let frameSize = frame.distance(from: frame.startIndex, to: frame.endIndex)
        if frameSize < ax25MinPacketLen || frameSize > ax25MaxPacketLen {
            print("AX25 frame is not within allowable range of \(ax25MinPacketLen) to \(ax25MaxPacketLen).")
            return nil
        }
    }

    func getNumberOfAddresses() -> Int {
        // use cached value if already set
        if numberOfAddresses >= 0 {
            return numberOfAddresses
        }
        
        numberOfAddresses = 0
        
        var addressBytes = 0
        var a = frame.startIndex
        while (a < frame.distance(from: frame.startIndex, to: frame.endIndex)) && (addressBytes == 0) {
            let compare = frame[a] & ssidLastMask
            if compare > 0 {
                addressBytes = a
            }
            
            a += 1
        }
        
        if (addressBytes % 7) == 0 {
            let addresses = addressBytes / 7
            if (addresses >= ax25MinAddresses) && (addresses <= ax25MaxAddresses) {
                numberOfAddresses = addresses
            }
        }
        
        return numberOfAddresses
    }
    
    func getAddressWithSsid(addressNum: Int) -> String {
        if (addressNum < 0) {
            print("Error: address index is less than 0.")
            return ""
        }
        
        if (addressNum >= numberOfAddresses) {
            print("Error: address index is larger than number of addresses.")
            return ""
        }
        
        var addressString = String()
        for byte in 0..<6 {
            let char = frame[frame.startIndex + (addressNum * 7) + byte] >> 1 & 0x7F
            if char == 0x20 { break }
            addressString.append(String(bytes: [char], encoding: .ascii)!)
        }
        
        let ssid = (frame[frame.startIndex + (addressNum * 7) + 6] & ssidSsidMask) >> ssidSsidShift
        if ssid != 0 {
            addressString.append("-\(ssid)")
        }

        return addressString
    }
    
    func isAddressRepeated(addressNum: Int) -> Bool {
        let repeated = (frame[frame.startIndex + (addressNum * 7) + 6] & ssidHMask) >> ssidHShift
        if repeated > 0 {
            return true
        }
        
        return false
    }
    
    func getControlOffset() -> Int {
        if numberOfAddresses == -1 {
            _ = getNumberOfAddresses()
        }
        
        return frame.startIndex + (numberOfAddresses * 7)
    }
    
    // TODO: Make sure this function gives the correct result.
    //    I think all APRS has 1 control byte.
    func getNumberOfControl() -> Int {
        if numberOfAddresses == -1 {
            _ = getNumberOfAddresses()
        }
        
        let control = frame[getControlOffset()]
        
        if (control & 0x01) == 0 {
            return 1
        }
        
        if (control & 0x03) == 1 {
            return 1
        }
        
        return 1
    }
    
    func getPidOffset() -> Int {
        return getControlOffset() + getNumberOfControl()
    }
    
    func getAprsInfo() -> Data {
        let infoOffset = getPidOffset() + 1
        return frame[infoOffset..<frame.endIndex]
    }
    
    func isAprsPacket() -> Bool {
        if numberOfAddresses == -1 {
            _ = getNumberOfAddresses()
        }

        let control = frame[getControlOffset()]
        let pid = frame[getPidOffset()]
        
        return (numberOfAddresses >= 2) && (control == ax25UiFrame) && (pid == ax25NoLayer3)
    }
}
