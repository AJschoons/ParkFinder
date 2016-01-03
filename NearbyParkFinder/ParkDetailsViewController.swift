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

struct ParkDetails {
    var place: GMSPlace
    var photoReference: String?
}

/// Shows details of a selected park
class ParkDetailsViewController: PFViewController {

    @IBOutlet weak var parkDetailsTable: UITableView!
    
    var parkDetails: ParkDetails! {
        didSet {
            decideInformationTypesToShowForParkDetials(parkDetails)
        }
    }
    
    var currentLocation: CLLocation!
    
    private var parkImage: UIImage?
    
    /// The types of information to be shown for the place
    private var informationTypesToShow = [ParkInformationTableViewCellType]()
    
    private let estimatedRowHeight: CGFloat = 48
    private let photoMargin: CGFloat = 15
    
    @IBAction func onBackButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = primaryGreen2
        parkDetailsTable.separatorColor = primaryGreen1
        
        // Use autolayout to decide row height
        parkDetailsTable.rowHeight = UITableViewAutomaticDimension
        parkDetailsTable.estimatedRowHeight = estimatedRowHeight
        
        getParkPhoto()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Makes sure the row heights are correctly calculated
        parkDetailsTable.reloadData()
    }
    
    // MARK: Networking
    
    /// Load the image for the park
    private func getParkPhoto() {
        guard let photoReference = parkDetails.photoReference else { return }
        
        let photoWidth = Int((parkDetailsTable.frame.width - photoMargin * 2) * UIScreen.mainScreen().scale)
        GooglePlacesPhotoClient.sharedClient.getPhotoForPlaceWithPhotoReference(photoReference, maxWidth: photoWidth,
            success: { [weak self] task, responseObject in
                guard let strongSelf = self else { return }
                guard let parkImage = responseObject as? UIImage else { return }
                strongSelf.parkImage = parkImage
                strongSelf.parkDetailsTable.reloadData()
            },
            failure: defaultAFHTTPFailureBlock
        )
    }
    
    // MARK: Helper
    
    /// Setup the ParkInformationLabelTableViewCell based on its type
    private func setupParkInformationLabelTableViewCell(cell: ParkInformationLabelTableViewCell) {
        guard let type = cell.type, place = parkDetails?.place else { return }
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
            
        default:
            break
        }
    }
    
    /// Decide which cells should be shown based on what place information is available
    private func decideInformationTypesToShowForParkDetials(parkDetails: ParkDetails!) {
        informationTypesToShow = []
        guard let parkDetails = parkDetails else { return }
        let place = parkDetails.place
        
        if place.name?.characters.count > 0 { informationTypesToShow.append(.Name) }
        if place.openNowStatus != .Unknown { informationTypesToShow.append(.Open) }
        if place.formattedAddress?.characters.count > 0 { informationTypesToShow.append(.Address) }
        if place.phoneNumber?.characters.count > 0 { informationTypesToShow.append(.Phone) }
        if place.website?.absoluteString.characters.count > 0 { informationTypesToShow.append(.Website) }
        if parkDetails.photoReference != nil { informationTypesToShow.append(.Photo) }
        if place.attributions?.length > 0 { informationTypesToShow.append(.Attributions) }
    }
    
    private func onAddressSelected() {
        guard let address = parkDetails?.place.formattedAddress, location = currentLocation else { return }
        
        let directions = GoogleDirectionsDefinition()
        directions.startingPoint = GoogleDirectionsWaypoint(location: location.coordinate)
        directions.destinationPoint = GoogleDirectionsWaypoint(query: address)
        OpenInGoogleMapsController.sharedInstance().openDirections(directions)
    }
    
    private func onPhoneSelected() {
        guard let phoneNumber = parkDetails?.place.phoneNumber else { return }
        
        let phoneNumberReducedToOnlyNumbers = phoneNumber.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
        
        if let phoneURL = NSURL(string: "telprompt://\(phoneNumberReducedToOnlyNumbers)") {
            UIApplication.sharedApplication().openURL(phoneURL)
        }
    }
    
    private func onWebsiteSelected() {
        guard let website = parkDetails?.place.website else { return }
        UIApplication.sharedApplication().openURL(website)
    }
    
    private func frameForImage(image: UIImage, inAspectFitImageViewWithSize imageViewSize: CGSize) -> CGRect {
        let imageRatio = image.size.width / image.size.height
        let viewRatio = imageViewSize.width / imageViewSize.height
        
        if imageRatio < viewRatio {
            let scale = imageViewSize.height / image.size.height
            let width = scale * image.size.width
            let topLeftX = (imageViewSize.width - width) / 2
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        } else {
            let scale = imageViewSize.width / image.size.width
            let height = scale * image.size.height
            let topLeftY = (imageViewSize.height - height) / 2
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

extension ParkDetailsViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return informationTypesToShow.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let parkInfoCellType = informationTypesToShow[indexPath.row]
        
        if parkInfoCellType == .Photo {
            let cell = tableView.dequeueReusableCellWithIdentifier(kParkInformationPhotoCellIdentifier)
            guard let parkInfoPhotoCell = cell as? ParkInformationPhotoTableViewCell else { return UITableViewCell() }
            parkInfoPhotoCell.type = parkInfoCellType
            parkInfoPhotoCell.parkImageView.image = parkImage
            return parkInfoPhotoCell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(kParkInformationLabelCellIdentifier)
            guard let parkInfoLabelCell = cell as? ParkInformationLabelTableViewCell else { return UITableViewCell() }
            parkInfoLabelCell.type = parkInfoCellType
            setupParkInformationLabelTableViewCell(parkInfoLabelCell)
            return parkInfoLabelCell
        }
    }
}

extension ParkDetailsViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if informationTypesToShow[indexPath.row] == .Photo {
            guard let image = parkImage else { return 0 }
            let imageViewWidth = tableView.frame.width - photoMargin * 2
            return frameForImage(image, inAspectFitImageViewWithSize: CGSizeMake(imageViewWidth, imageViewWidth)).height + photoMargin * 2
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
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

extension ParkDetailsViewController {
    // MARK: NetworkReachabilityVerificationViewControllerDelegate
    
    override func networkReachabilityVerificationViewControllerDidVerifyReachability() {
        super.networkReachabilityVerificationViewControllerDidVerifyReachability()
        
        // Now that network reachability has been reestablished, ensure the park image has been loaded
        if parkImage == nil {
            getParkPhoto()
        } else {
            parkDetailsTable.reloadData()
        }
    }
}