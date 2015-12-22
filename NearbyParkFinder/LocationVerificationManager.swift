//
//  LocationVerificationManager.swift
//  NearbyParkFinder
//
//  Created by adam on 12/21/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationVerificationManagerDelegate: class {
    func locationVerificationManager(manager: LocationVerificationManager, didSetState state: LocationVerificationManagerState)
}

enum LocationVerificationManagerState {
    case SearchingForLocation
    case SearchingForLocationExtended
    case LocationErrorIdle
    case FoundLocation
}

/// Handles resolving location issues and finding current location
class LocationVerificationManager: NSObject {
    
    weak var delegate: LocationVerificationManagerDelegate?
    
    private(set) var state: LocationVerificationManagerState = .SearchingForLocation
    private var stateTime: Double = 0.0
    private let StateServicePeriod = 0.1 // Period in seconds of how often to update state
    
    private(set) var locationErrorDescription: String?
    private(set) var currentLocation: CLLocation?
    
    private var timeInSearchingForLocationState = 0.0
    private let TransitionFromSearchingForLocationToExtendedPeriod = 0.2
    
    private var timeInLocationErrorIdleState = 0.0
    private let LocationErrorIdleStateCheckLocationAgainPeriod = 5.0
    
    override init() {
        super.init()
    
        setState(.SearchingForLocation)
        
        NSTimer.scheduledTimerWithTimeInterval(StateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
    }
    
    private func setState(newState: LocationVerificationManagerState) {
        state = newState
        stateTime = 0.0
        
        // Entrance actions upon state entry
        switch newState {
            
        case .SearchingForLocation:
            timeInSearchingForLocationState = 0.0
            currentLocation = nil
            locationErrorDescription = nil
            searchForLocation()
            break
            
        case .SearchingForLocationExtended:
            break
            
        case .LocationErrorIdle:
            timeInLocationErrorIdleState = 0.0
            currentLocation = nil
            break
            
        case .FoundLocation:
            locationErrorDescription = nil
            break
        }
        
        delegate?.locationVerificationManager(self, didSetState: state)
    }
    
    func serviceState() {
        stateTime += StateServicePeriod
        
        switch state {
            
        case .SearchingForLocation:
            timeInSearchingForLocationState += StateServicePeriod
            
            if timeInSearchingForLocationState > TransitionFromSearchingForLocationToExtendedPeriod {
                timeInSearchingForLocationState = 0.0
                setState(.SearchingForLocationExtended)
            }
            break
            
        case .SearchingForLocationExtended:
            break
            
        case .LocationErrorIdle:
            timeInLocationErrorIdleState += StateServicePeriod
            
            if timeInLocationErrorIdleState > LocationErrorIdleStateCheckLocationAgainPeriod {
                timeInLocationErrorIdleState = 0.0
                setState(.SearchingForLocation)
            }
            
        case .FoundLocation:
            break
        }
    }
    
    private func isSearchingForLocation() -> Bool {
        return state == .SearchingForLocation || state == .SearchingForLocationExtended
    }
    
    /// Location has an error event
    private func onLocationError() {
        setState(.LocationErrorIdle)
    }
    
    /// Location has been found event
    private func onFoundLocation() {
        setState(.FoundLocation)
    }
    
    /// View did appear event; status of location could have changed if returning to app
    func onViewDidAppear() {
        if !isSearchingForLocation() { setState(.SearchingForLocation) }
    }
    
    private func searchForLocation() {
        LocationManager.sharedManager.getLocation(
            success: { [weak self] location, accuracy in
                guard let strongSelf = self else { return }
                strongSelf.currentLocation = location
                strongSelf.onFoundLocation()
            },
            failure: { [weak self] errorDescription in
                guard let strongSelf = self else { return }
                strongSelf.locationErrorDescription = errorDescription
                strongSelf.onLocationError()
            }
        )
    }
}