//
//  AprsPlotter.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/4/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

class AprsBeaconStore {

    // MARK: - Properties
    static let shared = AprsBeaconStore()

    // MARK: -
    var beacons: [String: [APRSBeaconInfo]]
    private let concurrentBeaconQueue = DispatchQueue(label: "org.montynet.MontyAPRS.beaconQueue",
                                                      attributes: .concurrent)
    var delegate: AprsBeaconStoreDelegate?

    private init() {
        beacons = [:]
    }

    var count: Int {
        get {
            return beacons.count
        }
    }

    func postBeaconUpdateNotification(_ station: String) {
        delegate?.beaconsDidUpdate(withStation: station)
    }

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

private extension AprsBeaconStore {

    func addNewStation(_ beacon: APRSBeaconInfo) {
        concurrentBeaconQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            var beaconArray = [APRSBeaconInfo]()
            beaconArray.append(beacon)
            self.beacons[beacon.station] = beaconArray

            DispatchQueue.main.async { [weak self] in
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

            DispatchQueue.main.async { [weak self] in
                self?.postBeaconUpdateNotification(beacon.station)
            }
        }
    }

}
