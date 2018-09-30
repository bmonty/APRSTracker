//
//  InputDelegate.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/29/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

protocol InputDelegate {
    func didConnect()
    func didDisconnect()
    func receivedData<T: APRSData>(data: T)
}
