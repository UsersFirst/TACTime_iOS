//
//  WatchDataModel+CoreDataProperties.swift
//  TacTimeWatch
//
//  Created by bibek timalsina on 1/24/18.
//  Copyright © 2018 bibek timalsina. All rights reserved.
//
//

import Foundation
import CoreData


extension WatchDataModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchDataModel> {
        return NSFetchRequest<WatchDataModel>(entityName: "WatchDataModel")
    }

    @NSManaged public var text: String?
    @NSManaged public var startDate: NSDate?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var note: String?

}