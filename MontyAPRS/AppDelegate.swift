//
//  AppDelegate.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/20/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var protocolStack: [APRSParser] = []
    var isProtocolStackRunning: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // setup APRS protocol stack
        let kiss = KISS(hostname: "aprs.montynet.org", port: 8001)
        protocolStack.append(kiss)
        let ax25 = AX25(withInput: kiss)
        protocolStack.append(ax25)
        let aprsBeacon = APRSBeacon(withInput: ax25)
        protocolStack.append(aprsBeacon)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if isProtocolStackRunning {
            guard let proto = protocolStack.last else { return }
            proto.stop()
            isProtocolStackRunning = false
        }
    }

    func toggleProtocolStack() -> Bool {
        if isProtocolStackRunning {
            guard let proto = protocolStack.last else { return false }
            proto.stop()
            isProtocolStackRunning = false
        } else {
            guard let proto = protocolStack.last else { return false }
            if proto.start() {
                isProtocolStackRunning = true
            } else {
                return false
            }
        }

        return true
    }
}

extension AppDelegate: AprsBeaconHandler {
    func receiveBeacon(beacon: APRSBeaconInfo) {
        AprsBeaconStore.shared.receiveBeacon(beacon: beacon)
    }
}
