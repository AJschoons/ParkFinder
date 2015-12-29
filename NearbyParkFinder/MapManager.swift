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
}

protocol MapManagerDelegate: class {
    func mapManager(mapManager: MapManager, didUpdateWithParks parks: [Park])
}

/// Manages the google map
class MapManager: NSObject {
    
    /// Information relevant to park searches used to check whether parks should be updated
    struct ParkSearchInformation {
        var location: CLLocation
        var radius: Int
        var zoom: Float
    }
    
    weak var locationSource: MapManagerLocationSource?
    weak var delegate: MapManagerDelegate?
    
    private(set) var googleMapView: GMSMapView!
    weak var mapRegionView: UIView?
    
    private(set) var nearbyParks = [Park]()
    private var nearbyParkMarkers = [GMSMarker]()
    
    private(set) var state: MapState = .Created
    
    private var lastParkSearchInformation: ParkSearchInformation?
    
    private var mapIsAnimatingFromGettingInitialLocation = false
    private var mapIsAnimatingFromSelectingLocation = false
    private var mapIsAnimatingFromTappingOnMarker = false
    
    private let minMapZoom: Float = 11
    private let maxMapZoom: Float = 15
    private let initialMapZoom: Float = 3
    private let parkSelectionMinZoom: Float = 13
    
    /// The multiplier for radius of visible map to search
    private let radiusSearchMultiplier = 1.2
    
    /// The change in zoom where the parks should be loaded again
    private let zoomChangeRequiringParkUpdate: Float = 0.7
    
    private let markerParkLocationImage = UIImage(named: kParkLocationMarkerImageName)
    private let markerSnippet = "Tap here for more info"
    
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
    
    private func onFinishedAnimatingAfterParkSelection() {
        guard state == .Updated else { return }
        setState(.ParksNeedUpdating)
    }
    
    func onParkSelectedWithIndex(index: Int) {
        let park = nearbyParks[index]
        googleMapView.selectedMarker = nearbyParkMarkers[index]
        
        // Zoom in to at least the parkSelectionMinZoom, but if already zoomed farther then stay at same zoom
        let parkSelectionZoom = max(googleMapView.camera.zoom, parkSelectionMinZoom)
        
        let selectedParkCameraPosition = GMSCameraPosition.cameraWithLatitude(park.location.latitude, longitude: park.location.longitude, zoom: parkSelectionZoom)
        mapIsAnimatingFromSelectingLocation = true
        googleMapView.animateToCameraPosition(selectedParkCameraPosition)
    }
    
    private func onParksNeedUpdatingFromMapPositionChange() {
        guard state == .Updated else { return }
        setState(.ParksNeedUpdating)
    }
    
    // MARK: Helpers
    
    private func updateParks() {
        let center = getMapCenterCoordinate()
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let radiusToSearch = Int(Double(getMapRadiusInMeters()) * radiusSearchMultiplier)
        
        searchForNearbyParksFromLocation(centerLocation, withRadius: radiusToSearch)
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
        
        // Wait until the map has finished animating before changing state to updating parks
        // so that the search radius can be calculated from the map
        // This will happen in the idleAtCameraPosition GMSMapViewDelegate function
        let currentLocationCameraPosition = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: minMapZoom)
        mapIsAnimatingFromGettingInitialLocation = true
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
    
    private func parksShouldUpdateFromMapPositionChange() -> Bool {
        guard let lastParkSearchInformation = lastParkSearchInformation where state == .Updated else { return false }
        
        let distanceFromLastSearchThatUpdateIsNeeded = Double(lastParkSearchInformation.radius / 2)
        let mapCenter = getMapCenterCoordinate()
        let mapCenterLocation = CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        let currentDistanceFromLastSearch = mapCenterLocation.distanceFromLocation(lastParkSearchInformation.location)
        let shouldUpdateFromDistanceChange = currentDistanceFromLastSearch > distanceFromLastSearchThatUpdateIsNeeded
        
        let zoomChangeFromLastSearch = abs(lastParkSearchInformation.zoom - googleMapView.camera.zoom)
        let shouldUpdateFromZoomChange = zoomChangeFromLastSearch > zoomChangeRequiringParkUpdate
        
        return shouldUpdateFromDistanceChange || shouldUpdateFromZoomChange
    }
    
    private func shouldNotUpdateParksDuringMapPositionChange() -> Bool {
        return mapIsAnimatingFromGettingInitialLocation || mapIsAnimatingFromSelectingLocation || mapIsAnimatingFromTappingOnMarker
    }
    
    // MARK: Networking
    
    private func searchForNearbyParksFromLocation(location: CLLocation, withRadius radius: Int) {
        lastParkSearchInformation = ParkSearchInformation(location: location, radius: radius, zoom: googleMapView.camera.zoom)
    
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
                marker.snippet = markerSnippet
                marker.icon = markerParkLocationImage
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
            
        } else if mapIsAnimatingFromSelectingLocation {
            mapIsAnimatingFromSelectingLocation = false
            //onFinishedAnimatingAfterParkSelection()
            
        } else if mapIsAnimatingFromTappingOnMarker {
            mapIsAnimatingFromTappingOnMarker = false
        }
    }
    
    /// Called after a marker has been tapped.
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        mapIsAnimatingFromTappingOnMarker = true
        return false
    }
    
    /// Called repeatedly during any animations or gestures on the map (or once, if the camera is explicitly set)
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        guard shouldNotUpdateParksDuringMapPositionChange() == false else { return }
        
        if parksShouldUpdateFromMapPositionChange() {
            onParksNeedUpdatingFromMapPositionChange()
        }
    }
}
