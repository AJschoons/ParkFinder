//
//  ParkDetailsViewController.swift
//  NearbyParkFinder
//
//  Created by adam on 12/29/15.
//  Copyright © 2015 Adam Schoonmaker. All rights reserved.
//

import UIKit

let ParkDetailsViewControllerIdentifier = "ParkDetailsViewController"

class ParkDetailsViewController: UIViewController {

    @IBOutlet weak var parkDetailsTable: UITableView!
    
    @IBAction func onBackButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        view.backgroundColor = primaryGreen2
    }
}

extension ParkDetailsViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
}

extension ParkDetailsViewController: UITableViewDelegate {
    
}