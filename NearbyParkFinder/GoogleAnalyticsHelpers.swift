//
//  GoogleAnalyticsHelpers.swift
//  NearbyParkFinder
//
//  Created by adam on 1/24/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import Google
import UIKit

/// Sends/logs Google Analytics tracking data when visiting a screen
func trackViewWillAppearForScreenName(screenName: String) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: screenName)
    let eventTracker: NSObject = GAIDictionaryBuilder.createScreenView().build()
    tracker.send(eventTracker as! [NSObject : AnyObject])
}

/// Sends/logs Google Analytics tracking data for UX touch events
func trackUXTouchEventWithLabel(label: String, andScreenName screenName: String) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: screenName)
    let eventTracker: NSObject = GAIDictionaryBuilder.createEventWithCategory("UX", action: "touch", label: label, value: nil).build()
    tracker.send(eventTracker as! [NSObject : AnyObject])
    tracker.set(kGAIScreenName, value: nil)
}