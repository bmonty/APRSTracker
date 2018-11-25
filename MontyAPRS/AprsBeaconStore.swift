//
//  AprsPlotter.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/4/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

/**
 * Singleton class to store all beacons recieved by the app.
 */
class AprsBeaconStore {

    // MARK: - Static Properties
    /// Singleton for access to `AprsBeaconStore` data.
    static let shared = AprsBeaconStore()

    // MARK: - Properties

    /// Dictionary of beacons with the station as the key.
    var beacons: [String: [APRSBeaconInfo]]

    /// Returns the count of stations received.
    var stationCount: Int {
        get {
            return beacons.count
        }
    }

    // `DispatchQueue` used to control updates to `beacons`.
    private let concurrentBeaconQueue = DispatchQueue(label: "org.montynet.MontyAPRS.beaconQueue",
                                                      attributes: .concurrent)

    /**
     This is a singleton class.  Use `AprsBeaconStore.shared`.
     */
    private init() {
        beacons = [:]
    }

    /**
     Get the `APRSBeaconInfo` array for a station.

     - Parameters:
        - forStation: get beacons for this station callsign

     - Returns: The `APRSBeaconInfo` array for the station or `nil` if the
                station hasn't been heard.
     */
    func getBeacons(forStation station: String) -> [APRSBeaconInfo]? {
        guard let beacons: [APRSBeaconInfo] = AprsBeaconStore.shared.beacons[station] else {
            return nil
        }
        return beacons
    }

    private func addNewStation(_ beacon: APRSBeaconInfo) {
        concurrentBeaconQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            if self.isDuplicateBeacon(forBeacon: beacon) {
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

    private func updateStation(_ beacon: APRSBeaconInfo) {
        concurrentBeaconQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            if self.isDuplicateBeacon(forBeacon: beacon) {
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

    private func postBeaconUpdateNotification(_ station: String) {
        let infoDict: [String: String] = ["station": station]
        NotificationCenter.default.post(name: .didReceiveBeacon, object: nil, userInfo: infoDict)
    }

    /**
     Checks if `beacon` is a duplicate.

     - Parameters:
        - forBeacon: the beacon to check

     - Returns:
        - `true` if the beacon is a duplicate, `false` otherwise
     */
    func isDuplicateBeacon(forBeacon beacon: APRSBeaconInfo) -> Bool {
        guard let stationBeacons = beacons[beacon.station] else {
            return false
        }

        guard let lastBeacon = stationBeacons.last else {
            return false
        }

        return beacon == lastBeacon
    }

}

// MARK: - Notification.Name
extension Notification.Name {
    /// Name of the notification sent when new beacons are received.
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
