//
//  WatchDataTableViewCell.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import UIKit

class WatchDataTableViewCell: UITableViewCell {

    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var originalTextLabel: UILabel!
    
    var data: WatchDataModel? {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.locale = Locale(identifier: "en_US")
            self.endDateLabel.text = (data?.endDate).map({formatter.string(from: $0 as Date)})
            self.startDateLabel.text = (data?.startDate).map({formatter.string(from: $0 as Date)})
            self.noteLabel.text = data?.note
            self.originalTextLabel.text = data?.text
        }
    }
}
