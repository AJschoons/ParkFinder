//
//  GooglePlacesPhotoClient.swift
//  NearbyParkFinder
//
//  Created by adam on 1/2/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import AFNetworking
import CoreLocation
import Foundation

class GooglePlacesPhotoClient {
    
    lazy var urlSessionManager: AFURLSessionManager = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return AFURLSessionManager(sessionConfiguration: config)
    }()
    
    lazy var httpSessionManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: kGooglePlacesAPIBaseURL))
        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFImageResponseSerializer()
        return manager
    }()
    
    class var sharedClient: GooglePlacesPhotoClient {
        struct Static {
            static let client = GooglePlacesPhotoClient()
        }
        return Static.client
    }
    
    func getPhotoForPlaceWithPhotoReference(photoReference: String, maxWidth: Int, extraAttempts: Int = defaultExtraNetworkingAttempts, success: AFHTTPSuccessBlock, failure: AFHTTPFailureBlock) {
        
        let urlString = "\(kGooglePlacesAPIBaseURL)photo?"
        
        var params = Dictionary<String, AnyObject>()
        params.updateValue(kGMSServiceAPIKey, forKey: "key")
        params.updateValue(photoReference, forKey: "photoreference")
        params.updateValue(maxWidth, forKey: "maxwidth")
        
        let failureWithExtraAttempt: AFHTTPFailureBlock = { task, error in
            if errorShouldBeHandledWithRepeatedRequest(error, attemptsLeft: extraAttempts) {
                self.getPhotoForPlaceWithPhotoReference(photoReference, maxWidth: maxWidth, extraAttempts: (extraAttempts - 1), success: success, failure: failure)
            } else {
                failure!(task: task, error: error)
            }
        }
        
        httpSessionManager.GET(urlString, parameters: params, progress: nil, success: success, failure: failureWithExtraAttempt)
    }
    
}