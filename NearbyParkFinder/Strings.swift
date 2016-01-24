//
//  Strings.swift
//  NearbyParkFinder
//
//  Created by adam on 12/21/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

// API
let kGooglePlacesAPIBaseURL = "https://maps.googleapis.com/maps/api/place/"

// Cell indentifiers
let kParkCellIdentifier = "parkCell"
let kParkInformationLabelCellIdentifier = "parkInformationLabelCell"
let kParkInformationPhotoCellIdentifier = "parkInformationPhotoCell"

// Events
let kParkDetailsAddressTouchEventLabel = "Park Details Address Tap"
let kParkDetailsPhoneTouchEventLabel = "Park Details Phone Tap"
let kParkDetailsWebsiteTouchEventLabel = "Park Details Website Tap"
let kParkInfoWindowTouchEventLabel = "Park Info Window Tap"
let kParkMapMyLocationTouchEventLabel = "My Location Tap"
let kParkMarkerTouchEventLabel = "Park Marker Tap"
let kParkTableParkCellTouchEventLabel = "Park List Cell Tap"
let kParkTableDoubleParkCellTouchEventLabel = "Double Park List Cell Tap"

// Fonts
let kSignikaLightFontName = "Signika-Light"
let kSignikaRegularFontName = "Signika-Regular"
let kSignikaSemiboldFontName = "Signika-Semibold"
let kSignikaBoldFontName = "Signika-Bold"

// General
let kAppName = "Nearby Park Finder"
let kMainStoryboardName = "Main"
let kGMSServiceAPIKey = "AIzaSyDTIcLAbEtz33aTZvAJrvY9VzKh6ItjE5s"

// Images
let kParkLocationMarkerImageName = "parkLocationMarker"

// Notifications
let kNetworkReachabilityChangedToNotReachableNotification = "NetworkReachabilityChangedToNotReachable"
let kNetworkReachabilityChangedToReachableNotification = "NetworkReachabilityChangedToReachable"

// Screen names
let kParksMapScreenName = "Parks Map"
let kParkDetailsScreenName = "Park Details"
let kParkWebsiteScreenName = "Park Website"
let kNetworkVerificationScreenName = "Network Verification"
let kLocationVerificationScreenName = "Location Verification"

// Storyboard segues
let kParkTableViewControllerEmbedSegueIdentifier = "parkTableViewControllerEmbed"
let kPresentParkDetailsViewControllerSegueIdentifier = "presentParkDetailsViewController"