//
//  NavigationController.swift
//  DueList
//
//  Created by Sammy Yousif on 12/11/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    static let shared = NavigationController()
    
    let rootViewController = RootViewController()
    
    init() {
        super.init(rootViewController: rootViewController)
        view.backgroundColor = UIColor.white
        setNavigationBarHidden(true, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
