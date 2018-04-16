//
//  MyRoutesTableViewController.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/16/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit

// This is a pretty simple TableViewController that displays the saved routes.
// Much more can be done with it but for now the user can simply select the route,
// which then fills in the data on the home view controller so the route can be viewed
class MyRoutesTableViewController: UITableViewController {

    var userRoutes: [String:Any]?
    var address: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // Dismiss
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Number of rows depends on routes saved
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let ur = userRoutes {
            return ur.count
        } else {
            return 0
        }
    }

    // Populate cells with route info. Struggled to get this to work. Need to learn more about working with
    // data from Firebase
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeCell", for: indexPath) as! RouteCell
        if let ur = userRoutes {
            let val = Array(ur.values)[indexPath.row] as! NSDictionary
            cell.titleLabel.text = val["name"] as? String
            let address = val["address"] as! [String]
            cell.originAddress.text = address[0]
            cell.destinationAddress.text = address[1]
            
        }

        return cell
    }

    // If row selected, dismisses view and populates text fields in home view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = tableView.cellForRow(at: indexPath) as! RouteCell
        address = [selected.originAddress.text!, selected.destinationAddress.text!]
        
        // Get instance of HomeViewController for some setup before it displays again
        let home = self.presentingViewController as! HomeViewController
        // Addres from selected cells back to textfields
        if let a = self.address {
            home.originTextField.text = a[0]
            home.destinationTextField.text = a[1]
            home.dismiss(animated: true, completion: nil)
            home.searchForDirections() // Automatically search for directions
        }
    }

}
