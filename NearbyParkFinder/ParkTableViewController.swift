//
//  ParkTableViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/24/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

protocol ParkTableViewControllerParkDataSource: class {
    func getParks() -> [Park]
}

protocol ParkTableViewControllerDelegate: class {
    func parkTableViewController(parkTableViewController: ParkTableViewController, didSelectParkWithRow row: Int)
}

class ParkTableViewController: UITableViewController {
    
    weak var parkDataSource: ParkTableViewControllerParkDataSource?
    weak var delegate: ParkTableViewControllerDelegate?
}

extension ParkTableViewController {
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let parkDataSource = parkDataSource else { return 0 }
        return parkDataSource.getParks().count
    }
}

extension ParkTableViewController {
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kParkCellIdentifier)
        guard let parkDataSource = parkDataSource, parkCell = cell else { return UITableViewCell() }
        let park = parkDataSource.getParks()[indexPath.row]
        parkCell.textLabel?.text = park.name
        let distanceRoundedToTenthsPlace = Double(round(park.distance * 10) / 10)
        parkCell.detailTextLabel?.text = "\(distanceRoundedToTenthsPlace) mi"
        return parkCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let delegate = delegate else { return }
        delegate.parkTableViewController(self, didSelectParkWithRow: indexPath.row)
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}