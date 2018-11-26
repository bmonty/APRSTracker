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

    override func tearDown() {
        super.tearDown()

        // clear out the beacons between tests
        AprsBeaconStore.shared.beacons = [:]
    }

    func testAddNewStation() {
        let _ = expectation(forNotification: .didReceiveBeacon, object: nil, handler: { (notification) -> Bool in
            if let userInfo = notification.userInfo as? [String: String] {
                guard let station = userInfo["station"] else {
                    return false
                }
                XCTAssertEqual(station, "KG5YOV-9")

                guard let beacons = AprsBeaconStore.shared.getBeacons(forStation: station) else {
                    return false
                }

                XCTAssertEqual(beacons.count, 1)
                XCTAssertEqual(AprsBeaconStore.shared.stationCount, 1)

                XCTAssertEqual(beacons[0].station, "KG5YOV-9")
                XCTAssertEqual(beacons[0].destination, "TEST")
                XCTAssertEqual(beacons[0].message, "This is a first test.")

                return true
            }

            return false
        })

        AprsBeaconStore.shared.receiveBeacon(beacon: testBeacon1)

        waitForExpectations(timeout: 1.0)
    }

    func testUpdateStation() {
        AprsBeaconStore.shared.beacons["KG5YOV-9"] = [testBeacon1]
        let _ = expectation(forNotification: .didReceiveBeacon, object: nil, handler: { (notification) -> Bool in
            if let userInfo = notification.userInfo as? [String: String] {
                guard let station = userInfo["station"] else {
                    return false
                }
                XCTAssertEqual(station, "KG5YOV-9")

                guard let beacons = AprsBeaconStore.shared.getBeacons(forStation: station) else {
                    return false
                }

                XCTAssertEqual(beacons.count, 2)
                XCTAssertEqual(AprsBeaconStore.shared.stationCount, 1)

                XCTAssertEqual(beacons[1].station, "KG5YOV-9")
                XCTAssertEqual(beacons[1].destination, "TEST")
                XCTAssertEqual(beacons[1].message, "This is a second test.")

                return true
            }

            return false
        })

        AprsBeaconStore.shared.receiveBeacon(beacon: testBeacon2)

        waitForExpectations(timeout: 1.0)
    }

    func testAddSecondStation() {
        let _ = expectation(forNotification: .didReceiveBeacon, object: nil, handler: { (notification) -> Bool in
            if let userInfo = notification.userInfo as? [String: String] {
                guard let station = userInfo["station"] else {
                    return false
                }
                XCTAssertEqual(station, "KG5YOV-9")

                guard let beacons = AprsBeaconStore.shared.getBeacons(forStation: station) else {
                    return false
                }

                XCTAssertEqual(beacons.count, 1)
                XCTAssertEqual(beacons[0].station, "KG5YOV-9")
                XCTAssertEqual(beacons[0].destination, "TEST")
                XCTAssertEqual(beacons[0].message, "This is a first test.")

                return true
            }

            return false
        })
        AprsBeaconStore.shared.receiveBeacon(beacon: testBeacon1)
        waitForExpectations(timeout: 1.0)

        let _ = expectation(forNotification: .didReceiveBeacon, object: nil, handler: { (notification) -> Bool in
            if let userInfo = notification.userInfo as? [String: String] {
                guard let station = userInfo["station"] else {
                    return false
                }
                XCTAssertEqual(station, "W5CAA-9")

                guard let beacons = AprsBeaconStore.shared.getBeacons(forStation: station) else {
                    return false
                }

                XCTAssertEqual(beacons.count, 1)
                XCTAssertEqual(beacons[0].station, "W5CAA-9")
                XCTAssertEqual(beacons[0].destination, "TEST")
                XCTAssertEqual(beacons[0].message, "This is a third test.")

                return true
            }

            return false
        })
        AprsBeaconStore.shared.receiveBeacon(beacon: testBeacon3)
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(AprsBeaconStore.shared.stationCount, 2)
    }

}
