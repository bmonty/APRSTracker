//
//  KISS.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/22/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

/**
 Protocol for interaction with KISS class.
*/
protocol KISSDelegate: AnyObject {
    func didConnect()
    func didDisconnect()
    func didRecieveFrame(data: Data)
}

class KISS: NSObject, GCDAsyncSocketDelegate {

    // MARK: List of Constants
    private let TAG_KISS_START = 1
    private let TAG_KISS_FRAME = 2
    let FEND: UInt8 = 0xC0
    let FESC: UInt8 = 0xDB
    let TFEND: UInt8 = 0xDC
    let TFESC: UInt8 = 0xDD

    // MARK: Member Variables
    var hostname: String
    var port: UInt16
    var isConnected: Bool = false
    private var socket: GCDAsyncSocket!
    private var delegate: KISSDelegate?
    
    // MARK: Initializer
    init(hostname: String, port: UInt16, withDelegate delegate: KISSDelegate?) {
        self.hostname = hostname
        self.port = port
        self.delegate = delegate
       
        super.init()
        
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }

    // MARK: Methods
    func connect() {
        do {
            try socket.connect(toHost: hostname, onPort: port)
        } catch let e {
            print(e)
        }
    }
    
    func disconnect() {
        socket.write(Data(bytes: [FEND, 0x00, FEND]), withTimeout: -1, tag: 0)
        socket.disconnect()
    }
    
    // called when GCDAsyncSocket connects
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        delegate?.didConnect()
        isConnected = true
        
        // start reading for KISS frames
        socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: TAG_KISS_START)
    }
    
    // called when GCDAsyncSocket disconnects
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        delegate?.didDisconnect()
        isConnected = false
    }
    
    // called when a FEND is read
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if tag == TAG_KISS_START {
            // recieved start of KISS frame, continue to read until next FEND
            socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: TAG_KISS_FRAME)
            return
        }
        
        if tag == TAG_KISS_FRAME {
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
            while position <= frame.endIndex {
                let bounds = frame.range(of: Data(bytes: [FESC]), in: position..<frame.endIndex)
                if bounds != nil {
                    switch frame[bounds!.upperBound] {
                    case TFEND:
                        frame.replaceSubrange(bounds!.lowerBound...bounds!.upperBound, with: Data(bytes: [FEND]))
                    case TFESC:
                        frame.replaceSubrange(bounds!.lowerBound...bounds!.upperBound, with: Data(bytes: [FESC]))
                    default:
                        break
                    }
                    position += bounds!.upperBound as Int
                } else {
                    break
                }
            }
            
            // this should be a raw AX.25 frame
            delegate?.didRecieveFrame(data: frame)
            
            // start read for the next frame
            socket.readData(to: Data(bytes: [FEND]), withTimeout: -1, tag: TAG_KISS_START)
        }
    }
}
