//
//  MapViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/22/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapRegionView: UIView!
    private var googleMapView: GMSMapView!
    
    private var currentLocation: CLLocation?
    private var currentLocationMarker: GMSMarker?
    
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
        
        currentLocationMarker = GMSMarker(position: location.coordinate)
        currentLocationMarker!.title = "Current Location";
        currentLocationMarker!.icon = UIImage(named: kUserLocationMarkerImageName)
        currentLocationMarker!.map = googleMapView;
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
        print(view.frame)
        print(mapRegionView.bounds)
        print(mapRegionView.frame)
        
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
