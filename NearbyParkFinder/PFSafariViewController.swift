//
//  PFSafariViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 1/24/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import Google
import SafariServices
import UIKit

/// A SFSafariViewController that has a dark status bar and tracks when it appears
class PFSafariViewController: SFSafariViewController {

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        trackViewWillAppearForScreenName(kParkWebsiteScreenName)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
