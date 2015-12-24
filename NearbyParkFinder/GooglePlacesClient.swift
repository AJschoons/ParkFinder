//
//  GooglePlacesClient.swift
//  NearbyParkFinder
//
//  Created by adam on 12/23/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import AFNetworking
import CoreLocation
import Foundation

class GooglePlacesClient {
    
    lazy var urlSessionManager: AFURLSessionManager = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return AFURLSessionManager(sessionConfiguration: config)
    }()
    
    lazy var httpSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: kGooglePlacesAPIBaseURL))
        manager.requestSerializer = AFJSONRequestSerializer() as AFJSONRequestSerializer
        manager.responseSerializer = AFJSONResponseSerializer() as AFJSONResponseSerializer
        return manager
    }()
    
    class var sharedClient: GooglePlacesClient {
        struct Static {
            static let client = GooglePlacesClient()
        }
        return Static.client
    }
    
    func getPlacesNearbySearchParks(location: CLLocation, radius: Int, extraAttempts: Int = defaultExtraNetworkingAttempts, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        let urlString = "\(kGooglePlacesAPIBaseURL)nearbysearch/json?"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(kGMSServiceAPIKey, forKey: "key")
        params.updateValue("\(location.coordinate.latitude),\(location.coordinate.longitude)", forKey: "location")
        params.updateValue(radius, forKey: "radius")
        params.updateValue("park", forKey: "types")

        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(error, attemptsLeft: extraAttempts) {
                self.getPlacesNearbySearchParks(location, radius: radius, extraAttempts: (extraAttempts - 1), success: success, failure: failure)
            } else {
                failure!(task: task, error: error)
            }
        }
        
        httpSessionManager.GET(urlString, parameters: params, progress: nil, success: success, failure: failureWithExtraAttempt)
    }
    
}