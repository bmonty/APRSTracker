//
//  APRS.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/25/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import MapKit

let micEDestAddressEncoding: [String: (Int, Int, String, Int, String)] =
    ["0": (0, 0, "S", 0, "E"), "1": (1, 0, "S", 0, "E"), "2": (2, 0, "S", 0, "E"),
     "3": (3, 0, "S", 0, "E"), "4": (4, 0, "S", 0, "E"), "5": (5, 0, "S", 0, "E"),
     "6": (6, 0, "S", 0, "E"), "7": (7, 0, "S", 0, "E"), "8": (8, 0, "S", 0, "E"),
     "9": (9, 0, "S", 0, "E"), "A": (0, 1, " ", 0, " "), "B": (1, 1, " ", 0, " "),
     "C": (2, 1, " ", 0, " "), "D": (3, 1, " ", 0, " "), "E": (4, 1, " ", 0, " "),
     "F": (5, 1, " ", 0, " "), "G": (6, 1, " ", 0, " "), "H": (7, 1, " ", 0, " "),
     "I": (8, 1, " ", 0, " "), "J": (9, 1, " ", 0, " "), /*"K": " ", "L": " ",*/
     "P": (0, 1, "N", 100, "W"), "Q": (1, 1, "N", 100, "W"),
     "R": (2, 1, "N", 100, "W"), "S": (3, 1, "N", 100, "W"),
     "T": (4, 1, "N", 100, "W"), "U": (5, 1, "N", 100, "W"),
     "V": (6, 1, "N", 100, "W"), "W": (7, 1, "N", 100, "W"),
     "X": (8, 1, "N", 100, "W"), "Y": (9, 1, "N", 100, "W"), /*"Z": " "*/]

let micEmessageType: [String: String] = [
    "111": "Off Duty",
    "110": "En Route",
    "101": "In Service",
    "100": "Returning",
    "011": "Committed",
    "010": "Special",
    "001": "Priority",
    "000": "Emergency"
]

enum micEAPRSDataType {
    case currentData
    case oldData
    case unknown
}

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
    var speed: Int?
    var course: Int?
    var symbol: String?
    var aprsDataType: micEAPRSDataType?

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
    case invalidDataCast
}

class APRSBeacon {

    var delegate: APRSParser?

    private func parse(frame: AX25Frame) {
        var aprsResult: APRSBeaconInfo

        switch frame.informationType {
        // position without timestamp, with or without messaging
        case "!", "=":
            do {
                let (position, message, symbol) =  try parsePositionWithoutTimestamp(frame.information)
                aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position)
                aprsResult.symbol = symbol
            } catch {
                return
            }

        // position with timestamp, with or without messaging
        case "@", "/":
            do {
                let (timestamp, position, message, symbol) = try parsePositionWithTimestamp(frame.information)
                aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position, timestamp: timestamp)
                aprsResult.symbol = symbol
            } catch {
                return
            }

        // Mic-E
        case "'", "`":
             //let type where UInt8(type) == 0x1C,
             //let type where UInt8(type) == 0x1D:
            do {
                let data = try parseMicE(withDestination: frame.destination, withInfoType: frame.informationType, withInfo: frame.information)

                guard let position = data["position"] as? CLLocationCoordinate2D else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                guard let message = data["message"] as? String else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                guard let speed = data["speed"] as? Int else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                guard let course = data["course"] as? Int else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                guard let aprsDataType = data["aprs_data_type"] as? micEAPRSDataType else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                guard let symbol = data["symbol"] as? String else {
                    throw APRSBeaconParseError.invalidDataCast
                }

                aprsResult = APRSBeaconInfo(station: frame.source, destination: frame.destination, digipeaters: frame.digipeaters, message: message, position: position)
                aprsResult.symbol = symbol
                aprsResult.speed = speed
                aprsResult.course = course
                aprsResult.aprsDataType = aprsDataType
            } catch {
                return
            }

        default:
            return
        }

        let aprsBeaconData = APRSBeaconData(data: aprsResult)
        delegate?.receivedData(data: aprsBeaconData)
    }
    
    private func parsePositionWithoutTimestamp(_ info: String) throws -> (CLLocationCoordinate2D, String, String) {
        // don't parse info that starts with "!!"
        if info[info.index(info.startIndex, offsetBy: 1)] == "!" { throw APRSBeaconParseError.invalidPosition }

        // if the position info starts with "/", it's a compressed report
        if info[info.startIndex] == "/" {
            do {
                let (position, message, symbol) = try parseCompressedPositionAndMessage(info)
                return (position, message, symbol)
            } catch {
                throw error
            }
        }

        // parse as an uncompressed report
        do {
            let (position, message, symbol) = try parsePositionAndMessage(info)
            return (position, message, symbol)
        } catch {
            throw error
        }
    }

    private func parsePositionWithTimestamp(_ info: String) throws -> (Date, CLLocationCoordinate2D, String, String) {
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
            let (position, message, symbol) = try parsePositionAndMessage(String(info[start..<end]))
            return (beaconDate, position, message, symbol)
        } catch {
            throw error
        }
    }

    private func parsePositionAndMessage(_ info: String) throws -> (CLLocationCoordinate2D, String, String) {
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

        // get the symbol table
        let symbolTable = String(info[info.index(info.startIndex, offsetBy: 8)])

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

        // get the symbol code
        let symbolCode = String(info[info.index(info.startIndex, offsetBy: 18)])

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

        let symbol = symbolTable + symbolCode

        return (position, message, symbol)
    }

    private func parseCompressedPositionAndMessage(_ info: String) throws -> (CLLocationCoordinate2D, String, String) {
        let symbolTable = String(info[info.startIndex])

        // decode latitude
        var start = info.index(info.startIndex, offsetBy: 1)
        var end = info.index(info.startIndex, offsetBy: 4)
        let latBytes = String(info[start...end]).utf8.map{ UInt8($0) }
        var sum: Decimal = 0
        for i in 0...3 {
            sum += (Decimal(latBytes[i]) - 33) * pow(91, 3 - i)
        }
        let lat = Double(truncating: (90 - sum / 380926) as NSNumber)

        // decode longitude
        start = info.index(info.startIndex, offsetBy: 5)
        end = info.index(info.startIndex, offsetBy: 8)
        let longBytes = String(info[start...end]).utf8.map{ UInt8($0) }
        var longSum: Decimal = 0
        for i in 0...3 {
            longSum += (Decimal(longBytes[i]) - 33) * pow(91, 3 - i)
        }
        let long = Double(truncating: (-180 + longSum / 190463) as NSNumber)

        // get lat/long to 2 decimal places
        let finalLat = Double(String(format: "%.2f", lat))!
        let finalLong = Double(String(format: "%.2f", long))!

        let position = CLLocationCoordinate2D(latitude: finalLat, longitude: finalLong)

        let symbolCode = String(info[info.index(info.startIndex, offsetBy: 9)])

        let symbol = symbolTable + symbolCode

        // get message
        start = info.index(info.startIndex, offsetBy: 13)
        end = info.index(info.endIndex, offsetBy: -1)
        let message = String(info[start...end])

        return (position, message, symbol)
    }

    private func parseMicE(withDestination destination: String, withInfoType infoType: String, withInfo info: String) throws -> Dictionary<String, Any> {
        var data: [String: Any] = [:]

        // decode latitude
        var destLatDigitDecode = [Int]()
        for i in 0...5 {
            let sub = String(destination[destination.index(destination.startIndex, offsetBy: i)])
            guard let num = micEDestAddressEncoding[sub]?.0 else { throw APRSBeaconParseError.invalidPosition }
            destLatDigitDecode.append(num)
        }

        let latDegree: Int = (destLatDigitDecode[0] * 10) + destLatDigitDecode[1]
        let latMinute: Double = (Double(String("\(destLatDigitDecode[2])\(destLatDigitDecode[3]).\(destLatDigitDecode[4])\(destLatDigitDecode[5])")))!
        let latDirection = (micEDestAddressEncoding[String(destination[destination.index(destination.startIndex, offsetBy: 3)])]?.2)!
        var latitude = Double(latDegree) + (latMinute / 60)
        if latDirection == "S" {
            latitude = -latitude
        }
        latitude = roundToPlaces(latitude, toDecimalPlaces: 4)

        // decode longitude offset
        let longitudeOffset = (micEDestAddressEncoding[String(destination[destination.index(destination.startIndex, offsetBy: 4)])]?.3)!

        // decode longitude direction (East or West)
        let longDirection = (micEDestAddressEncoding[String(destination[destination.index(destination.startIndex, offsetBy: 3)])]?.4)!

        // decode longitude degree value
        var s = info[info.startIndex].unicodeScalars
        var longitudeDecimal = Int(s[s.startIndex].value) - 28
        if longitudeOffset > 0 {
            longitudeDecimal += longitudeOffset
        }

        // decode longitude minute value
        s = info[info.index(info.startIndex, offsetBy: 1)].unicodeScalars
        var longitudeMinuteInt = Int(s[s.startIndex].value) - 28
        if longitudeMinuteInt >= 60 {
            longitudeMinuteInt -= 60
        }

        // decode the longitude hundreths of a minute value
        s = info[info.index(info.startIndex, offsetBy: 2)].unicodeScalars
        let longitudeHundrethMinute = Double((Int(s[s.startIndex].value) - 28)) / 100

        var longitude = Double(longitudeDecimal) + ((Double(longitudeMinuteInt) + longitudeHundrethMinute) / 60)
        if longDirection == "W" {
            longitude = -longitude
        }
        longitude = roundToPlaces(longitude, toDecimalPlaces: 4)

        // create the position object
        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        data["position"] = position

        // decode message type
        var messageType: String = ""
        for i in 0...2 {
            let sub = String(destination[destination.index(destination.startIndex, offsetBy: i)])
            let digit = (micEDestAddressEncoding[sub]?.1)!
            messageType.append(String(digit))
        }
        data["message_type"] = micEmessageType[messageType]

        // decode speed
        s = info[info.index(info.startIndex, offsetBy: 3)].unicodeScalars
        var speedTen = Int(s[s.startIndex].value) - 28
        if speedTen >= 80 {
            speedTen -= 80
        }
        speedTen *= 10

        // decode course
        s = info[info.index(info.startIndex, offsetBy: 4)].unicodeScalars
        let dcByte = Int(s[s.startIndex].value) - 28
        let speedOnes = dcByte / 10

        data["speed"] = speedTen + speedOnes

        let courseHundreds = ((dcByte % 10) - 4) * 100

        s = info[info.index(info.startIndex, offsetBy: 5)].unicodeScalars
        let courseOnes = Int(s[s.startIndex].value) - 28

        data["course"] = courseHundreds + courseOnes

        // get symbol info
        var symbol = ""
        for i in 6...7 {
            let sym = String(info[info.index(info.startIndex, offsetBy: i)])
            symbol.append(sym)
        }
        data["symbol"] = symbol

        // get APRS data type identifier
        switch infoType {
        case "`":
            data["aprs_data_type"] = micEAPRSDataType.currentData
        case "'":
            data["aprs_data_type"] = micEAPRSDataType.oldData
        default:
            data["aprs_data_type"] = micEAPRSDataType.unknown
        }

        // TODO: add telemetry decoding, byte 9 is the telemetry flag

        // get message
        data["message"] = String(info[info.index(info.startIndex, offsetBy: 8)...])

        return data
    }

    private func roundToPlaces(_ value: Double, toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }
}

extension APRSBeacon: APRSParser {

    func receivedData<T>(data: T) where T : APRSData {
        if let inputData = data.data as? AX25Frame {
            parse(frame: inputData)
        }
    }

}
