//
//  AprsPlotter.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/4/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

class AprsBeaconStore {

    // MARK: - Static Properties
    static let shared = AprsBeaconStore()

    // MARK: - Properties
    var beacons: [String: [APRSBeaconInfo]]
    var count: Int {
        get {
            return beacons.count
        }
    }
    private let concurrentBeaconQueue = DispatchQueue(label: "org.montynet.MontyAPRS.beaconQueue",
                                                      attributes: .concurrent)

    // MARK: -
    private init() {
        beacons = [:]
    }

    func postBeaconUpdateNotification(_ station: String) {
        let infoDict: [String: String] = ["station": station]
        NotificationCenter.default.post(name: .didReceiveBeacon, object: nil, userInfo: infoDict)
    }

}

// MARK: - Notification.Name
extension Notification.Name {
    static let didReceiveBeacon = Notification.Name(rawValue: "org.montynet.didReceiveData")
}

// MARK: - AprsBeaconHandler
extension AprsBeaconStore: AprsBeaconHandler {

    func receiveBeacon(beacon: APRSBeaconInfo) {
        if let _ = beacons[beacon.station] {
            updateStation(beacon)
        } else {
            addNewStation(beacon)
        }
    }

}

// MARK: - AprsBeaconStore
private extension AprsBeaconStore {

    func addNewStation(_ beacon: APRSBeaconInfo) {
        concurrentBeaconQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            var beaconArray = [APRSBeaconInfo]()
            beaconArray.append(beacon)
            self.beacons[beacon.station] = beaconArray

            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.postBeaconUpdateNotification(beacon.station)
            }
        }
    }

    func updateStation(_ beacon: APRSBeaconInfo) {
        concurrentBeaconQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            guard var beaconArray = self.beacons[beacon.station] else {
                return
            }
            beaconArray.append(beacon)

            self.beacons.updateValue(beaconArray, forKey: beacon.station)

            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.postBeaconUpdateNotification(beacon.station)
            }
        }
    }

}
