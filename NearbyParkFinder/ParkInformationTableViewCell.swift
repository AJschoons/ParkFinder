//
//  ParkInformationTableViewCell.swift
//  NearbyParkFinder
//
//  Created by adam on 12/30/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

enum ParkInformationTableViewCellType {
    case Name, Open, Address, Phone, Website, Attributions
}

class ParkInformationTableViewCell: UITableViewCell {

    @IBOutlet weak var informationTypeLabel: UILabel!
    @IBOutlet weak var informationDetailsLabel: UILabel!
    
    var type: ParkInformationTableViewCellType!
}
