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
        self.createdAt = record.value(forKey: "CD_createdAt") as? Date
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
    
    static func refreshList(_ handler: @escaping ([TodayDueItem]?) -> Void) {
        let query = CKQuery(recordType: "CD_DueItem", predicate: NSPredicate(format: "CD_completed = %d", false))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            CKContainer(identifier: "iCloud.DueList").privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    print("error fetching items in extension", error)
                    
                    handler(nil)
                }
                else if let records = records {
                    let items = records.compactMap(TodayDueItem.init).sorted(by: { itemOne, itemTwo in
                        if itemOne.dueDate == nil,
                            itemTwo.dueDate == nil,
                            let createdOne = itemOne.createdAt,
                            let createdTwo = itemTwo.createdAt {
                            return createdOne > createdTwo
                        }
                        else if let dueOne = itemOne.dueDate,
                            let dueTwo = itemTwo.dueDate {
                            return dueOne > dueTwo
                        }
                        else if itemOne.dueDate != nil, itemTwo.dueDate == nil {
                            return false
                        }
                        else if itemOne.dueDate == nil, itemTwo.dueDate != nil {
                            return true
                        }
                        return true
                    })
                    
                    handler(items)
                }
            }
        }
        
    }
}
