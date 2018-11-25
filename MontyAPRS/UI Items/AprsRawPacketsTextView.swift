//
//  AprsRawPacketsTextView.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/25/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import AppKit

class AprsRawPacketsTextView: NSTextView {

    override var isEditable: Bool {
        get {
            return false
        }
        set {
            // isEditable is always false
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setUp()
    }

    private func setUp() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateBeaconAnnotation(_:)), name: .didReceiveBeacon, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateBeaconAnnotation(_ notification: Notification) {
        if let userInfo = notification.userInfo as? [String: String] {
            guard let station = userInfo["station"] else {
                return
            }

            guard let beacon = AprsBeaconStore.shared.getBeacons(forStation: station)?.last else {
                return
            }

            // make sure self.textStorage.append runs on the main queue
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }

                let beaconString = "\(beacon.station)->\(beacon.destination) \(beacon.message ?? "")\n"
                let attr = NSAttributedString(string: beaconString as String,
                                              attributes: [.foregroundColor: NSColor.textColor])
                self.textStorage?.append(attr)
            }
        }
    }

}
