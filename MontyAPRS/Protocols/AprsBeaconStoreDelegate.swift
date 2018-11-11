//
//  AprsBeaconStoreDelegate.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/8/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

protocol AprsBeaconStoreDelegate {
    func beaconsDidUpdate(withStation station: String)
}
