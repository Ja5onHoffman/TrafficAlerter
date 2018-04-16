//
//  RoundedButton.swift
//  TrafficAlerter
//
//  Created by Jason Hoffman on 3/17/18.
//  Copyright © 2018 Jason Hoffman. All rights reserved.
//

import UIKit

// Trying to add some style but only used on Sign In and My Routes buttons
class RoundedButton: UIButton {
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 5.0
        self.layer.shadowRadius = 10.0
        self.layer.shadowColor = UIColor.white.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize.zero
    }
}
