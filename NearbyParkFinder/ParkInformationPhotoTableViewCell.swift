//
//  ParkInformationPhotoTableViewCell.swift
//  NearbyParkFinder
//
//  Created by adam on 1/2/16.
//  Copyright © 2016 Adam Schoonmaker. All rights reserved.
//

import UIKit

class ParkInformationPhotoTableViewCell: ParkInformationTableViewCell {
    
    @IBOutlet weak var parkImageView: UIImageView!
    
    override func awakeFromNib() {
        parkImageView.layer.masksToBounds = true
        parkImageView.layer.cornerRadius = 5
    }
}
