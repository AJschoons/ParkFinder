//
//  NetworkReachabilityVerificationViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 1/3/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import UIKit

protocol NetworkReachabilityVerificationViewControllerDelegate: class {
    func networkReachabilityVerificationViewControllerDidVerifyReachability()
}

let NetworkReachabilityVerificationViewControllerIdentifier = "NetworkReachabilityVerificationViewController"

class NetworkReachabilityVerificationViewController: UIViewController {
    
    weak var delegate: NetworkReachabilityVerificationViewControllerDelegate?
    
    private var networkReachabilityChangedToReachable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNetworkReachabilityChangedToReachable", name: kNetworkReachabilityChangedToReachableNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        guard networkReachabilityChangedToReachable else { return }
        
        delegate?.networkReachabilityVerificationViewControllerDidVerifyReachability()
    }
    
    /// Dismiss the view controller and notify the delegate once the view disappears
    func onNetworkReachabilityChangedToReachable() {
        networkReachabilityChangedToReachable = true
        dismissViewControllerAnimated(true, completion: nil)
    }
}
