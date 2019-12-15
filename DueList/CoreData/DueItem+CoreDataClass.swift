//
//  DueItem+CoreDataClass.swift
//  DueList
//
//  Created by Sammy Yousif on 12/8/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//
//

import Foundation
import CoreData
import DeepDiff
import RxSwift

@objc(DueItem)
public class DueItem: NSManagedObject, DiffAware {

    lazy var observable = {
        return Observable.combineLatest(
            self.rx.observe(Bool.self, "completed").asObservable(),
            self.rx.observe(String.self, "title").asObservable(),
            self.rx.observe(Date.self, "dueDate").asObservable()
        )
    }()
    
}
