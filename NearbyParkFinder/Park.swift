//
//  Park.swift
//  NearbyParkFinder
//
//  Created by adam on 12/24/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import CoreLocation
import Foundation
import SwiftyJSON

enum ParkError: ErrorType {
    case InsufficientJSONInformationForInitialization
}

class Park {
    private(set) var id: String!
    private(set) var name: String!
    private(set) var location: CLLocationCoordinate2D!
    private(set) var vicinity: String! // incomplete address from Google Places API
    private(set) var distance: Double! // distance from current location in miles
    
    private(set) var photoReference: String?
    
    class func initWithJSON(json: JSON, currentLocation: CLLocation) throws -> Park {
        guard let id = json["place_id"].string, name = json["name"].string, lat = json["geometry"]["location"]["lat"].double, lng = json["geometry"]["location"]["lng"].double, vicinity = json["vicinity"].string else {
            throw ParkError.InsufficientJSONInformationForInitialization
        }
        
        let park = Park()
        park.id = id
        park.name = name
        park.vicinity = vicinity
        
        let location = CLLocation(latitude: lat, longitude: lng)
        park.location = location.coordinate
        park.distance = (location.distanceFromLocation(currentLocation) * 0.00062137) // convert meters to miles
        
        if let photos = json["photos"].array {
            if let photoRef = photos[0]["photo_reference"].string {
                park.photoReference = photoRef
            }
        }
    
        return park
    }
}