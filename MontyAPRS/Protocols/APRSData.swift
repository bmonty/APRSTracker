//
//  APRSData.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/29/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

protocol APRSData {
    associatedtype APRSDataElement: Any
    var protocolName: String { get }
    var data: APRSDataElement { get set }
}
