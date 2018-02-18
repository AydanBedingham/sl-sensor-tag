//
//  SensorTagTableViewCell.swift
//  SLSensorTagExample1
//
//  Created by Aydan Bedingham on 18/2/18.
//  Copyright © 2018 Aydan Bedingham. All rights reserved.
//

import UIKit

class SensorTagTableViewCell: UITableViewCell {
    
    @IBOutlet var sensorNameLabel : UILabel!
    @IBOutlet var sensorValueLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
