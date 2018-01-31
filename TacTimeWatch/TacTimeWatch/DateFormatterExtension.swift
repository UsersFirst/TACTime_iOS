//
//  DateFormatterExtension.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/31/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    static func toDate(dateString: String, format: String = "E, dd MMM, YYYY") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.date(from: dateString)
    }
    
    static func toString(date: Date, format: String = "E, dd MMM, YYYY") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: date)
    }
}

