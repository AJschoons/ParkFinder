//
//  MapViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/22/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import GoogleMaps
import SwiftyJSON
import UIKit

class MapViewController: UIViewController {
    
    private var parkTableViewController: ParkTableViewController!
    
    @IBOutlet weak var mapRegionView: UIView!
    private var googleMapView: GMSMapView!
    
    private var currentLocation: CLLocation?
    private var currentLocationMarker: GMSMarker?
    private(set) var nearbyParks = [Park]()
    private var nearbyParkMarkers = [GMSMarker]()
    
    private var returningFromLocationVerificationViewController = false
    
    private var mapHasGottenInitialLocation = false
    private var mapIsAnimatingFromGettingLocation = false
    
    private let parkLocationMarkerImage = UIImage(named: kParkLocationMarkerImageName)
    
    private var lastLocationParksSearchedFrom: CLLocation?
    private var radiusUsedForLastParkSearch: Int?
    
    
    private let minMapZoom: Float = 11
    private let maxMapZoom: Float = 13
    private let initialMapZoom: Float = 3
    
    override func viewDidLayoutSubviews() {
        if googleMapView == nil {
            initializeMapView()
        }
        
        googleMapView.frame = mapRegionView.frame
    }
    
    override func viewDidLoad() {
        view.backgroundColor = primaryGreen2
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == kParkTableViewControllerEmbedSegueIdentifier {
            // Embed for the ParkTableViewController
            guard let destination = segue.destinationViewController as? ParkTableViewController else { return }
            parkTableViewController = destination
            parkTableViewController.parkDataSource = self
            parkTableViewController.delegate = self
            
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
    
    private func reloadParkTableViewControllerParkData() {
        parkTableViewController.tableView.reloadData()
    }
}

extension MapViewController {
    // MARK: Networking
    
    private func searchForNearbyParks() {
        guard let location = currentLocation else { return }
        
        let radiusToSearch = Int(Double(getMapRadiusInMeters()) * 1.5)
        GooglePlacesClient.sharedClient.getPlacesNearbySearchParks(location, radius: radiusToSearch,
            success: { [weak self] task, responseObject in
                guard let strongSelf = self else { return }
                guard let responseObject = responseObject else { return }
                let json = JSON(responseObject)
                guard let results = json["results"].array else { return }
                
                strongSelf.createParksAndMarkersFromParkResultsJSON(results)
                strongSelf.reloadParkTableViewControllerParkData()
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    private func createParksAndMarkersFromParkResultsJSON(parkResultsJSON: [JSON]) {
        guard let currentLocation = currentLocation else { return }
        
        // Create and store parks from JSON, create and store map markers from those parks
        nearbyParks = []
        nearbyParkMarkers = []
        for parkJSON in parkResultsJSON {
            do {
                let park = try Park.initWithJSON(parkJSON, currentLocation: currentLocation)
                nearbyParks.append(park)
                
                let marker = GMSMarker(position: park.location)
                marker.title = park.name
                marker.icon = parkLocationMarkerImage
                marker.map = googleMapView
                nearbyParkMarkers.append(marker)
            } catch {
                continue
            }
        }
    }
}

extension MapViewController {
    // MARK: Location
    
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
    
    private func onGotLocationSuccess() {
        // Called when found location or returning from location verification view controller
        
        setupMapViewAfterGettingInitialLocation()
        
        // Wait until the map has finished animating before searching for nearby parks
        // so that the search radius can be calculated from the map
        // This will happen in the idleAtCameraPosition GMSMapViewDelegate function
        mapIsAnimatingFromGettingLocation = true
    }
    
    private func onGotLocationFailure() {
        presentLocationVerificationViewController()
    }
}

extension MapViewController {
    // MARK: Map
    
    private func setupMapViewAfterGettingInitialLocation() {
        guard let location = currentLocation else { return }
        
        googleMapView.myLocationEnabled = true
        googleMapView.setMinZoom(minMapZoom, maxZoom: maxMapZoom)
        
        let currentLocationCameraPosition = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: minMapZoom)
        googleMapView.animateToCameraPosition(currentLocationCameraPosition)
    }
    
    private func getMapRadiusInMeters() -> Int {
        let centerCoordinate = getMapCenterCoordinate()
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = getMapTopCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        let radius = CLLocationDistance(centerLocation.distanceFromLocation(topCenterLocation))
        return Int(radius)
    }
    
    private func getMapCenterCoordinate() -> CLLocationCoordinate2D {
        let centerPoint = googleMapView.center
        return googleMapView.projection.coordinateForPoint(centerPoint)
    }
    
    private func getMapTopCenterCoordinate() -> CLLocationCoordinate2D {
        let topCenterPoint = googleMapView.convertPoint(CGPointMake(googleMapView.frame.size.width / 2.0, 0), fromView: googleMapView)
        return googleMapView.projection.coordinateForPoint(topCenterPoint)
    }
    
    private func initializeMapView() {
        googleMapView = GMSMapView(frame: mapRegionView.bounds)
        mapRegionView.addSubview(googleMapView)
        
        // Map should initially start centered in the continental United States
        let centerOfUnitedStates = CLLocationCoordinate2DMake(39.8282, -98.5795)
        googleMapView.camera = GMSCameraPosition.cameraWithTarget(centerOfUnitedStates, zoom: initialMapZoom)
        
        googleMapView.delegate = self
    }
}

extension MapViewController: LocationVerificationViewControllerDelegate {
    // MARK: LocationVerificationViewControllerDelegate
    
    func locationVerificationViewControllerDidGetLocation(location: CLLocation) {
        // Need to wait until view is visible before animating
        currentLocation = location
        returningFromLocationVerificationViewController = true
    }
}

extension MapViewController: ParkTableViewControllerParkDataSource {
    // MARK: ParkTableViewControllerParkDataSource
    
    func getParks() -> [Park] { return nearbyParks }
}

extension MapViewController: ParkTableViewControllerDelegate {
    // MARK: ParkTableViewControllerDelegate
    
    func parkTableViewController(parkTableViewController: ParkTableViewController, didSelectParkWithRow row: Int) {
        let park = nearbyParks[row]
        let selectedParkCameraPosition = GMSCameraPosition.cameraWithLatitude(park.location.latitude, longitude: park.location.longitude, zoom: maxMapZoom)
        googleMapView.animateToCameraPosition(selectedParkCameraPosition)
    }
}

extension MapViewController: GMSMapViewDelegate {
    // MARK: GMSMapViewDelegate
    
    /// Called when the map becomes idle, after any outstanding gestures or animations have completed (or after the camera has been explicitly set).
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        
        if mapIsAnimatingFromGettingLocation {
            // Map has finished animating to current location
            // Now get the nearby parks since we can get the radius from the animated map
            mapIsAnimatingFromGettingLocation = false
            searchForNearbyParks()
        }
    }
    
    /// Called repeatedly during any animations or gestures on the map (or once, if the camera is explicitly set)
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        // TODO: update parks while scrolling
    }
}
