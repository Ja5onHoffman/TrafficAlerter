//
//  RouteCell.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/18/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit

// A subclass of the table view cell was required for the
// custom cell to work properly. Only contains outlets to
// UI elements
class RouteCell: UITableViewCell {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var originAddress: UILabel!
    @IBOutlet weak var destinationAddress: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
