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
    
    // MARK: - Reference Outlets
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var mainSplitView: NSSplitView!
    
    // MARK: - Member Variables
    let plotter = AprsPlotter()
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup location for map
        configureLocationServices()

        // register aprs beacon annotation view
        map.register(BeaconAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        // connect the plotter
        plotter.mapView = map
        map.delegate = plotter
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        let maxPos = mainSplitView.maxPossiblePositionOfDivider(at: 0)
        mainSplitView.setPosition(maxPos, ofDividerAt: 0)
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

    @IBAction func aprsConnect(_ menuItem: NSMenuItem) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            return
        }

        if menuItem.state == NSControl.StateValue.off {
            appDelegate.aprsManager.start()
            menuItem.state = NSControl.StateValue.on
        } else {
            appDelegate.aprsManager.stop()
            menuItem.state = NSControl.StateValue.off
        }
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
