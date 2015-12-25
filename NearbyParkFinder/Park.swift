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
    private(set) var name: String!
    private(set) var location: CLLocationCoordinate2D!
    private(set) var vicinity: String! // incomplete address from Google Places API
    var distance: Double! // distance from current location in miles
    
    class func initWithJSON(json: JSON, currentLocation: CLLocation) throws -> Park {
        guard let name = json["name"].string, lat = json["geometry"]["location"]["lat"].double, lng = json["geometry"]["location"]["lng"].double, vicinity = json["vicinity"].string else {
            throw ParkError.InsufficientJSONInformationForInitialization
        }
        
        let park = Park()
        park.name = name
        park.vicinity = vicinity
        
        let location = CLLocation(latitude: lat, longitude: lng)
        park.location = location.coordinate
        park.distance = (location.distanceFromLocation(currentLocation) * 0.00062137) // convert meters to miles
        
        //
        //        JSON is formatted like this
        //
        //        {
        //            "reference":"CmRgAAAABqCIQxjkI30uP-cF_rROZhCctTpP5XwB2HglrCHw1o96pU4V0oU2QqK4PfZgjDWuY9NNRivvXqBoGPkjwufss5HYitDDfex2_4oMKe7RiZrHrEdTo8aufjgPKc6TFyGlEhDAeMipHkhL6m-05LGK6oXRGhSMhGNR-uoojYg8FCKRgMZ-ZIfvKQ",
        //            "vicinity":"4540 Okemos Road, Okemos",
        //            "id":"d3f80c97a2e7fc31caaafe7ac46e491c8cd643ee",
        //            "geometry":{
        //                "location":{
        //                    "lat":42.7134705,
        //                    "lng":-84.4302331
        //                }
        //            },
        //            "scope":"GOOGLE",
        //            "types":[
        //            "park",
        //            "point_of_interest",
        //            "establishment"
        //            ],
        //            "place_id":"ChIJ76urJ0ndIogREWGxDS2nySg",
        //            "icon":"https:\/\/maps.gstatic.com\/mapfiles\/place_api\/icons\/generic_recreational-71.png",
        //            "name":"Ferguson Park"
        //        }
        
        return park
    }
}