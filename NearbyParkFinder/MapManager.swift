//
//  MapManager.swift
//  NearbyParkFinder
//
//  Created by adam on 12/25/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import GoogleMaps
import SwiftyJSON
import UIKit

enum MapState {
    case Created
    case Initialized
    case InitializedWithFirstLocation
    case ParksNeedUpdating
    case LocationNeedsUpdating
    case Updated
}

protocol MapManagerLocationSource: class {
    func getCurrentLocation() -> CLLocation?
    //func gotLocation()
    //func updatedLocation()
}

protocol MapManagerDelegate: class {
    func mapManager(mapManager: MapManager, didUpdateWithParks parks: [Park])
}

/// Manages the google map
class MapManager: NSObject {
    
    weak var locationSource: MapManagerLocationSource?
    weak var delegate: MapManagerDelegate?
    
    private(set) var googleMapView: GMSMapView!
    weak var mapRegionView: UIView?
    
    private(set) var nearbyParks = [Park]()
    private var nearbyParkMarkers = [GMSMarker]()
    
    private(set) var state: MapState = .Created
    
    private var lastLocationParksSearchedFrom: CLLocation?
    private var radiusUsedForLastParkSearch: Int?
    
    private var mapIsAnimatingFromGettingInitialLocation = false
    
    private let minMapZoom: Float = 11
    private let maxMapZoom: Float = 13
    private let initialMapZoom: Float = 3
    
    // The multiplier for radius of visible map to search
    private let radiusSearchMultiplier = 1.3
    
    private let parkLocationMarkerImage = UIImage(named: kParkLocationMarkerImageName)
    
    init(viewToPlaceMapIn: UIView) {
        super.init()
        mapRegionView = viewToPlaceMapIn
        
        setState(.Created)
    }
    
    // MARK: State management
    
    private func setState(newState: MapState) {
        state = newState
        
        // Entrance actions upon state entry
        switch newState {
            
        case .Created:
            // The delegate must wait for viewDidLayoutSubviews to layout the map view
            // Then the delegate can call onMapRegionSuperviewViewDidLayoutSubviews
            break
            
        case .Initialized:
            // Wait on initial location
            break
            
        case .InitializedWithFirstLocation:
            setupMapViewAfterGettingInitialLocation()
            break
            
        case .ParksNeedUpdating:
            updateParks()
            break
            
        case .LocationNeedsUpdating:
            // TODO: support location updating
            break
            
        case .Updated:
            break
        }
    }
    
    // MARK: Events
    // All functions that set state will be here, among others
    
    func onMapRegionSuperviewViewDidLayoutSubviews() {
        guard state == .Created else { return }
        initializeMapView()
        onInitialized()
    }
    
    private func onInitialized() {
        setState(.Initialized)
    }
    
    func onGotLocation() {
        guard state == .Initialized else { return }
        setState(.InitializedWithFirstLocation)
    }
    
    private func onUpdatedParks() {
        guard state == .ParksNeedUpdating else { return }
        setState(.Updated)
    }
    
    private func onFinishedAnimatingToInitialMapLocation() {
        guard state == .InitializedWithFirstLocation else { return }
        setState(.ParksNeedUpdating)
    }
    
    func onParkSelected(park: Park) {
        let selectedParkCameraPosition = GMSCameraPosition.cameraWithLatitude(park.location.latitude, longitude: park.location.longitude, zoom: maxMapZoom)
        googleMapView.animateToCameraPosition(selectedParkCameraPosition)
    }
    
    // MARK: Helpers
    
    private func updateParks() {
        guard let location = locationSource?.getCurrentLocation() else { return }
        let radiusToSearch = Int(Double(getMapRadiusInMeters()) * radiusSearchMultiplier)
        searchForNearbyParksFromLocation(location, withRadius: radiusToSearch)
    }
    
    func initializeMapView() {
        guard let mapRegionView = mapRegionView else { return }
        
        googleMapView = GMSMapView(frame: mapRegionView.bounds)
        mapRegionView.addSubview(googleMapView)
        
        // Map should initially start centered in the continental United States
        let centerOfUnitedStates = CLLocationCoordinate2DMake(39.8282, -98.5795)
        googleMapView.camera = GMSCameraPosition.cameraWithTarget(centerOfUnitedStates, zoom: initialMapZoom)
        
        googleMapView.delegate = self
    }
    
    private func setupMapViewAfterGettingInitialLocation() {
        guard let location = locationSource?.getCurrentLocation() else { return }
        
        googleMapView.myLocationEnabled = true
        googleMapView.setMinZoom(minMapZoom, maxZoom: maxMapZoom)
        
        let currentLocationCameraPosition = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: minMapZoom)
        googleMapView.animateToCameraPosition(currentLocationCameraPosition)
        
        // Wait until the map has finished animating before changing state to updating parks
        // so that the search radius can be calculated from the map
        // This will happen in the idleAtCameraPosition GMSMapViewDelegate function
        mapIsAnimatingFromGettingInitialLocation = true
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
    
    // MARK: Networking
    
    private func searchForNearbyParksFromLocation(location: CLLocation, withRadius radius: Int) {
        guard let location = locationSource?.getCurrentLocation() else { return }
    
        GooglePlacesClient.sharedClient.getPlacesNearbySearchParks(location, radius: radius,
            success: { [weak self] task, responseObject in
                guard let strongSelf = self else { return }
                guard let responseObject = responseObject else { return }
                let json = JSON(responseObject)
                guard let results = json["results"].array else { return }
                
                strongSelf.updateParksAndMarkersFromParkResultsJSON(results)
                strongSelf.onUpdatedParks()
                strongSelf.delegate?.mapManager(strongSelf, didUpdateWithParks: strongSelf.nearbyParks)
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    private func updateParksAndMarkersFromParkResultsJSON(parkResultsJSON: [JSON]) {
        guard let location = locationSource?.getCurrentLocation() else { return }
        
        // Clear out the old park markers
        for parkMarker in nearbyParkMarkers {
            parkMarker.map = nil
        }
        
        // Create and store parks from JSON, create and store map markers from those parks
        nearbyParks = []
        nearbyParkMarkers = []
        for parkJSON in parkResultsJSON {
            do {
                let park = try Park.initWithJSON(parkJSON, currentLocation: location)
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

extension MapManager: GMSMapViewDelegate {
    // MARK: GMSMapViewDelegate
    
    /// Called when the map becomes idle, after any outstanding gestures or animations have completed (or after the camera has been explicitly set).
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        
        if mapIsAnimatingFromGettingInitialLocation {
            // Map has finished animating to current location
            // Now get the nearby parks since we can get the radius from the animated map
            mapIsAnimatingFromGettingInitialLocation = false
            onFinishedAnimatingToInitialMapLocation()
        }
    }
    
    /// Called repeatedly during any animations or gestures on the map (or once, if the camera is explicitly set)
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        // TODO: update parks while scrolling
    }
}
