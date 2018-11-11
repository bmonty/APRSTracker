//
//  AprsBeaconStoreTests.swift
//  MontyAPRSTests
//
//  Created by Benjamin Montgomery on 11/8/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import XCTest
import MapKit
@testable import MontyAPRS

class AprsBeaconStoreTests: XCTestCase {

    let testBeacon1 = APRSBeaconInfo(station: "KG5YOV-9", destination: "TEST",
                                    digipeaters: ["WIDE1-1", "WIDE2-1"],
                                    message: "This is a first test.",
                                    position: CLLocationCoordinate2D(latitude: 90, longitude: -30))

    let testBeacon2 = APRSBeaconInfo(station: "KG5YOV-9", destination: "TEST",
                                     digipeaters: ["WIDE1-1", "WIDE2-1"],
                                     message: "This is a second test.",
                                     position: CLLocationCoordinate2D(latitude: 90, longitude: -31))

    let testBeacon3 = APRSBeaconInfo(station: "W5CAA-9", destination: "TEST",
                                     digipeaters: ["WIDE1-1", "WIDE2-1"],
                                     message: "This is a third test.",
                                     position: CLLocationCoordinate2D(latitude: 90, longitude: -32))

    class AprsPlotterDelegateMock: AprsBeaconStoreDelegate {

        var didReceiveBeaconUpdateClosure: ((String) -> Void)?

        func beaconsDidUpdate(withStation station: String) {
            didReceiveBeaconUpdateClosure?(station)
        }

    }

    override func tearDown() {
        super.tearDown()

        // clear out the beacons between tests
        AprsBeaconStore.shared.beacons = [:]
    }

    func testAddNewStation() {
        let beaconStore = AprsBeaconStore.shared

        let plotterExpectation = expectation(description: "A new beacon is added.")
        let consumer = AprsPlotterDelegateMock()
        beaconStore.delegate = consumer

        consumer.didReceiveBeaconUpdateClosure = { station in
            XCTAssertEqual(beaconStore.beacons.count, 1)
            XCTAssertNotNil(beaconStore.beacons[station])
            XCTAssertEqual(beaconStore.count, 1)

            plotterExpectation.fulfill()
        }


        beaconStore.receiveBeacon(beacon: testBeacon1)

        waitForExpectations(timeout: 1.0)
    }

    func testUpdateStation() {
        let beaconStore = AprsBeaconStore.shared
        beaconStore.beacons["KG5YOV-9"] = [testBeacon1]

        let plotterExpectation = expectation(description: "A beacon is updated.")
        let consumer = AprsPlotterDelegateMock()
        beaconStore.delegate = consumer

        consumer.didReceiveBeaconUpdateClosure = { station in
            XCTAssertEqual(beaconStore.beacons.count, 1)
            XCTAssertNotNil(beaconStore.beacons[station])
            XCTAssertEqual(beaconStore.count, 1)

            plotterExpectation.fulfill()
        }

        beaconStore.receiveBeacon(beacon: testBeacon2)

        waitForExpectations(timeout: 1.0)
    }

    func testAddSecondStation() {
        let beaconStore = AprsBeaconStore.shared

        var testExpectation = expectation(description: "Add first beacon.")
        beaconStore.receiveBeacon(beacon: testBeacon1)
        let firstBeacon = AprsPlotterDelegateMock()
        firstBeacon.didReceiveBeaconUpdateClosure = { station in
            testExpectation.fulfill()
        }
        beaconStore.delegate = firstBeacon
        waitForExpectations(timeout: 1.0)

        testExpectation = expectation(description: "Add second beacon.")
        let secondBeacon = AprsPlotterDelegateMock()
        secondBeacon.didReceiveBeaconUpdateClosure = { station in
            testExpectation.fulfill()
        }
        beaconStore.receiveBeacon(beacon: testBeacon3)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(beaconStore.count, 2)
    }
}
