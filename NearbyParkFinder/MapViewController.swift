//
//  MapViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/22/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapRegionView: UIView!
    private var googleMapView: GMSMapView!
    
    private var currentLocation: CLLocation?
    private var currentLocationMarker: GMSMarker?
    private var nearbyParks = [Park]()
    private var nearbyParkMarkers = [GMSMarker]()
    
    private var returningFromLocationVerificationViewController = false
    
    override func viewDidLayoutSubviews() {
        if googleMapView == nil {
            initializeMapView()
        }
        
        googleMapView.frame = mapRegionView.frame
    }
    
    override func viewDidAppear(animated: Bool) {
        if currentLocation == nil {
            // Get the location before showing this view controller
            presentLocationVerificationViewController()
        } else if returningFromLocationVerificationViewController {
            returningFromLocationVerificationViewController = false
            onGotLocationSuccess()
        }
    }
    
    /// Creates a LocationVerificationViewController from the storyboard and presents it
    private func presentLocationVerificationViewController() {
        let storyboard = UIStoryboard(name: kMainStoryboardName, bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier(LocationVerificationViewControllerIndentifier)
        guard let lvvc = vc as? LocationVerificationViewController else { return }
        lvvc.delegate = self
        presentViewController(lvvc, animated: true, completion: nil)
    }
    
    private func onGotLocationSuccess() {
        guard let location = currentLocation else { return }
        let currentLocationCameraPosition = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 11)
        googleMapView.animateToCameraPosition(currentLocationCameraPosition)
        googleMapView.myLocationEnabled = true
        
        GooglePlacesClient.sharedClient.getPlacesNearbySearchParks(location, radius: 10000,
            success: { [weak self] task, responseObject in
                guard let strongSelf = self else { return }
                guard let responseObject = responseObject else { return }
                let json = JSON(responseObject)
                guard let results = json["results"].array else { return }
                strongSelf.createParksAndMarkersFromParkResultsJSON(results)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    private func createParksAndMarkersFromParkResultsJSON(parkResultsJSON: [JSON]) {
        // Create and store parks from JSON, create and store map markers from those parks
        nearbyParks = []
        nearbyParkMarkers = []
        for parkJSON in parkResultsJSON {
            do {
                let park = try Park.initWithJSON(parkJSON)
                nearbyParks.append(park)
                
                let marker = GMSMarker(position: park.location)
                marker.title = park.name
                marker.icon = UIImage(named: kParkLocationMarkerImageName)
                marker.map = googleMapView
                nearbyParkMarkers.append(marker)
            } catch {
                continue
            }
        }
    }
    
    private func onGotLocationFailure() {
        presentLocationVerificationViewController()
    }
    
    private func getLocation() {
        LocationManager.sharedManager.getLocation(
            success: { [weak self] location, accuracy in
                guard let strongSelf = self else { return }
                strongSelf.currentLocation = location
                strongSelf.onGotLocationSuccess()
            },
            failure: { [weak self] errorDescription in
                guard let strongSelf = self else { return }
                strongSelf.onGotLocationFailure()
            }
        )
    }
    
    private func initializeMapView() {
        googleMapView = GMSMapView(frame: mapRegionView.bounds)
        mapRegionView.addSubview(googleMapView)
        
        // Map should initially start centered in the continental United States
        let centerOfUnitedStates = CLLocationCoordinate2DMake(39.8282, -98.5795)
        googleMapView.camera = GMSCameraPosition.cameraWithTarget(centerOfUnitedStates, zoom: 3)
    }
}

extension MapViewController: LocationVerificationViewControllerDelegate {
    func locationVerificationViewControllerDidGetLocation(location: CLLocation) {
        // Need to wait until view is visible before animating
        currentLocation = location
        returningFromLocationVerificationViewController = true
    }
}
