//
//  ViewController.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 9/20/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Cocoa
import MapKit

class ViewController: NSViewController {
    
    // MARK: - Outlets
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var map: MKMapView!
    
    // MARK: - Member Variables
    var isProtocolStackRunning: Bool = false
    var protocolStack: [APRSParser] = []
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup location for map
        configureLocationServices()
        
        // setup APRS protocol stack
        // the setup of the stack could eventually be configurable...
        let kiss = KISS(hostname: "aprs.montynet.org", port: 8001)
        protocolStack.append(kiss)
        let ax25 = AX25(withInput: kiss)
        protocolStack.append(ax25)
        let aprsBeacon = APRSBeacon(withInput: ax25)
        protocolStack.append(aprsBeacon)
        aprsBeacon.plotter = self
    }

    private func configureLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    private func beginLocationUpdates(locationManager: CLLocationManager) {
        map.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.startUpdatingLocation()
    }
    
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 50000, longitudinalMeters: 50000)
        map.setRegion(zoomRegion, animated: true)
    }
    
    @IBAction func connectAction(_ sender: Any) {
        if isProtocolStackRunning {
            guard let proto = protocolStack.last else { return }
            proto.stop()
            connectButton.title = "Connect"
            isProtocolStackRunning = false
        } else {
            guard let proto = protocolStack.last else { return }
            if proto.start() {
                connectButton.title = "Disconnect"
                isProtocolStackRunning = true
            }
        }
    }

    private func appendToTextField(string: String) {
        print(string)
        textView.textStorage?.append(NSAttributedString(string: "\(string)\n"))
        textView.scrollToEndOfDocument(textView)
    }

}

// MARK: - Extensions
//extension ViewController {
//    // TODO: Move this out of ViewController
//    func didRecieveFrame(data: Data) {
//        let frame = AX25(withFrame: data)
//        if frame == nil { return }
//        
//        let numberOfAddresses = frame!.getNumberOfAddresses()
//        
//        if numberOfAddresses > 0 {
//            var decodedPacket = "\(frame!.getAddressWithSsid(addressNum: 1))>\(frame!.getAddressWithSsid(addressNum: 0))"
//            
//            if (numberOfAddresses - 2) > 0 {
//                decodedPacket.append(",")
//                for address in 2...numberOfAddresses - 1 {
//                    let addressString = frame!.getAddressWithSsid(addressNum: address)
//                    decodedPacket.append("\(addressString)")
//                    
//                    //                    if frame!.isAddressRepeated(addressNum: address) {
//                    //                        decodedPacket.append("*")
//                    //                    }
//                    
//                    if address < numberOfAddresses - 1 {
//                        decodedPacket.append(",")
//                    }
//                }
//            }
//            
//            decodedPacket.append(":")
//            
//            decodedPacket.append(String(bytes: frame!.getAprsInfo(), encoding: .ascii)!)
//            
//            appendToTextField(string: decodedPacket)
//            
//            let aprs = APRSBeacon(station: frame!.getAddressWithSsid(addressNum: 1), withData: frame!.getAprsInfo())
//            if aprs != nil {
//                let aprsAnnotation = MKPointAnnotation()
//                aprsAnnotation.title = aprs?.station
//                aprsAnnotation.coordinate = (aprs?.position)!
//                
//                map.addAnnotation(aprsAnnotation)
//            }
//        }
//    }
//    
//    func didConnect() {
//        isConnected = true
//        print("Connected!")
//    }
//    
//    func didDisconnect() {
//        isConnected = false
//        print("Disconnected!")
//    }
//    
//}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
        
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorized {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
}

extension ViewController: APRSPlotter {
    func receivePosition(beacon: APRSBeaconInfo) {
        let aprsAnnotation = MKPointAnnotation()
        aprsAnnotation.title = beacon.station
        aprsAnnotation.coordinate = beacon.position
        map.addAnnotation(aprsAnnotation)
    }
}
