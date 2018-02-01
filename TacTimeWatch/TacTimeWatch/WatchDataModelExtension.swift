//
//  WatchDataModelExtension.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 2/1/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import Foundation
extension WatchDataModel {
    var toString: String {
        let startDate = self.startDate.map ({ISO8601DateFormatter().string(from: $0 as Date)}) ?? ""
        let endDate = self.endDate.map({ISO8601DateFormatter().string(from: $0 as Date)}) ?? ""
        return "\"\(startDate)\",\"\(endDate)\",\"\(self.note ?? "")\",\"\(self.text ?? "")\"\n"
    }
    static let stringFormat = "start date, end date, note, original text"
}
