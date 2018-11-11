//
//  KISS.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/22/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

struct KISSData: APRSData {
    typealias APRSDataElement = Data
    var protocolName = "KISS_FRAME"
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
}

enum KISSTags: Int {
    case START
    case FRAME
}

class KISS: NSObject, APRSParser {

    // MARK: - Constants
    let FEND: UInt8 = 0xC0
    let FESC: UInt8 = 0xDB
    let TFEND: UInt8 = 0xDC
    let TFESC: UInt8 = 0xDD

    // MARK: - Properties
    let hostname: String
    let port: UInt16
    var isConnected: Bool = false
    var delegate: InputDelegate?
    private var socket: GCDAsyncSocket!
    
    // MARK:  - Methods
    init(hostname: String, port: UInt16) {
        self.hostname = hostname
        self.port = port

        super.init()

        // initialize socket to run on global queue with QoS utility
        socket = GCDAsyncSocket.init(delegate: self, delegateQueue: DispatchQueue.global(qos: .utility))
    }

    func start() -> Bool {
        do {
            try socket.connect(toHost: hostname, onPort: port)
        } catch let e {
            print(e)
            return false
        }
        
        return true
    }
    
    func stop() {
        socket.write(Data(bytes: [FEND, 0x00, FEND]), withTimeout: -1, tag: 0)
        socket.disconnect()
    }
    
}

extension KISS: GCDAsyncSocketDelegate {
    
    // called when GCDAsyncSocket connects
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        delegate?.didConnect()
        isConnected = true
        
        // start reading for KISS frames
        socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: KISSTags.START.rawValue)
    }
    
    // called when GCDAsyncSocket disconnects
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        delegate?.didDisconnect()
        isConnected = false
    }
    
    // called when a FEND is read
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if tag == KISSTags.START.rawValue {
            // recieved start of KISS frame, continue to read until next FEND
            socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: KISSTags.FRAME.rawValue)
            return
        }
        
        if tag == KISSTags.FRAME.rawValue {
            var frame: Data
            
            // check this is a data frame
            if data[0] == 0x00 {
                frame = data.dropFirst()
            } else {
                // this is isn't a data frame...do nothing
                return
            }
            
            // get rid of FEND at end of frame
            frame = frame.dropLast()
            
            // look for FESC and replace with appropriate value
            var position = frame.startIndex
            while position < frame.endIndex {
                guard let bounds = frame.range(of: Data(bytes: [FESC]), in: position..<frame.endIndex) else {
                    break
                }

                switch frame[bounds.upperBound] {
                case TFEND:
                    frame.replaceSubrange(bounds.lowerBound...bounds.upperBound, with: Data(bytes: [FEND]))
                case TFESC:
                    frame.replaceSubrange(bounds.lowerBound...bounds.upperBound, with: Data(bytes: [FESC]))
                default:
                    break
                }
                position += bounds.upperBound
            }
            
            // send received frame up the stack
            let kissData = KISSData(data: frame)
            delegate?.receivedData(data: kissData)
            
            // start read for the next frame
            socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: KISSTags.START.rawValue)
        }
    }
    
}
