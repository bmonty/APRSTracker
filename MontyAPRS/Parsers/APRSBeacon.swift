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

    init(station: String, destination: String, digipeaters: [String]?, message: String?, position: CLLocationCoordinate2D, timestamp: Date) {
        self.station = station
        self.destination = destination
        self.digipeaters = digipeaters
        self.message = message
        self.position = position
        self.timeStamp = timestamp
    }

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
    case invalidPosition
    case invalidMessage
    case invalidTimestamp
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
        var aprsResult: APRSBeaconInfo

        switch frame.informationType {
        // position without timestamp, with or without messaging
        case "!", "=":
            do {
                let (position, message) =  try parsePositionWithoutTimestamp(frame.information)
                aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position)
            } catch {
                return
            }

        // position with timestamp, with or without messaging
        case "@", "/":
            do {
                let (timestamp, position, message) = try parsePositionWithTimestamp(frame.information)
                aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position, timestamp: timestamp)
            } catch {
                return
            }

        default:
            return
        }
        
        // send the parsed beacon to a plotter
        plotter?.receiveBeacon(beacon: aprsResult)
        
        let aprsBeaconData = APRSBeaconData(data: aprsResult)
        delegate?.receivedData(data: aprsBeaconData)
    }
    
    private func parsePositionWithoutTimestamp(_ info: String) throws -> (CLLocationCoordinate2D, String) {
        // don't parse info that starts with "!!"
        if info[info.index(info.startIndex, offsetBy: 1)] == "!" { throw APRSBeaconParseError.invalidPosition }
        if info[info.index(info.startIndex, offsetBy: 1)] == "/" { throw APRSBeaconParseError.invalidPosition }
        
        do {
            let (position, message) = try parsePositionAndMessage(info)
            return (position, message)
        } catch {
            throw error
        }
    }

    private func parsePositionWithTimestamp(_ info: String) throws -> (Date, CLLocationCoordinate2D, String) {
        // get first number
        var start = info.startIndex
        var end = info.index(info.startIndex, offsetBy: 1)
        guard let firstNum = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidTimestamp }

        // get second number
        start = info.index(info.startIndex, offsetBy: 2)
        end = info.index(info.startIndex, offsetBy: 3)
        guard let secondNum = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidTimestamp }

        // get third number
        start = info.index(info.startIndex, offsetBy: 4)
        end = info.index(info.startIndex, offsetBy: 5)
        guard let thirdNum = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidTimestamp }

        // get the timestamp format
        let format = String(info[info.index(info.startIndex, offsetBy: 6)])

        // get current system time info
        let currentDate = Date()
        let currentCalendar = Calendar.current

        var beaconDate: Date
        switch format {
        case "z": // timestamp with day/hour/minute in zulu
            var c = DateComponents()
            c.month = currentCalendar.component(.month, from: currentDate)
            c.year = currentCalendar.component(.year, from: currentDate)
            c.day = firstNum
            c.hour = secondNum
            c.minute = thirdNum
            c.timeZone = TimeZone(identifier: "UTC")
            if let tempDate = Calendar(identifier: Calendar.Identifier.gregorian).date(from: c) {
                beaconDate = tempDate
            } else {
                throw APRSBeaconParseError.invalidTimestamp
            }

        case "/": // timestamp with day/hour/minute in local time
            var c = DateComponents()
            c.month = currentCalendar.component(.month, from: currentDate)
            c.year = currentCalendar.component(.year, from: currentDate)
            c.day = firstNum
            c.hour = secondNum
            c.minute = thirdNum
            c.timeZone = TimeZone.current
            if let tempDate = Calendar(identifier: Calendar.Identifier.gregorian).date(from: c) {
                beaconDate = tempDate
            } else {
                throw APRSBeaconParseError.invalidTimestamp
            }

        case "h": // timestamp with hour/minute/second in zulu
            var c = DateComponents()
            c.month = currentCalendar.component(.month, from: currentDate)
            c.year = currentCalendar.component(.year, from: currentDate)
            c.day = currentCalendar.component(.day, from: currentDate)
            c.hour = firstNum
            c.minute = secondNum
            c.second = thirdNum
            c.timeZone = TimeZone(identifier: "UTC")
            if let tempDate = Calendar(identifier: Calendar.Identifier.gregorian).date(from: c) {
                beaconDate = tempDate
            } else {
                throw APRSBeaconParseError.invalidTimestamp
            }

        default:
            throw APRSBeaconParseError.invalidTimestamp
        }

        // parse position and message
        start = info.index(info.startIndex, offsetBy: 7)
        end = info.endIndex
        do {
            let (position, message) = try parsePositionAndMessage(String(info[start..<end]))
            return (beaconDate, position, message)
        } catch {
            throw error
        }
    }

    private func parsePositionAndMessage(_ info: String) throws -> (CLLocationCoordinate2D, String) {
        // get the latitude degrees
        var start = info.startIndex
        var end = info.index(info.startIndex, offsetBy: 1)
        guard let latDegrees = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidPosition }

        // get the latitude minutes
        start = info.index(info.startIndex, offsetBy: 2)
        end = info.index(info.startIndex, offsetBy: 6)
        guard let latMinutes = Double(String(info[start...end])) else { throw APRSBeaconParseError.invalidPosition }

        // get the latitude direction, N or S
        let latDirection = String(info[info.index(info.startIndex, offsetBy: 7)])

        // get the longitude degrees
        start = info.index(info.startIndex, offsetBy: 9)
        end = info.index(info.startIndex, offsetBy: 11)
        guard let longDegrees = Int(String(info[start...end])) else { throw APRSBeaconParseError.invalidPosition }

        // get the longitude minutes
        start = info.index(info.startIndex, offsetBy: 12)
        end = info.index(info.startIndex, offsetBy: 16)
        guard let longMinutes = Double(String(info[start...end])) else { throw APRSBeaconParseError.invalidPosition }

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
