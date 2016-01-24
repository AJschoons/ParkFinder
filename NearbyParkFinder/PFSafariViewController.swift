//
//  PFSafariViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 1/24/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import SafariServices
import UIKit

/// A SFSafariViewController that has a dark status bar
class PFSafariViewController: SFSafariViewController {

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
}
