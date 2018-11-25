//
//  AprsPlotter.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/11/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Cocoa
import MapKit

/**
 Manages annotations for beacons that are plotted on the map.
 */
class AprsPlotter: NSObject {

    var plottedBeacons: [String: BeaconAnnotation] = [:]
    weak var mapView: MKMapView?

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(updateBeaconAnnotation(_:)), name: .didReceiveBeacon, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func updateBeaconAnnotation(_ notification: Notification) {
        if let userInfo = notification.userInfo as? [String: String] {
            guard let station = userInfo["station"] else {
                return
            }

            guard let beacon = AprsBeaconStore.shared.getBeacons(forStation: station)?.last else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                // remove old annotation if this station is already plotted
                if let annotation = self.plottedBeacons[station] {
                    self.mapView?.removeAnnotation(annotation)
                }

                // create a new annotation
                let newAnnotation = BeaconAnnotation(station: beacon.station,
                                                     symbol: beacon.symbol ?? "?",
                                                     coordinate: beacon.position)

                self.plottedBeacons[station] = newAnnotation
                self.mapView?.addAnnotation(newAnnotation)
            }
        }
    }

    //    func checkPositions(oldPosition: CLLocationCoordinate2D, newPosition: CLLocationCoordinate2D) {
    //        let oldPosLocation = CLLocation(latitude: oldPosition.latitude, longitude: oldPosition.longitude)
    //        let newPosLocation = CLLocation(latitude: newPosition.latitude, longitude: newPosition.longitude)
    //
    //        let distance = newPosLocation.distance(from: oldPosLocation)
    //
    //    }

}

// MARK: - MKMapViewDelegate
extension AprsPlotter: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) ->
        MKAnnotationView? {
            var view: BeaconAnnotationView
            guard let annotation = annotation as? BeaconAnnotation else {
                return nil
            }
            guard let identifier = annotation.symbol else {
                return nil
            }

            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? BeaconAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = BeaconAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            let calloutView = NSTextView()
            calloutView.isEditable = false
            calloutView.string = annotation.title!
            view.detailCalloutAccessoryView = calloutView

            return view
    }

}

// MARK: - BeaconAnnotation
class BeaconAnnotation: NSObject, MKAnnotation {

    let title: String?
    let symbol: String?
    let coordinate: CLLocationCoordinate2D

    init(station: String, symbol: String, coordinate: CLLocationCoordinate2D) {
        self.title = station
        self.symbol = symbol
        self.coordinate = coordinate

        super.init()
    }

}

// MARK: - BeaconAnnotationView
class BeaconAnnotationView: MKAnnotationView {

    override var annotation: MKAnnotation? {
        willSet {
            guard let beacon = newValue as? BeaconAnnotation else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)

            if let symbol = beacon.symbol {
                do {
                    try image = AprsIcon.shared?.getImage(symbol)
                } catch {
                    image = nil
                }
            }
        }
    }
    
}
