//
//  DateExtension.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/27/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
}
