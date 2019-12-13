//
//  DueItems.swift
//  DueList
//
//  Created by Sammy Yousif on 12/8/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import CoreData
import Foundation
import UIKit
import RxSwift
import RxCocoa

class DueItems {
    static let shared = DueItems()
    
    let incomplete = FetchController(
        viewContext: appDelegate.persistentContainer.viewContext,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \DueItem.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \DueItem.createdAt, ascending: false)
        ],
        predicate: NSPredicate(format: "completed = %d", false)
    )
    
    let complete = FetchController(
        viewContext: appDelegate.persistentContainer.viewContext,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \DueItem.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \DueItem.createdAt, ascending: false)
        ],
        predicate: NSPredicate(format: "completed = %d", true)
    )
    
    let list = BehaviorRelay<List>(value: .all)
    
    func delete(item: DueItem) {
        appDelegate.persistentContainer.viewContext.delete(item)
    }
    
    enum List {
        case all
        case today
        case late
        case done
        
        var stringValue: String {
            switch self {
            case .all: return "All"
            case .today: return "Today"
            case .late: return "Late"
            case .done: return "Done"
            }
        }
        
        var colorValue: UIColor {
            switch self {
            case .all: return .gray
            case .today: return .blue
            case .late: return .orange
            case .done: return .green
            }
        }
        
        var imageValue: UIImage {
            switch self {
            case .all: return #imageLiteral(resourceName: "AllIcon")
            case .today: return #imageLiteral(resourceName: "TodayIcon")
            case .late: return #imageLiteral(resourceName: "LateIcon")
            case .done: return #imageLiteral(resourceName: "DoneIcon")
            }
        }
    }
}

extension DueItems {
    class FetchController: NSObject, NSFetchedResultsControllerDelegate {
        var managedObjectContext: NSManagedObjectContext!
        
        var fetchedResultsController: NSFetchedResultsController<DueItem>!
        
        let sortDescriptors: [NSSortDescriptor]?
        
        let predicate: NSPredicate?
        
        let results = BehaviorRelay<[DueItem]>(value: [])
        
        init(viewContext: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]?, predicate: NSPredicate?) {
            self.sortDescriptors = sortDescriptors
            self.predicate = predicate
            
            super.init()
            
            viewContext.automaticallyMergesChangesFromParent = true
            
            self.managedObjectContext = viewContext
            
            configureFetchController()
            
            do {
                try fetchedResultsController.performFetch()
                updateObjects()
            } catch {
                print(error)
            }
        }
        
        func configureFetchController() {
            let fetchRequest: NSFetchRequest<DueItem> = DueItem.fetchRequest()
            
            fetchRequest.sortDescriptors = self.sortDescriptors
            fetchRequest.predicate = self.predicate
            
            self.fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            self.fetchedResultsController.delegate = self
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            updateObjects()
        }
        
        func updateObjects() {
            if let objects = self.fetchedResultsController.fetchedObjects {
                results.accept(objects)
            }
        }
    }
}
