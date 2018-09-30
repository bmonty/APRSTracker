//
//  APRS.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/25/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import MapKit

struct APRSBeaconData: APRSData {
    typealias APRSDataElement = APRSBeaconInfo
    var protocolName = "APRS_BEACON_INFO"
    var data: APRSBeaconInfo
    
    init(data: APRSBeaconInfo) {
        self.data = data
    }
}

struct APRSBeaconInfo {
    var station: String
    var destination: String
    var digipeaters: [String]?
    var message: String?
    var timeStamp: Date
    var position: CLLocationCoordinate2D
    
    init(station: String, destination: String, digipeaters: [String]?, message: String?, position: CLLocationCoordinate2D) {
        self.station = station
        self.destination = destination
        self.digipeaters = digipeaters
        self.message = message
        self.position = position
        self.timeStamp = Date()
    }
}

enum APRSBeaconParseError: Error {
    case invalidPositionInfo
    case invalidMessage
}

class APRSBeacon: APRSParser {

    var input: APRSParser
    var isRunning: Bool = false
    var delegate: InputDelegate?
    var plotter: APRSPlotter?
    
    init(withInput input: APRSParser) {
        self.input = input
        self.input.delegate = self
    }
    
    func start() -> Bool {
        return input.start()
    }
    
    func stop() {
        input.stop()
    }
    
    private func parse(frame: AX25Frame) {
        var position: CLLocationCoordinate2D
        var message: String
        
        switch frame.informationType {
        case "!", "=":
            do {
                try (position, message) = parsePositionWithoutTimestamp(info: frame.information)
            } catch {
                return
            }
        default:
            return
        }
        
        let aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position)
        plotter?.receiveBeacon(beacon: aprsResult)
        
        let aprsBeaconData = APRSBeaconData(data: aprsResult)
        delegate?.receivedData(data: aprsBeaconData)
    }
    
    private func parsePositionWithoutTimestamp(info: String) throws -> (CLLocationCoordinate2D, String) {
        // don't parse info that starts with "!!"
        if info[info.index(info.startIndex, offsetBy: 1)] == "!" { throw APRSBeaconParseError.invalidPositionInfo }
        if info[info.index(info.startIndex, offsetBy: 1)] == "/" { throw APRSBeaconParseError.invalidPositionInfo }
        
        // get the latitude degrees
        var start = info.startIndex
        var end = info.index(info.startIndex, offsetBy: 1)
        guard let latDegrees = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidPositionInfo }
        
        // get the latitude minutes
        start = info.index(info.startIndex, offsetBy: 2)
        end = info.index(info.startIndex, offsetBy: 6)
        guard let latMinutes = Double(String(info[start...end])) else { throw APRSBeaconParseError.invalidPositionInfo }
        
        // get the latitude direction, N or S
        let latDirection = String(info[info.index(info.startIndex, offsetBy: 7)])
        
        // get the longitude degrees
        start = info.index(info.startIndex, offsetBy: 9)
        end = info.index(info.startIndex, offsetBy: 11)
        guard let longDegrees = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidPositionInfo }
        
        // get the longitude minutes
        start = info.index(info.startIndex, offsetBy: 12)
        end = info.index(info.startIndex, offsetBy: 16)
        guard let longMinutes = Double(String(info[start...end])) else { throw APRSBeaconParseError.invalidPositionInfo }
        
        // get the longitude direction, E or W
        let longDirection = String(info[info.index(info.startIndex, offsetBy: 17)])
        
        // create the location coordinate
        var lat = Double(latDegrees) + (latMinutes / 60)
        if latDirection == "S" { lat = lat * -1.0 }
        var long = Double(longDegrees) + (longMinutes / 60)
        if longDirection == "W" { long = long * -1.0 }
        let position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        // get message
        start = info.index(info.startIndex, offsetBy: 19)
        end = info.index(info.endIndex, offsetBy: -1)
        let message = String(info[start...end])
        
        return (position, message)
    }
}

extension APRSBeacon: InputDelegate {
    
    func didConnect() {
        isRunning = true
        delegate?.didConnect()
    }
    
    func didDisconnect() {
        isRunning = false
        delegate?.didDisconnect()
    }
    
    func receivedData<T>(data: T) where T : APRSData {
        if let inputData = data.data as? AX25Frame {
            parse(frame: inputData)
        }
    }

}
