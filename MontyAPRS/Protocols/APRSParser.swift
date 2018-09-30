//
//  APRSParser.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/29/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation

protocol APRSParser {
//    associatedtype APRSParserDelegate
    var delegate: InputDelegate? { get set }
    func start() -> Bool
    func stop()
}
