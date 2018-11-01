//
//  APRSBeaconTests.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/30/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import XCTest
import MapKit
@testable import MontyAPRS

class APRSBeaconTests: XCTestCase {

    class APRSParserMock: APRSParser {

        var delegate: InputDelegate?

        func start() -> Bool {
            return true
        }

        func stop() {
            return
        }

    }

    class APRSPlotterMock: APRSPlotter {

        var didReceiveBeaconClosure: ((APRSBeaconInfo) -> Void)?

        func receiveBeacon(beacon: APRSBeaconInfo) {
            didReceiveBeaconClosure?(beacon)
        }
        
    }

    var testBeacon: APRSBeacon!
    var parserTester: APRSParserMock!

    override func setUp() {
        super.setUp()

        parserTester = APRSParserMock()
        testBeacon = APRSBeacon(withInput: parserTester)
    }

    override func tearDown() {
        testBeacon = nil

        super.tearDown()
    }

    func testParseOfPositionWithoutTimestamp() {
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "TEST", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "!", information: "4903.50N/07201.75W-This is a test.")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A beacon with position is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "This is a test.")

            // check position info
            XCTAssertEqual(beacon.position.latitude, 49.05833333333333)
            XCTAssertEqual(beacon.position.longitude, -72.02916666666667)

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }

    func testParseOfPositionWithTimestampInZulu() {
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "TEST", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "@", information: "092345z4903.50N/07201.75W-This is a test.")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A beacon with position and timestamp in Zulu is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "This is a test.")

            // check the timestamp info
            let calendar = Calendar.current
            let beaconDateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: beacon.timeStamp)
            XCTAssertEqual(beaconDateComponents.day, 9)
            XCTAssertEqual(beaconDateComponents.hour, 23)
            XCTAssertEqual(beaconDateComponents.minute, 45)
            XCTAssertEqual(beaconDateComponents.timeZone, TimeZone(identifier: "UTC"))

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }

    func testParseOfPositionWithTimestampInLocal() {
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "TEST", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "@", information: "092345/4903.50N/07201.75W-This is a test.")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A beacon with position and timestamp in the local time zone is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "This is a test.")

            // check the timestamp info
            let calendar = Calendar.current
            let beaconDateComponents = calendar.dateComponents(in: TimeZone.current, from: beacon.timeStamp)
            XCTAssertEqual(beaconDateComponents.day, 9)
            XCTAssertEqual(beaconDateComponents.hour, 23)
            XCTAssertEqual(beaconDateComponents.minute, 45)
            XCTAssertEqual(beaconDateComponents.timeZone, TimeZone.current)

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }

    func testParseOfPositionWithTimestampInHours() {
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "TEST", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "@", information: "234517h4903.50N/07201.75W-This is a test.")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A beacon with position and timestamp in hours/minutes/seconds is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "This is a test.")

            // check the timestamp info
            let calendar = Calendar.current
            let beaconDateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: beacon.timeStamp)
            XCTAssertEqual(beaconDateComponents.hour, 23)
            XCTAssertEqual(beaconDateComponents.minute, 45)
            XCTAssertEqual(beaconDateComponents.second, 17)
            XCTAssertEqual(beaconDateComponents.timeZone, TimeZone(identifier: "UTC"))

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }

    func testParseOfCompressedPositionWithoutTimestamp() {
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "TEST", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "!", information: "/?VJo5Qz1$csTThis is a test.")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A beacon with compressed position is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "This is a test.")

            // check position info
            XCTAssertEqual(beacon.position.latitude, 29.49)
            XCTAssertEqual(beacon.position.longitude, -98.74)

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }

    func testParseOfMicE() {
        /* N5NTG-4>2Y3S4V,WA5LNL-3,WIDE1*,WIDE2-1:`~9'mJD>/'SAHams.org|3
        MIC-E, normal car (side view), Byonics TinyTrack3, Special
        N 29 33.4600, W 098 29.1100, 16 MPH, course 240
        SAHams.org */
        let testFrame = AX25Frame(source: "KG5YOV-9", destination: "2Y3S4V", digipeaters: ["WIDE1-1", "WIDE1-2"], informationType: "`", information: "~9'mJD>/'SAHams.org|3")
        let testData = AX25Data(data: testFrame)

        let beaconExpectation = expectation(description: "A Mic-E beacon is parsed correctly.")

        let consumer = APRSPlotterMock()
        testBeacon.plotter = consumer

        consumer.didReceiveBeaconClosure = { beacon in
            // check basic beacon info
            XCTAssertEqual(beacon.station, testFrame.source)
            XCTAssertEqual(beacon.destination, testFrame.destination)
            XCTAssertEqual(beacon.message, "'SAHams.org|3")

            // check position info
            XCTAssertEqual(beacon.position.latitude, 29.5577)
            XCTAssertEqual(beacon.position.longitude, -98.4852)

            // check speed and course
            XCTAssertEqual(beacon.speed, 14)
            XCTAssertEqual(beacon.course, 240)

            XCTAssertEqual(beacon.symbol, ">/")
            XCTAssertEqual(beacon.aprsDataType, micEAPRSDataType.currentData)

            beaconExpectation.fulfill()
        }

        testBeacon.receivedData(data: testData)

        waitForExpectations(timeout: 1.0)
    }
}
