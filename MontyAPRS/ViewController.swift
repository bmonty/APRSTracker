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
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var map: MKMapView!

    // MARK: - Member Variables
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup location for map
        configureLocationServices()
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
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let connectButton = sender as? NSButton else {
            return
        }

        if connectButton.title == "Connect" {
            appDelegate.aprsManager.start()
            connectButton.title = "Disconnect"
        } else {
            appDelegate.aprsManager.stop()
            connectButton.title = "Connect"
        }
    }

    private func appendToTextField(string: String) {
        textView.textStorage?.append(NSAttributedString(string: "\(string)\n"))
        textView.scrollToEndOfDocument(textView)
    }

}

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

extension ViewController: AprsBeaconStoreDelegate {

    func beaconsDidUpdate(withStation station: String) {
//        guard let stationInfo = AprsBeaconStore.shared.beacons[station] else {
//            return
//        }
//        guard let beacon = stationInfo.last else {
//            return
//        }
//
//        let aprsAnnotation = MKPointAnnotation()
//        aprsAnnotation.title = station
//        if beacon.message != nil {
//            aprsAnnotation.subtitle = beacon.message
//        }
//        aprsAnnotation.coordinate = beacon.position
//        map.addAnnotation(aprsAnnotation)
//
//        var beaconText = String("\(beacon.station)>\(beacon.destination),")
//        if beacon.digipeaters != nil {
//            let digipeaters = beacon.digipeaters!
//            var numDigipeaters = digipeaters.count
//            for digipeater in digipeaters {
//                beaconText.append(digipeater)
//                if numDigipeaters < digipeaters.count {
//                    beaconText.append(",")
//                }
//                numDigipeaters += 1
//            }
//        }
//
//        if beacon.message != nil {
//            let message = beacon.message!
//            beaconText.append(":\(message)")
//        }

        appendToTextField(string: station)
    }

}
