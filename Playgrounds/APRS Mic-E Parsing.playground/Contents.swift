import Foundation
import MapKit

enum PlaygroundError: Error {
    case invalidDestination
}

enum MicEDestinationEncoding {
    case latDigit
    case messageABC
    case northSouth
    case longOffset
    case eastWest
}

var latDigits: [String: (Int, Int, String, Int, String)] =
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

let ax25MinAddresses: Int = 2
let ax25MaxAddresses: Int = 10
let ssidLastMask: UInt8 = 0x01
let ssidSsidMask: UInt8 = 0x1E
let ssidSsidShift: Int = 1

//Digipeater WIDE2 (probably WX5II-3) audio level = 10(5/4)   [NONE]   _||||||:_
//[0.4] WD5KAL-9>SQ2U9X,W5BEC-5,AUSWST,WX5II-3,WIDE2*:'}(#l!Jv/]"5n}wd5kal@aol.com<0x0d>MIC-E, VAN, Kenwood TM-D700, En Route
//N 31 25.9800, W 097 12.0700, 0 MPH, course 146, alt 584 ft
//wd5kal@aol.com

var frame: Data = Data(bytes: [0xa6, 0xa2, 0x64, 0xaa, 0x72, 0xb0,
                              0x60, 0xae, 0x88, 0x6a, 0x96, 0x82, 0x98, 0xf2,
                              0xae, 0x6a, 0x84, 0x8a, 0x86, 0x40, 0xea, 0x82,
                              0xaa, 0xa6, 0xae, 0xa6, 0xa8, 0xe0, 0xae, 0xb0,
                              0x6a, 0x92, 0x92, 0x40, 0xe6, 0xae, 0x92, 0x88,
                              0x8a, 0x64, 0x40, 0xe1, 0x03, 0xf0, 0x27, 0x7d,
                              0x28, 0x23, 0x6c, 0x21, 0x4a, 0x76, 0x2f, 0x5d,
                              0x22, 0x35, 0x6e, 0x7d, 0x77, 0x64, 0x35, 0x6b,
                              0x61, 0x6c, 0x40, 0x61, 0x6f, 0x6c, 0x2e, 0x63,
                              0x6f, 0x6d, 0x0d])
print("Raw frame: \(String(bytes: frame, encoding: .ascii)!)")

// get destination address field from AX.25 frame
var destination = String()
var ssid: UInt8 = 0
var isGenericDigipeaterPath = false
for byte in frame.startIndex..<frame.startIndex + 6 {
    let char = frame[byte] >> 1 & 0x7F
    if char == 0x20 { break }
    guard let destinationTemp = String(bytes: [char], encoding: .ascii) else { throw PlaygroundError.invalidDestination }
    destination.append(destinationTemp)
}
print("Destination address is \(destination)")

// decode latitude degrees
var destLatDigitDecode = [Int]()
for i in 0...5 {
    let sub = String(destination[destination.index(destination.startIndex, offsetBy: i)])
    guard let num = latDigits[sub]?.0 else { throw PlaygroundError.invalidDestination }
    destLatDigitDecode.append(num)
}

let latDegree: Int = (destLatDigitDecode[0] * 10) + destLatDigitDecode[1]
let latMinute: Double = (Double(String("\(destLatDigitDecode[2])\(destLatDigitDecode[3]).\(destLatDigitDecode[4])\(destLatDigitDecode[5])")))!

// decode latitude direction (North or South)
let latDirection = (latDigits[String(destination[destination.index(destination.startIndex, offsetBy: 3)])]?.2)!

print("Latitude is \(latDirection) \(latDegree) \(latMinute)")

// decode message type
var messageType: String = ""
for i in 0...2 {
    let sub = String(destination[destination.index(destination.startIndex, offsetBy: i)])
    let digit = (latDigits[sub]?.1)!
    messageType.append(String(digit))
}
print("Message type is \"\(micEmessageType[messageType]!)\"")

// decode longitude offset
var longitudeOffset = (latDigits[String(destination[destination.index(destination.startIndex, offsetBy: 4)])]?.3)!
print("Longitude offset is \(longitudeOffset)")

// decode longitude direction (East or West)
let longDirection = (latDigits[String(destination[destination.index(destination.startIndex, offsetBy: 3)])]?.4)!

// get information field
let info: String = "'}(#l!Jv/]\"5n}wd5kal@aol.com"

// get APRS data type identifier
var micEDataType = info[info.index(info.startIndex, offsetBy: 0)]
switch micEDataType {
case "`":
    print("Data Type: Current GPS Data")
case "'":
    print("Data Type: Old GPS Data")
default:
    print("Couldn't get Mic-E Data Type.")
}

// decode longitude decimal value
var s = info[info.index(info.startIndex, offsetBy: 1)].unicodeScalars
var longitudeDecimal = Int(s[s.startIndex].value) - 28
if longitudeOffset > 0 {
    longitudeDecimal += longitudeOffset
}

// decode longitude minute value
s = info[info.index(info.startIndex, offsetBy: 2)].unicodeScalars
var longitudeMinuteInt = Int(s[s.startIndex].value) - 28
if longitudeMinuteInt >= 60 {
    longitudeMinuteInt -= 60
}

// decode the longitude hundreths of a minute value
s = info[info.index(info.startIndex, offsetBy: 3)].unicodeScalars
var longitudeHundrethMinute = Double((Int(s[s.startIndex].value) - 28)) / 100

let longitudeMinute = Double(longitudeMinuteInt) + longitudeHundrethMinute

print("Longitude is \(longDirection) \(longitudeDecimal) \(longitudeMinute)")

// decode speed
s = info[info.index(info.startIndex, offsetBy: 4)].unicodeScalars
var speedTen = Int(s[s.startIndex].value) - 28
if speedTen >= 80 {
    speedTen -= 80
}
speedTen *= 10

// decode course
s = info[info.index(info.startIndex, offsetBy: 5)].unicodeScalars
var dcByte = Int(s[s.startIndex].value) - 28

var speedOnes = dcByte / 10

print("Speed: \(speedTen + speedOnes) MPH")

var courseHundreds = ((dcByte % 10) - 4) * 100

s = info[info.index(info.startIndex, offsetBy: 6)].unicodeScalars
var courseOnes = Int(s[s.startIndex].value) - 28

print("Course: \(courseHundreds + courseOnes)")

// get symbol info
var symbol = ""
for i in 7...8 {
    let sym = String(info[info.index(info.startIndex, offsetBy: i)])
    symbol.append(sym)
}
print("Symbol: \(symbol)")
