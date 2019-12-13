//
//  TodayDueItem.swift
//  DueList
//
//  Created by Sammy Yousif on 12/13/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import Foundation
import Disk
import CloudKit
import DeepDiff

struct TodayDueItem: Equatable, Hashable, DiffAware, Codable {
    
    static let recordType: String = "CD_DueItem"
    
    let id: String
    var completed: Bool
    var dueDate: Date?
    var input: String?
    var title: String?
    var createdAt: Date?
    
    init?(record: CKRecord) {
        guard record.recordType == TodayDueItem.recordType else { return nil }
        
        self.id = record.recordID.recordName
        
        self.completed = (record.value(forKey: "CD_completed") as! NSNumber) == 1
        self.dueDate = record.value(forKey: "CD_dueDate") as? Date
        self.input = record.value(forKey: "CD_input") as? String
        self.title = record.value(forKey: "CD_title") as? String
        self.createdAt = record.value(forKey: "CD_dueDate") as? Date
    }
    
    init(from dueItem: DueItem) {
        self.id = dueItem.objectID.uriRepresentation().absoluteString
        self.completed = dueItem.completed
        self.dueDate = dueItem.dueDate
        self.createdAt = dueItem.createdAt
        self.input = dueItem.input
        self.title = dueItem.title
    }
    
    static func saveList(of items: [DueItem]) {
        saveList(of: items.map(TodayDueItem.init))
    }
    
    static func saveList(of items: [TodayDueItem]) {
        try? Disk.save(items, to: .sharedContainer(appGroupName: "group.me.syousif.DueList"), as: "items.json")
    }
    
    static func retrieveList() -> [TodayDueItem]? {
        if let list = try? Disk.retrieve("items.json", from: .sharedContainer(appGroupName: "group.me.syousif.DueList"), as: [TodayDueItem].self) {
            return list
        }
        else {
            return nil
        }
    }
}
