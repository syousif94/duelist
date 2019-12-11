//
//  DueItem+CoreDataProperties.swift
//  DueList
//
//  Created by Sammy Yousif on 12/8/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//
//

import Foundation
import CoreData


extension DueItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DueItem> {
        return NSFetchRequest<DueItem>(entityName: "DueItem")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var dueDate: Date?
    @NSManaged public var input: String?
    @NSManaged public var title: String?

}
