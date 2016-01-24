//
//  CurrentLocationManager.swift
//  NearbyParkFinder
//
//  Created by adam on 1/2/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import Foundation
import CoreLocation

enum CurrentLocationManagerError: ErrorType {
    case LocationUninitialized
}

enum CurrentLocationManagerState {
    case LocationUninitialized /// State machine has not been initialized with a location
    case LocationUpdated /// Current location updated in past 30 seconds
    case LocationExpired /// Current location not updated in past 30 seconds
    case LocationExpiredError /// Current location not updated and received error when updating location
    case LocationUpdating /// Updating current location
}

/// Singleton that handles updating current location and supplies the location app-wide
class CurrentLocationManager: NSObject {
    
    class var sharedManager: CurrentLocationManager {
        struct Static {
            static let currentLocationManager = CurrentLocationManager()
        }
        return Static.currentLocationManager
    }
    
    private var currentLocation: CLLocation!
    
    private var state: CurrentLocationManagerState = .LocationUninitialized
    private var stateTime: Double = 0.0
    private let StateServicePeriod = 0.1 /// Period in seconds of how often to service state
    
    private var timeInLocationUpdatedState = 0.0
    private let TransitionFromUpdatedToExpiredPeriod = 30.0 /// Period in seconds of how often to update location
    
    private var timeInLocationExpiredErrorState = 0.0
    private let TransitionFromExpiredErrorToUpdatingPeriod = 10.0 /// Period in seconds of how often to update location when there was an error getting it
    
    override init() {
        super.init()
        
        setState(.LocationUninitialized)
        
        NSTimer.scheduledTimerWithTimeInterval(StateServicePeriod, target: self, selector: "serviceState", userInfo: nil, repeats: true)
    }
    
    // MARK: Getters
    
    func getCurrentLocation() throws -> CLLocation {
        if simulateLocation {
            currentLocation = CLLocation(latitude: 40.75921100, longitude: -73.98463800)
            return currentLocation
        }
        
        guard let location = currentLocation where state != .LocationUninitialized else {
            throw CurrentLocationManagerError.LocationUninitialized
        }
        
        return location
    }
    
    // MARK: State management
    
    private func setState(newState: CurrentLocationManagerState) {
        state = newState
        stateTime = 0.0
        
        // Entrance actions upon state entry
        switch newState {
            
        case .LocationUninitialized:
            break
            
        case .LocationUpdated:
            timeInLocationUpdatedState = 0.0
            
        case .LocationExpired:
            onLocationHasExpired()
            break
            
        case .LocationExpiredError:
            timeInLocationExpiredErrorState = 0.0
            
        case .LocationUpdating:
            updateLocation()
            break
        }
    }
    
    func serviceState() {
        stateTime += StateServicePeriod
        
        switch state {
            
        case .LocationUninitialized:
            break
            
        case .LocationUpdated:
            timeInLocationUpdatedState += StateServicePeriod
            
            // Update the location every time this period expires
            if timeInLocationUpdatedState > TransitionFromUpdatedToExpiredPeriod {
                timeInLocationUpdatedState = 0.0
                setState(.LocationExpired)
            }
            
        case .LocationExpired:
            break
            
        case .LocationExpiredError:
            timeInLocationExpiredErrorState += StateServicePeriod
            
            // Try updating the location every time this period expires; it's been at least 
            // over 40 seconds since updating
            if timeInLocationExpiredErrorState > TransitionFromExpiredErrorToUpdatingPeriod {
                timeInLocationUpdatedState = 0.0
                setState(.LocationUpdating)
            }
            
        case .LocationUpdating:
            break
        }
    }
    
    // MARK: Events
    
    /// Location has expired, so update it
    private func onLocationHasExpired() {
        guard state == .LocationExpired else { return }
        setState(.LocationUpdating)
    }
    
    /// Location has an error event
    private func onLocationError() {
        guard state == .LocationUpdating else { return }
        setState(.LocationExpiredError)
    }
    
    /// Location has been found event
    private func onFoundLocation() {
        guard state == .LocationUpdating else { return }
        setState(.LocationUpdated)
    }
    
    /// Initalizes the state machine with a location, then begins updating it
    func onInitializeWithLocation(location: CLLocation) {
        guard state == .LocationUninitialized else { return }
        currentLocation = location
        setState(.LocationUpdated)
    }
    
    // MARK: Helpers
    
    private func updateLocation() {
        LocationManager.sharedManager.getCurrentLocation(
            success: { [weak self] location, accuracy in
                guard let strongSelf = self else { return }
                strongSelf.currentLocation = location
                strongSelf.onFoundLocation()
            },
            failure: { [weak self] errorDescription in
                guard let strongSelf = self else { return }
                strongSelf.onLocationError()
            }
        )
    }
}