//
//  PFViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 1/3/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import AFNetworking
import UIKit

/// Base class Park Finder view controller; handles ensuring there is network reachability when visible
class PFViewController: UIViewController {
    
    private(set) var isShowingNetworkReachabilityVerificationViewController = false
    var requiresNetworkReachability = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNetworkReachabilityChangedToNotReachable", name: kNetworkReachabilityChangedToNotReachableNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !AFNetworkReachabilityManager.sharedManager().reachable {
            presentNetworkReachabilityVerificationViewController()
        }
    }
    
    /// Creates a NetworkReachabilityVerificationViewController from the storyboard and presents it when the view controller is visible and and it isn't already being presented
    private func presentNetworkReachabilityVerificationViewController() {
        guard viewControllerIsVisible() && isShowingNetworkReachabilityVerificationViewController == false else { return }
        
        let storyboard = UIStoryboard(name: kMainStoryboardName, bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier(NetworkReachabilityVerificationViewControllerIdentifier)
        guard let nrvvc = vc as? NetworkReachabilityVerificationViewController else { return }
        
        nrvvc.delegate = self
        nrvvc.modalTransitionStyle = .CrossDissolve
        nrvvc.modalPresentationStyle = .OverFullScreen
        
        isShowingNetworkReachabilityVerificationViewController = true
        presentViewController(nrvvc, animated: true, completion: nil)
    }
    
    func onNetworkReachabilityChangedToNotReachable() {
        presentNetworkReachabilityVerificationViewController()
    }
    
    private func viewControllerIsVisible() -> Bool {
        return isViewLoaded() && view.window != nil
    }
}

extension PFViewController: NetworkReachabilityVerificationViewControllerDelegate {
    // MARK: NetworkReachabilityVerificationViewControllerDelegate
    
    func networkReachabilityVerificationViewControllerDidVerifyReachability() {
        isShowingNetworkReachabilityVerificationViewController = false
        
        // Allow subclasses to decide what to do when verifying reachability
    }
}