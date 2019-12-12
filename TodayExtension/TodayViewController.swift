//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Sammy Yousif on 12/12/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import PinLayout
import RxSwift
import RxCocoa

class TodayViewController: UIViewController, NCWidgetProviding {
    
    let bag = DisposeBag()
    
    var dueItems: DueItems!
    
    let label: UILabel = {
        let label = UILabel()
        return label
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(label)
            
        self.dueItems = DueItems(viewContext: persistentContainer.viewContext)
        
        dueItems.incomplete.results.subscribe(onNext: { [unowned self] items in
            let text = "\(items.count) Incomplete"
            DispatchQueue.main.async {
                self.label.text = text
                self.view.setNeedsLayout()
            }
        }).disposed(by: bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        label.pin.sizeToFit().center()
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: PersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = PersistentContainer(name: "DueList")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
}

class PersistentContainer: NSPersistentCloudKitContainer {
    override class func defaultDirectoryURL() -> URL{
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.me.syousif.DueList")!
    }
 
    override init(name: String, managedObjectModel model: NSManagedObjectModel) {
        super.init(name: name, managedObjectModel: model)
    }
}
