//
//  LocationVerificationViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/21/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationVerificationViewControllerDelegate: class {
    func locationVerificationViewControllerDidInitializeCurrentLocationManager()
}

let LocationVerificationViewControllerIdentifier = "LocationVerificationViewController"

/// Displays when location is unknown and handles resolving the issues and getting the location; initializes the CurrentLocationManager upon success
class LocationVerificationViewController: UIViewController {

    weak var delegate: LocationVerificationViewControllerDelegate?
    
    @IBOutlet weak var checkingLocationView: UIView!
    @IBOutlet weak var errorDescriptionLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    
    private var locationVerificationManager: LocationVerificationManager!
    
    private var currentLocationManagerInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationVerificationManager = LocationVerificationManager()
        locationVerificationManager.delegate = self
        initializeUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        locationVerificationManager.onViewDidAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        guard currentLocationManagerInitialized else { return }
        
        delegate?.locationVerificationViewControllerDidInitializeCurrentLocationManager()
    }
    
    private func updateUIForState(state: LocationVerificationManagerState) {
        
        switch state {
            
        case .SearchingForLocation:
            break
            
        case .SearchingForLocationExtended:
            hideErrorLabel()
            setCheckingLocationViewHidden(false)
            break
            
        case .LocationErrorIdle:
            showErrorLabelWithErrorDescription()
            setCheckingLocationViewHidden(true)
            break
            
        case .FoundLocation:
            // onFoundLocation() should be called and handle what to do
            break
        }
        
    }
    
    private func initializeUI() {
        hideErrorLabel()
        setCheckingLocationViewHidden(true)
    }
    
    private func hideErrorLabel() {
        errorDescriptionLabel.hidden = true
        errorDescriptionLabel.text = ""
    }
    
    private func showErrorLabelWithErrorDescription() {
        errorDescriptionLabel.hidden = false
        errorDescriptionLabel.text = locationVerificationManager.locationErrorDescription
    }
    
    private func setCheckingLocationViewHidden(hidden: Bool) {
        checkingLocationView.hidden = hidden
    }
    
    /// Dismiss the view controller and notify the delegate once the view disappears
    private func onFoundLocation() {
        CurrentLocationManager.sharedManager.onInitializeWithLocation(locationVerificationManager.currentLocation!)
        currentLocationManagerInitialized = true
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LocationVerificationViewController: LocationVerificationManagerDelegate {
    
    func locationVerificationManager(manager: LocationVerificationManager, didSetState state: LocationVerificationManagerState) {
        updateUIForState(state)
        
        if state == .FoundLocation {
            onFoundLocation()
        }
    }
}