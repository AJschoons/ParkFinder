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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNetworkReachabilityChangedToReachable", name: kNetworkReachabilityChangedToReachableNotification, object: nil)
    }
    
    func onNetworkReachabilityChangedToReachable() {
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.networkReachabilityVerificationViewControllerDidVerifyReachability()
    }
}
