//
//  LocationManager.swift
//  NearbyParkFinder
//
//  Created by adam on 12/21/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import Foundation
import INTULocationManager

typealias LocationSuccessBlock = (location: CLLocation, accuracy: INTULocationAccuracy) -> Void
typealias LocationFailureBlock = (errorDesciption: String) -> Void

/// Manages getting location of the device
class LocationManager: NSObject {
    
    class var sharedManager: LocationManager {
        struct Static {
            static let locationManager = LocationManager()
        }
        return Static.locationManager
    }
    
    private var numberOfInitialLocationSearchRequests = 0
    
    /// Gets the location within at least 300ft-3mi on success. Each failure adds 5 seconds to location request timeout, up to 30
    func getInitialLocation(success success: LocationSuccessBlock, failure: LocationFailureBlock) {
        let locMgr = INTULocationManager.sharedInstance()
        
        let timeout = min(10.0 + 5.0 * Double(numberOfInitialLocationSearchRequests), 30)
        ++numberOfInitialLocationSearchRequests
        
        locMgr.requestLocationWithDesiredAccuracy(INTULocationAccuracy.Block, timeout: timeout, delayUntilAuthorized: true, block: {[unowned self] currentLocation, accuracy, status in
            
            dispatch_async(dispatch_get_main_queue(), {
                // Got location within City distance of ~5000 meters
                if status == .Success || (currentLocation != nil && accuracy == .Neighborhood || accuracy == .City) {
                    success(location: currentLocation, accuracy: accuracy)
                } else if status == .TimedOut {
                    failure(errorDesciption: "Could not determine location within 3 miles. Please try again in better conditions, the app will continue attempting to get the location with longer periods of time before failure")
                } else {
                    failure(errorDesciption: self.getINTUStatusErrorMessageFromStatus(status))
                }
            })
        })
    }
    
    /// Gets the location within at least 45ft-3mi on success
    func getCurrentLocation(success success: LocationSuccessBlock, failure: LocationFailureBlock) {
        let locMgr = INTULocationManager.sharedInstance()
        
        locMgr.requestLocationWithDesiredAccuracy(INTULocationAccuracy.House, timeout: 30.0, delayUntilAuthorized: true, block: {[unowned self] currentLocation, accuracy, status in
            
            dispatch_async(dispatch_get_main_queue(), {
                // Got location within Neighborhood distance of ~3000 meters
                if status == .Success || (currentLocation != nil && accuracy == .Block || accuracy == .Neighborhood || accuracy == .City) {
                    success(location: currentLocation, accuracy: accuracy)
                } else if status == .TimedOut {
                    failure(errorDesciption: "Could not determine location within 3 miles. Please try again in better conditions")
                } else {
                    failure(errorDesciption: self.getINTUStatusErrorMessageFromStatus(status))
                }
            })
            })
    }
    
    private func getINTUStatusErrorMessageFromStatus(status: INTULocationStatus) -> String {
        switch status {
        case .ServicesNotDetermined:
            return "Must respond to the dialog to grant \(kAppName) permission to access location services"
        case .ServicesDenied:
            return "\(kAppName) has been explicitly deined permission to access location services. Please go to Settings>\(kAppName)>Location to allow this feature"
        case .ServicesRestricted:
            return "Location services are currently restricted and cannot be enabled due to parental controls, corporate policy, etc"
        case .ServicesDisabled:
            return "Location services have been disabled device-wide. Please enable them in the Settings app"
        default:
            return ""
        }
    }
    
}
