//
//  APRSPlotter.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/29/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

protocol APRSPlotter {
    func receiveBeacon(beacon: APRSBeaconInfo)
}
