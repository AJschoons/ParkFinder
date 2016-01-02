//
//  ParkDetailsViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/29/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import GoogleMaps
import OpenInGoogleMaps
import UIKit

let ParkDetailsViewControllerIdentifier = "ParkDetailsViewController"

class ParkDetailsViewController: UIViewController {

    @IBOutlet weak var parkDetailsTable: UITableView!
    
    var place: GMSPlace! {
        didSet {
            decideInformationTypesToShowForPlace(place)
        }
    }
    
    var currentLocation: CLLocation!
    
    /// The types of information to be shown for the place
    private var informationTypesToShow = [ParkInformationTableViewCellType]()
    
    private let estimatedRowHeight: CGFloat = 48
    
    @IBAction func onBackButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        view.backgroundColor = primaryGreen2
        parkDetailsTable.separatorColor = primaryGreen1
        
        // Use autolayout to decide row height
        parkDetailsTable.rowHeight = UITableViewAutomaticDimension
        parkDetailsTable.estimatedRowHeight = estimatedRowHeight
    }
    
    // MARK: Helper
    
    /// Setup the ParkInformationTableViewCell based on its type
    private func setupParkInformationTableViewCell(cell: ParkInformationTableViewCell) {
        guard let type = cell.type, place = place else { return }
        let underlineAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        
        switch type {
            
        case .Name:
            cell.informationTypeLabel.text = "Name:"
            cell.informationDetailsLabel.text = place.name
            
        case .Open:
            cell.informationTypeLabel.text = "Open:"
            
            if place.openNowStatus == .Yes {
                cell.informationDetailsLabel.text = "Yes"
            } else if place.openNowStatus == .No {
                cell.informationDetailsLabel.text = "No"
            }
            
        case .Address:
            cell.informationTypeLabel.text = "Address:"
            cell.informationDetailsLabel.attributedText = NSAttributedString(string: place.formattedAddress, attributes: underlineAttributes)
            
        case .Phone:
            cell.informationTypeLabel.text = "Phone:"
            cell.informationDetailsLabel.attributedText = NSAttributedString(string: place.phoneNumber, attributes: underlineAttributes)
            
        case .Website:
            cell.informationTypeLabel.text = "Website:"
            cell.informationDetailsLabel.text = place.website?.absoluteString
            cell.informationDetailsLabel.attributedText = NSAttributedString(string: place.website.absoluteString, attributes: underlineAttributes)
            
        case .Attributions:
            cell.informationTypeLabel.text = ""
            cell.informationDetailsLabel.attributedText = place.attributions
        }
    }
    
    /// Decide which cells should be shown based on what place information is available
    private func decideInformationTypesToShowForPlace(place: GMSPlace!) {
        informationTypesToShow = []
        guard let place = place else { return }
        
        if place.name?.characters.count > 0 { informationTypesToShow.append(.Name) }
        if place.openNowStatus != .Unknown { informationTypesToShow.append(.Open) }
        if place.formattedAddress?.characters.count > 0 { informationTypesToShow.append(.Address) }
        if place.phoneNumber?.characters.count > 0 { informationTypesToShow.append(.Phone) }
        if place.website?.absoluteString.characters.count > 0 { informationTypesToShow.append(.Website) }
        if place.attributions?.length > 0 { informationTypesToShow.append(.Attributions) }
    }
    
    private func onAddressSelected() {
        guard let address = place?.formattedAddress, location = currentLocation else { return }
        
        let directions = GoogleDirectionsDefinition()
        directions.startingPoint = GoogleDirectionsWaypoint(location: location.coordinate)
        directions.destinationPoint = GoogleDirectionsWaypoint(query: address)
        OpenInGoogleMapsController.sharedInstance().openDirections(directions)
    }
    
    private func onPhoneSelected() {
        guard let phoneNumber = place?.phoneNumber else { return }
        
        let phoneNumberReducedToOnlyNumbers = phoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
        
        if let phoneURL = NSURL(string: "telprompt://\(phoneNumberReducedToOnlyNumbers)") {
            UIApplication.sharedApplication().openURL(phoneURL)
        }
    }
    
    private func onWebsiteSelected() {
        guard let website = place?.website else { return }
        UIApplication.sharedApplication().openURL(website)
    }
}

extension ParkDetailsViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return informationTypesToShow.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kParkInformationCellIdentifier)
        guard let parkInformationCell = cell as? ParkInformationTableViewCell else { return UITableViewCell() }
        
        parkInformationCell.type = informationTypesToShow[indexPath.row]
        setupParkInformationTableViewCell(parkInformationCell)
        
        return parkInformationCell
    }
}

extension ParkDetailsViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let parkInfoCell = tableView.cellForRowAtIndexPath(indexPath) as? ParkInformationTableViewCell else { return }
        guard let parkInfoCellType = parkInfoCell.type else { return }
        
        switch parkInfoCellType {
            
        case .Address:
            onAddressSelected()
            
        case .Phone:
            onPhoneSelected()
            
        case .Website:
            onWebsiteSelected()
            
        default:
            return
        }
    }
}