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

/// Manages getting location for user
class LocationManager: NSObject {
    
    class var sharedManager: LocationManager {
        struct Static {
            static let locationManager = LocationManager()
        }
        return Static.locationManager
    }
    
    /// Gets the location within at least 300-3000ft on success
    func getLocation(success success: LocationSuccessBlock, failure: LocationFailureBlock) {
        let locMgr = INTULocationManager.sharedInstance()
        
        locMgr.requestLocationWithDesiredAccuracy(INTULocationAccuracy.House, timeout: 15.0, delayUntilAuthorized: true, block: {[unowned self] currentLocation, accuracy, status in
            
            dispatch_async(dispatch_get_main_queue(), {
                // Got location within Neighborhood distance of ~1000 meters
                if status == .Success || (currentLocation != nil && accuracy == .Block || accuracy == .Neighborhood) {
                    success(location: currentLocation, accuracy: accuracy)
                } else if status == .TimedOut {
                    failure(errorDesciption: "Could not determine location within 3000ft. Please try again in better conditions")
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
