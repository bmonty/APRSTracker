//
//  AprsManager.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/11/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import Cocoa

class AprsManager {

    let kiss: KISS
    let ax25: AX25
    let aprsBeacon: APRSBeacon

    init() {
        // setup APRS protocol stack
        kiss = KISS(hostname: "aprs.montynet.org", port: 8001)
        ax25 = AX25()
        aprsBeacon = APRSBeacon()

        // connect delegates
        kiss.delegate = ax25
        ax25.delegate = aprsBeacon
    }

    func start() {
        if !kiss.start() {
            let alert = NSAlert()
            alert.messageText = "Unable to connect to TNC."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func stop() {
        kiss.stop()
    }

}

extension AprsManager: APRSParser {

    func receivedData<T>(data: T) where T : APRSData {
        guard let aprsBeacon = data as? APRSBeaconData else {
            return
        }

        AprsBeaconStore.shared.receiveBeacon(beacon: aprsBeacon.data)
    }

}
