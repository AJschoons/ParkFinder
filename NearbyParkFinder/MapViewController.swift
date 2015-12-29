//
//  MapViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/22/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import GoogleMaps
import SwiftyJSON
import UIKit

class MapViewController: UIViewController {
    
    private var parkTableViewController: ParkTableViewController!
    private var mapManager: MapManager!
    
    @IBOutlet weak var mapRegionView: UIView!
    
    private var currentLocation: CLLocation?
    
    override func viewDidLayoutSubviews() {
        if mapManager.googleMapView == nil {
            mapManager.onMapRegionSuperviewViewDidLayoutSubviews()
        }
        
        mapManager.googleMapView.frame = mapRegionView.frame
    }
    
    override func viewDidLoad() {
        mapManager = MapManager(viewToPlaceMapIn: mapRegionView)
        mapManager.locationSource = self
        mapManager.delegate = self
        
        view.backgroundColor = primaryGreen2
    }
    
    override func viewDidAppear(animated: Bool) {
        if currentLocation == nil {
            // Get the location before showing this view controller
            presentLocationVerificationViewController()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == kParkTableViewControllerEmbedSegueIdentifier {
            // Embed for the ParkTableViewController
            guard let destination = segue.destinationViewController as? ParkTableViewController else { return }
            parkTableViewController = destination
            parkTableViewController.parkDataSource = self
            parkTableViewController.delegate = self
            
        }
    }
    
    /// Creates a LocationVerificationViewController from the storyboard and presents it
    private func presentLocationVerificationViewController() {
        let storyboard = UIStoryboard(name: kMainStoryboardName, bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier(LocationVerificationViewControllerIndentifier)
        guard let lvvc = vc as? LocationVerificationViewController else { return }
        
        lvvc.delegate = self
        lvvc.modalTransitionStyle = .CrossDissolve
        lvvc.modalPresentationStyle = .OverFullScreen
        
        presentViewController(lvvc, animated: true, completion: nil)
    }
    
    private func reloadParkTableViewControllerParkData() {
        parkTableViewController.tableView.reloadData()
    }
}

extension MapViewController {
    // MARK: Location
    
    private func getLocation() {
        LocationManager.sharedManager.getLocation(
            success: { [weak self] location, accuracy in
                guard let strongSelf = self else { return }
                strongSelf.currentLocation = location
                strongSelf.onGotLocationSuccess()
            },
            failure: { [weak self] errorDescription in
                guard let strongSelf = self else { return }
                strongSelf.onGotLocationFailure()
            }
        )
    }
    
    private func onGotLocationSuccess() {
        // Called when found location or returning from location verification view controller
        // TODO: handle updating location
        
        mapManager.onGotLocation()
    }
    
    private func onGotLocationFailure() {
        presentLocationVerificationViewController()
    }
}

extension MapViewController: MapManagerLocationSource {
    // MARK: MapManagerLocationSource
    
    func getCurrentLocation() -> CLLocation? {
        return currentLocation
    }
}

extension MapViewController: MapManagerDelegate {
    // MARK: MapManagerLocationSource
    
    func mapManager(mapManager: MapManager, didUpdateWithParks parks: [Park]) {
        reloadParkTableViewControllerParkData()
    }
}

extension MapViewController: LocationVerificationViewControllerDelegate {
    // MARK: LocationVerificationViewControllerDelegate
    
    func locationVerificationViewControllerDidGetLocation(location: CLLocation) {
        // Need to wait until view is visible before animating
        currentLocation = location
        onGotLocationSuccess()
    }
}

extension MapViewController: ParkTableViewControllerParkDataSource {
    // MARK: ParkTableViewControllerParkDataSource
    
    func getParks() -> [Park] {
        return mapManager.nearbyParks
    }
}

extension MapViewController: ParkTableViewControllerDelegate {
    // MARK: ParkTableViewControllerDelegate
    
    func parkTableViewController(parkTableViewController: ParkTableViewController, didSelectParkWithRow row: Int) {
        let park = mapManager.nearbyParks[row]
        mapManager.onParkSelected(park)
    }
}
