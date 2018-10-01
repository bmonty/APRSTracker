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

class ParserMock: APRSParser {

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

class APRSBeaconTests: XCTestCase {

    var testBeacon: APRSBeacon!
    var parserTester: ParserMock!

    override func setUp() {
        parserTester = ParserMock()
        testBeacon = APRSBeacon(withInput: parserTester)

        super.setUp()
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
}
