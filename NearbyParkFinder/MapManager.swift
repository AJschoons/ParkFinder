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

protocol MapManagerDelegate: class {
    func mapManager(mapManager: MapManager, didUpdateWithParks parks: [Park])
    func mapManager(mapManager: MapManager, didTapOnInfoWindowOfPark park: Park)
}

/// Manages the google map
class MapManager: NSObject {
    
    /// Information relevant to park searches used to check whether parks should be updated
    struct ParkSearchInformation {
        var location: CLLocation
        var radius: Int
        var zoom: Float
    }
    
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
    private var mapIsAnimatingToCurrentLocation = false
    
    private let minMapZoom: Float = 11
    private let maxMapZoom: Float = 15
    private let initialMapZoom: Float = 3
    private let parkSelectionMinZoom: Float = 13
    
    /// The multiplier for radius of visible map to search
    private let radiusSearchMultiplier = 1.3
    
    /// The change in zoom where the parks should be loaded again
    private let zoomChangeRequiringParkUpdate: Float = 0.7
    
    /// The distance in meters a park can be from the center of the map to still be considered at the center
    private let parkAtCenterOfMapDistanceThreshold = 10.0
    
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
    
    private func onFinishedAnimatingToCurrentLocation() {
        guard state == .Updated else { return }
        setState(.ParksNeedUpdating)
    }
    
    func onParkSelectedWithIndex(index: Int) {
        let park = nearbyParks[index]
        
        if selectionShouldBehaveLikeInfoWindowTapForParkWithIndex(index) {
            // Show info window of the park
            delegate?.mapManager(self, didTapOnInfoWindowOfPark: park)
            
        } else {
            // Animate to the park and set its marker as selected
            setMarkerSelectedAndAnimateToPark(park, withMarker: nearbyParkMarkers[index])
        }
    }
    
    /// Animates to current location at current zoom level
    func onAnimateToCurrentLocation() {
        do {
            let currentLocation = try CurrentLocationManager.sharedManager.getCurrentLocation()
            let currentPosition = GMSCameraPosition.cameraWithLatitude(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: googleMapView.camera.zoom)
            mapIsAnimatingToCurrentLocation = true
            googleMapView.animateToCameraPosition(currentPosition)
        } catch {
            return
        }
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
        do {
            let location = try CurrentLocationManager.sharedManager.getCurrentLocation()
            
            googleMapView.myLocationEnabled = true
            googleMapView.setMinZoom(minMapZoom, maxZoom: maxMapZoom)
            
            // Wait until the map has finished animating before changing state to updating parks
            // so that the search radius can be calculated from the map
            // This will happen in the idleAtCameraPosition GMSMapViewDelegate function
            let currentLocationCameraPosition = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: minMapZoom)
            mapIsAnimatingFromGettingInitialLocation = true
            googleMapView.animateToCameraPosition(currentLocationCameraPosition)
        } catch {
            return
        }

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
        
        let distanceFromLastSearchThatUpdateIsNeeded = Double(lastParkSearchInformation.radius) * 0.75
        let mapCenter = getMapCenterCoordinate()
        let mapCenterLocation = CLLocation(latitude: mapCenter.latitude, longitude: mapCenter.longitude)
        let currentDistanceFromLastSearch = mapCenterLocation.distanceFromLocation(lastParkSearchInformation.location)
        let shouldUpdateFromDistanceChange = currentDistanceFromLastSearch > distanceFromLastSearchThatUpdateIsNeeded
        
        let zoomChangeFromLastSearch = abs(lastParkSearchInformation.zoom - googleMapView.camera.zoom)
        let shouldUpdateFromZoomChange = zoomChangeFromLastSearch > zoomChangeRequiringParkUpdate
        
        return shouldUpdateFromDistanceChange || shouldUpdateFromZoomChange
    }
    
    private func shouldNotUpdateParksDuringMapPositionChange() -> Bool {
        return mapIsAnimatingFromGettingInitialLocation || mapIsAnimatingFromSelectingLocation || mapIsAnimatingFromTappingOnMarker || mapIsAnimatingToCurrentLocation
    }
    
    /// Returns true if the park is already selected and at the center of the map
    private func selectionShouldBehaveLikeInfoWindowTapForParkWithIndex(parkIndex: Int) -> Bool {
        guard let selectedMarker = googleMapView.selectedMarker else { return false }
        guard nearbyParkMarkers[parkIndex] == selectedMarker else { return false }
        
        let park = nearbyParks[parkIndex]
        let parkLocation = CLLocation(latitude: park.location.latitude, longitude: park.location.longitude)
        
        let centerMapCoordinate = getMapCenterCoordinate()
        let centerMapLocation = CLLocation(latitude: centerMapCoordinate.latitude, longitude: centerMapCoordinate.longitude)
        
        return parkLocation.distanceFromLocation(centerMapLocation) < parkAtCenterOfMapDistanceThreshold
    }
    
    private func setMarkerSelectedAndAnimateToPark(park: Park, withMarker marker: GMSMarker) {
        googleMapView.selectedMarker = marker
        
        // Zoom in to at least the parkSelectionMinZoom, but if already zoomed farther then stay at same zoom
        let parkSelectionZoom = max(googleMapView.camera.zoom, parkSelectionMinZoom)
        
        let selectedParkCameraPosition = GMSCameraPosition.cameraWithLatitude(park.location.latitude, longitude: park.location.longitude, zoom: parkSelectionZoom)
        mapIsAnimatingFromSelectingLocation = true
        googleMapView.animateToCameraPosition(selectedParkCameraPosition)
    }
    
    // MARK: Networking
    
    private func searchForNearbyParksFromLocation(location: CLLocation, withRadius radius: Int) {
        do {
            let currentLocation = try CurrentLocationManager.sharedManager.getCurrentLocation()
            lastParkSearchInformation = ParkSearchInformation(location: location, radius: radius, zoom: googleMapView.camera.zoom)
            
            GooglePlacesClient.sharedClient.getPlacesNearbySearchParks(location, radius: radius,
                success: { [weak self] task, responseObject in
                    guard let strongSelf = self else { return }
                    guard let responseObject = responseObject else { return }
                    let json = JSON(responseObject)
                    guard let results = json["results"].array else { return }
                    
                    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        guard let strongSelf = self else { return }
                        strongSelf.updateParksAndMarkersFromParkResultsJSON(results, withCurrentLocation: currentLocation)
                    })
                    
                    strongSelf.onUpdatedParks()
                    strongSelf.delegate?.mapManager(strongSelf, didUpdateWithParks: strongSelf.nearbyParks)
                },
                failure: defaultAFHTTPFailureBlock
            )
        } catch {
            return
        }
    }
    
    private func updateParksAndMarkersFromParkResultsJSON(parkResultsJSON: [JSON], withCurrentLocation currentLocation: CLLocation) {
        objc_sync_enter(nearbyParks)
        objc_sync_enter(nearbyParkMarkers)
        objc_sync_enter(googleMapView)
        
        let selectedMarker = googleMapView.selectedMarker
        var selectedPark: Park!
        
        // Clear out the old park markers, except the selected one
        for (index, parkMarker) in nearbyParkMarkers.enumerate() {
            if selectedMarker != nil && parkMarker == selectedMarker {
                selectedPark = nearbyParks[index]
            } else {
                parkMarker.map = nil
            }
        }
        
        //
        // Create and store parks from JSON, create and store map markers from those parks
        //
        
        nearbyParks = []
        nearbyParkMarkers = []
        
        // If a marker was selected then have that be the first listed, and don't have it removed
        if selectedPark != nil && selectedMarker != nil {
            nearbyParks.append(selectedPark)
            nearbyParkMarkers.append(selectedMarker)
        }
        
        for parkJSON in parkResultsJSON {
            do {
                let park = try Park.initWithJSON(parkJSON, currentLocation: currentLocation)
                
                // If there was a selected marker kept, don't add it again
                if selectedPark != nil && selectedMarker != nil && selectedPark.id == park.id {
                    continue
                } else {
                    nearbyParks.append(park)
                    
                    let marker = GMSMarker(position: park.location)
                    marker.title = park.name
                    marker.snippet = markerSnippet
                    marker.icon = markerParkLocationImage
                    marker.map = googleMapView
                    nearbyParkMarkers.append(marker)
                }
            } catch {
                continue
            }
        }
        
        objc_sync_exit(nearbyParks)
        objc_sync_exit(nearbyParkMarkers)
        objc_sync_exit(googleMapView)
    }
}

extension MapManager: GMSMapViewDelegate {
    // MARK: GMSMapViewDelegate
    
    /// Called when the map becomes idle, after any outstanding gestures or animations have completed (or after the camera has been explicitly set).
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        
        //
        // Don't load parks until camera finished moving for the conditions below
        //
        
        if mapIsAnimatingFromGettingInitialLocation {
            // Map has finished animating to current location
            // Now get the nearby parks since we can get the radius from the animated map
            mapIsAnimatingFromGettingInitialLocation = false
            onFinishedAnimatingToInitialMapLocation()
            
        } else if mapIsAnimatingFromSelectingLocation {
            mapIsAnimatingFromSelectingLocation = false
            onFinishedAnimatingAfterParkSelection()
            
        } else if mapIsAnimatingFromTappingOnMarker {
            mapIsAnimatingFromTappingOnMarker = false
            onFinishedAnimatingAfterParkSelection()
            
        } else if mapIsAnimatingToCurrentLocation {
            mapIsAnimatingToCurrentLocation = false
            onFinishedAnimatingToCurrentLocation()
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
    
    /// Called after a marker's info window has been tapped
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        if let index = nearbyParkMarkers.indexOf(marker) {
            delegate?.mapManager(self, didTapOnInfoWindowOfPark: nearbyParks[index])
        }
    }
}
